COPY (
	with w as (
		select
			(floor(time / 15) * 15) / 60 as window,
			country,
			sex,
			"group" is not null as in_club
			/* case when age < 60 then 5 else age // 10 end as decade */
		from '/tmp/performances.tsv'
		join '/tmp/runners.tsv' using (runner)
		join '/tmp/events.tsv' using (event)
		where sex is not null
		and country in ('ie', 'com.au')
		and time < 34 * 60
		/* and age BETWEEN 18 and 80 */
	),
	c as (
		/* select sex, decade, "window", count(1) c from w group by sex, decade, "window" */
		select country, sex, in_club, "window", count(1) c from w group by country, sex, "window", in_club
	),
	cc as (
		/* select sex, decade, sum(c) cc from c group by sex, decade */
		select country, sex, in_club, sum(c) cc from c group by country, sex, in_club
	)
	/* select sex, decade, "window", c / cc as p from c natural join cc */
	select country, sex, in_club, "window", c / cc as p from c natural join cc
) to '/tmp/data.csv';
