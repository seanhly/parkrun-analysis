ELITE_CLUBS="24804, 25125, 2351, 367, 22598, 1149, 18306, 1490, 1993, 612, 44, 19905, 48109, 25348, 24434, 22488, 3116, 29276, 615, 26944, 28921, 20791, 47125, 847, 24872, 2064, 28965, 2015, 1119, 2789, 47290, 1743, 1681, 24935, 20762, 143, 2854, 723, 2356, 245, 28211, 1734, 1825, 21611, 2062, 25629, 47770, 21276, 21502, 17871, 21977, 2226, 22745, 2250, 20857, 1807, 29058, 573, 2427, 1750, 21222, 2190, 19946, 2033, 25153, 26974, 2047, 3080, 20515, 22116, 25386, 22642, 2928, 21632, 2848, 2906, 1014, 918, 21089, 22281, 2419, 2261, 21941, 417, 22244, 23975, 2264, 18287, 17448, 21074, 3040, 24793, 667, 17243, 1856, 2017, 30071, 47224, 26144, 2262, 20962, 23733, 20937, 20891, 787, 21347, 21201, 1496, 2777, 47174, 23508, 19917, 20817, 945, 22524, 23451, 2927, 1943, 2863, 1479, 2918, 21051, 1936, 21039, 22464, 236, 26242, 1883, 25240, 1677, 2369, 1749, 1047, 23985, 242, 22092, 3017, 21813, 30043, 1532, 30231, 20005, 23297, 29993, 26322, 1775, 2867, 503, 29696, 3029, 2564, 22628, 21545, 2223, 2294, 23762, 23175, 21579, 1954, 1787, 1579, 28730, 21302, 20761, 22354, 722, 20001, 2063, 22142, 24532, 23164, 1622, 1928, 46779, 1206, 2156, 23301, 22461, 18146, 17757, 20113, 2228, 25195, 2441, 1242, 22412, 1092, 1670, 1951, 22090, 114, 24940, 21169, 49337, 18231, 22927, 21705, 947, 25338, 1598"
mkdir -p results
rm groups.tsv runners.tsv times.tsv performances.tsv
if [ ! -e parkrun.tsv ]; then
	(
		echo -e $'event\tweek\trunner\trunner_name\tsex\tcategory\tgroup\tgroup_name\ttime' && zcat parkrun.tsv.gz
	) > parkrun.tsv
fi
if [ ! -e times.tsv ]; then
	pv parkrun.tsv |
		awk '{print $NF}' |
		awk -F: '
		NF == 1 {
			print "time\ttime_label"
			next
		}
		NF == 2 {
			printf "%d", $1 * 60 + $2
		}
		NF == 3 {
			printf "%d", $1 * 3600 + $2 * 60 + $3
		}
		{printf "\t%s\n", $0}
		' |
		sort -nu > times.tsv
fi
if [ ! -e groups.tsv ]; then
	(
		echo -e $'group\tgroup_name' && (
			pv parkrun.tsv |
				cut -d$'\t' -f7,8 |
				sort -nu |
				grep -E $'^[0-9]+\t'
		)
	) > groups.tsv
fi
if [ ! -e runners.tsv ]; then
	(cat | duckdb) <<END
	copy (
		with x as (
			select country, sex, case when dense_rank()over(partition by e.country order by avg(t.time))=1 then 'Male' else 'Female' end sex2
			from 'parkrun.tsv' p
			join 'events.tsv' e on e.event_label = p.event
			join 'times.tsv' t on t.time_label = p.time
			where sex not in ('&nbsp;') group by e.country, sex
		),
		sexes as (select sex, sex2 from x group by sex, sex2)
		select runner, p.runner_name, max(sex2) as sex
		from 'parkrun.tsv' p
		left join sexes using (sex)
		group by runner, p.runner_name
		order by runner
	) to 'runners.tsv' (delimiter '\t', header true)
	;
END
fi
if [ ! -e performances.tsv ]; then
	(cat | duckdb) <<END
	copy (
		select
			e."event",
			p.week,
			runner,
			regexp_replace(
				"category", '[^0-9]*([0-9]*)[^0-9]*.*', '\1'
			) as "age",
			regexp_replace("group", ',.*', '') as "group",
			t."time"
		from 'parkrun.tsv' p
		join 'events.tsv' e on e.event_label = p.event
		join 'times.tsv' t on t.time_label = p."time"
		order by e.event, p.week, t.time
	) to 'performances.tsv' (delimiter '\t', header true)
	;
END
fi

if [ ! -e results/general_pb_distribution.csv ]; then
	(cat | duckdb) <<END
	copy (
		with pb as (
			select runner, age, min("time") as "time"
			from 'performances.tsv' natural join 'events.tsv' group by runner, age
		),
		windows as (
			select floor("time" / (60 / 4)) / 4 "window" from pb
			where "time" < 60 * 75
		),
		"minutes" as (
			select "window" "minutes", count(1) c
			from windows group by "window"
		)
		select "minutes", c / (select count(1) from windows) p from "minutes"
	) to 'results/general_pb_distribution.csv';
