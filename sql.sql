copy (
	with t as (
		select
			* EXCLUDE "time",
			case
				when length("time") = 5 then cast('00:' || "time" as time)
				else cast("time" as time)
			end "time",
			category
		from '/tmp/parkrun.tsv'
	),
	w as (select *, cast(floor((month - 1) / 3) + 1 as int) as quarter from 'dates.tsv'),
	by_quarter as (
		select runner, year, quarter, min("time") "time"
		from t natural join w group by runner, year, quarter order by runner, year, quarter
	),
	regulars as (
		select * from by_quarter
		where runner in (select runner from by_quarter group by runner having count(1) > 1)
	),
	best_by_runner as (select runner, min("time") "time" from regulars group by runner),
	improvers as (
		select
		*
		from regulars where runner in (
			select distinct runner from regulars r1
			join regulars r2 using (runner)
			where (r1.year < r2.year or (r1.year = r2.year and r1.quarter < r2.quarter))
			and r1.time > r2.time
			and EXTRACT(EPOCH FROM r1.time) / EXTRACT(EPOCH FROM r2.time) > 1.16
			and r2.time < cast('00:18:00' as time)
		)
	),
	improver_pbs as (
		select runner, min("time") "time" from improvers group by runner
	),
	improver_pb_rows as (
		select * from improvers natural join improver_pbs
	),
	improvers_up_to_pb as (
		select
			i.*,
			case when i.year = p.year and i.quarter = p.quarter
			then 0
			else
				(EXTRACT(EPOCH FROM i.time) - EXTRACT(EPOCH FROM p.time)) /
				((p.year + (p.quarter - 1) / 4 - (i.year + (i.quarter - 1) / 4)) * 4)
			end rate
		from improvers i
		join improver_pb_rows p
			on i.runner = p.runner
		where i.year < p.year or (i.year == p.year and i.quarter <= p.quarter)
	),
	incremental_improvers as (
		select i.* from improvers_up_to_pb i
		left join improvers_up_to_pb i2
			on i2.runner = i.runner
			and (i2.year < i.year or (i2.year = i.year and i2.quarter < i.quarter))
			and i2."time" < i.time
		where i2.runner is null
	),
	accelerated_improvers as (
		select * from incremental_improvers where runner in (
			select distinct runner from incremental_improvers i1
			join incremental_improvers i2 using (runner)
			where EXTRACT(EPOCH FROM i1.time) / EXTRACT(EPOCH FROM i2.time) > 1.16
		)
	),
	runner_improvement_rates as (
		select
			i.runner,
			case when i.year = p.year and i.quarter = p.quarter
			then 0
			else
				(EXTRACT(EPOCH FROM i.time) - EXTRACT(EPOCH FROM p.time)) /
				((p.year + (p.quarter - 1) / 4 - (i.year + (i.quarter - 1) / 4)) * 4)
			end rate
		from accelerated_improvers i
		join accelerated_improvers p
			on i.runner = p.runner
		where i.year < p.year or (i.year == p.year and i.quarter <= p.quarter)
		order by
			case when i.year = p.year and i.quarter = p.quarter
			then 0
			else
				(EXTRACT(EPOCH FROM i.time) - EXTRACT(EPOCH FROM p.time)) /
				((p.year + (p.quarter - 1) / 4 - (i.year + (i.quarter - 1) / 4)) * 4)
			end
	),
	max_accelerated_improvers as (
		select runner, max(rate) max_rate
		from runner_improvement_rates group by runner
	)
	select * from accelerated_improvers natural join max_accelerated_improvers
	order by max_rate desc, runner, year, quarter
)
to '/tmp/out.csv'
;
