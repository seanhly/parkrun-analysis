(
	echo -e $'code\turl' && curl -s https://images.parkrun.com/events.json |
		jq -r '.countries|to_entries[]|[.key,.value.url]|@tsv' |
		grep -v ^0 |
		sort -n
) > /tmp/countries.tsv
(
	echo -e $'code\tpath' && curl -s https://images.parkrun.com/events.json |
		jq -r '.events.features[].properties|[.countrycode,.eventname]|@tsv' |
		grep -v '\-juniors$' |
		sort -n
) > /tmp/paths.tsv
output="$(duckdb -csv <<< "with c as (select * from '/tmp/countries.tsv'),
p as (select * from '/tmp/paths.tsv')
select 'https://' || url || '/' || path || '/' from c natural join p" | tail -n+2)"
echo "$output" | grep www.parkrun.ie/ | sort
echo "$output" | grep -v www.parkrun.ie/ | sort