END
fi

if [ ! -e results/general_distribution.csv ]; then
	(cat | duckdb) <<END
	copy (
		with windows as (
			select floor("time" / (60 / 4)) / 4 "window" from 'performances.tsv'
			where "time" < 60 * 75
		),
		"minutes" as (
			select "window" "minutes", count(1) c
			from windows group by "window"
		)
		select "minutes", c / (select count(1) from windows) p from "minutes"
	) to 'results/general_distribution.csv';
END
fi

if [ ! -e results/sex_distribution.csv ]; then
	(cat | duckdb) <<END
	copy (
		with windows as (
			select sex, floor("time" / (60 / 4)) / 4 "window" from 'performances.tsv'
			natural join 'runners.tsv'
			where "time" < 60 * 75
		),
		"minutes" as (
			select sex, "window" "minutes", count(1) c
			from windows
			group by sex, "window"
		),
		totals as (
			select sex, count(1) as total from windows group by sex
		)
		select sex, "minutes", c / total p from "minutes"
		natural join totals
	) to 'results/sex_distribution.csv';
END
fi

if [ ! -e results/sex_pb_distribution.csv ]; then
	(cat | duckdb) <<END
	copy (
		with pb as (
			select runner, age, min("time") as "time"
			from 'performances.tsv' natural join 'events.tsv' group by runner, age
		),
		windows as (
			select sex, floor("time" / (60 / 4)) / 4 "window" from pb
			natural join 'runners.tsv'
			where "time" < 60 * 75
		),
		"minutes" as (
			select sex, "window" "minutes", count(1) c
			from windows
			group by sex, "window"
		),
		totals as (
			select sex, count(1) as total from windows group by sex
		)
		select sex, "minutes", c / total p from "minutes"
		natural join totals
	) to 'results/sex_pb_distribution.csv';
END
fi

if [ ! -e results/young_distribution.csv ]; then
	(cat | duckdb) <<END
	copy (
		with windows as (
			select sex, floor("time" / (60 / 4)) / 4 "window" from 'performances.tsv'
			natural join 'runners.tsv'
			where "time" < 60 * 75
			and age <= 35
		),
		"minutes" as (
			select sex, "window" "minutes", count(1) c
			from windows
			group by sex, "window"
		),
		totals as (
			select sex, count(1) as total from windows group by sex
		)
		select sex, "minutes", c / total p from "minutes"
		natural join totals
	) to 'results/young_distribution.csv';
END
fi

if [ ! -e results/young_pb_distribution.csv ]; then
	(cat | duckdb) <<END
	copy (
		with pb as (
			select runner, age, min("time") as "time"
			from 'performances.tsv' natural join 'events.tsv' group by runner, age
		),
		windows as (
			select sex, floor("time" / (60 / 4)) / 4 "window" from pb
			natural join 'runners.tsv'
			where "time" < 60 * 75
			and age <= 35
		),
		"minutes" as (
			select sex, "window" "minutes", count(1) c
			from windows
			group by sex, "window"
		),
		totals as (
			select sex, count(1) as total from windows group by sex
		)
		select sex, "minutes", c / total p from "minutes"
		natural join totals
	) to 'results/young_pb_distribution.csv';
END
fi

if [ ! -e results/club_distributions.csv ]; then
	(cat | duckdb) <<END
	copy (
		with windows as (
			select sex, "group" is not null in_club,
			floor("time" / (60 / 4)) / 4 "window" from 'performances.tsv'
			natural join 'runners.tsv'
			where "time" < 60 * 75
		),
		"minutes" as (
			select sex, in_club, "window" "minutes", count(1) c
			from windows
			group by sex, in_club, "window"
		),
		totals as (
			select sex, in_club, count(1) as total
			from windows group by sex, in_club
		)
		select sex, in_club, "minutes", c / total p from "minutes"
		natural join totals
	) to 'results/club_distributions.csv';
END
fi

if [ ! -e results/club_pb_distributions.csv ]; then
	(cat | duckdb) <<END
	copy (
		with pb as (
			select runner, age, "group", min("time") as "time"
			from 'performances.tsv' natural join 'events.tsv'
			group by runner, age, "group"
		),
		windows as (
			select sex, "group" is not null in_club,
			floor("time" / (60 / 4)) / 4 "window" from pb
			natural join 'runners.tsv'
			where "time" < 60 * 75
		),
		"minutes" as (
			select sex, in_club, "window" "minutes", count(1) c
			from windows
			group by sex, in_club, "window"
		),
		totals as (
			select sex, in_club, count(1) as total
			from windows group by sex, in_club
		)
		select sex, in_club, "minutes", c / total p from "minutes"
		natural join totals
	) to 'results/club_pb_distributions.csv';
END
fi

if [ ! -e results/club_young_distributions.csv ]; then
	(cat | duckdb) <<END
	copy (
		with windows as (
			select sex, "group" is not null in_club,
			floor("time" / (60 / 4)) / 4 "window" from 'performances.tsv'
			natural join 'runners.tsv'
			where "time" < 60 * 75
			and age <= 35 and age >= 18
		),
		"minutes" as (
			select sex, in_club, "window" "minutes", count(1) c
			from windows
			group by sex, in_club, "window"
		),
		totals as (
			select sex, in_club, count(1) as total
			from windows group by sex, in_club
		)
		select sex, in_club, "minutes", c / total p from "minutes"
		natural join totals
	) to 'results/club_young_distributions.csv';
END
fi

if [ ! -e results/club_young_pb_distributions.csv ]; then
	(cat | duckdb) <<END
	copy (
		with pb as (
			select runner, age, "group", min("time") as "time"
			from 'performances.tsv' natural join 'events.tsv'
			group by runner, age, "group"
		),
		windows as (
			select sex, "group" is not null in_club,
			floor("time" / (60 / 4)) / 4 "window" from pb
			natural join 'runners.tsv'
			where "time" < 60 * 75
			and age <= 35 and age >= 18
		),
		"minutes" as (
			select sex, in_club, "window" "minutes", count(1) c
			from windows
			group by sex, in_club, "window"
		),
		totals as (
			select sex, in_club, count(1) as total
			from windows group by sex, in_club
		)
		select sex, in_club, "minutes", c / total p from "minutes"
		natural join totals
	) to 'results/club_young_pb_distributions.csv';
END
fi

rm results/club_young_and_good_*.csv

if [ ! -e results/club_young_and_good_distributions.csv ]; then
	(cat | duckdb) <<END
	copy (
		with windows as (
			select sex, "group" is not null in_club,
			floor("time" / (60 / 4)) / 4 "window" from 'performances.tsv'
			natural join 'runners.tsv'
			where "time" < 60 * 75
			and age <= 35 and age >= 18
			and "group" in ($ELITE_CLUBS)
		),
		"minutes" as (
			select sex, in_club, "window" "minutes", count(1) c
			from windows
			group by sex, in_club, "window"
		),
		totals as (
			select sex, in_club, count(1) as total
			from windows group by sex, in_club
		)
		select sex, in_club, "minutes", c / total p from "minutes"
		natural join totals
	) to 'results/club_young_and_good_distributions.csv';
END
fi

if [ ! -e results/club_young_and_good_pb_distributions.csv ]; then
	(cat | duckdb) <<END
	copy (
		with pb as (
			select runner, age, min("time") as "time", "group"
			from 'performances.tsv' natural join 'events.tsv' group by runner, age, "group"
		),
		windows as (
			select sex, "group" is not null in_club,
			floor("time" / (60 / 4)) / 4 "window" from pb
			natural join 'runners.tsv'
			where "time" < 60 * 75
			and age <= 35 and age >= 18
			and "group" in ($ELITE_CLUBS)
		),
		"minutes" as (
			select sex, in_club, "window" "minutes", count(1) c
			from windows
			group by sex, in_club, "window"
		),
		totals as (
			select sex, in_club, count(1) as total
			from windows group by sex, in_club
		)
		select sex, in_club, "minutes", c / total p from "minutes"
		natural join totals
	) to 'results/club_young_and_good_pb_distributions.csv';
END
fi


if [ ! -e results/country_pb_distributions.csv ]; then
	(cat | duckdb) <<END
	copy (
		with country_popularity as (
			select country, count(1) cc from 'performances.tsv'
			natural join 'events.tsv' group by country
		),
		runner_countries as (
			select runner, country, count(1) c
			from 'performances.tsv'
			natural join 'events.tsv' group by runner, country
		),
		runner_main_country_c as (
			select runner, max(c) c from runner_countries group by runner
		),
		runner_likely_country as (
			select
				runner,
				country as home,
				c,
				dense_rank() over (partition by runner order by cc) r
			from runner_countries
			natural join runner_main_country_c
			natural join country_popularity
		),
		runner_home as (
			select runner, home from runner_likely_country where r = 1
		),
		pb as (
			select runner, home, age, min("time") as "time", "group"
			from 'performances.tsv'
			natural join 'events.tsv'
			natural join runner_home
			group by runner, age, "group", home
		),
		windows as (
			select home, sex, "group" is not null in_club,
			floor("time" / (60 / 4)) / 4 "window" from pb
			natural join 'runners.tsv'
			where "time" < 60 * 75
			and age <= 35 and age >= 18
		),
		"minutes" as (
			select sex, home, in_club, "window" "minutes", count(1) c
			from windows
			group by sex, in_club, "window", home
		),
		totals as (
			select home, sex, in_club, count(1) as total
			from windows group by sex, in_club, home
		)
		select home as country, sex, in_club, "minutes", c / total p from "minutes"
		natural join totals
	) to 'results/country_pb_distributions.csv';
END
fi

