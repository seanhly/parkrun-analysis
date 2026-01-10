library(ggplot2)
library(lubridate)
library(plotly)
library(htmlwidgets)

d = read.csv("/tmp/parkrun.tsv", sep="\t")
print("Extending shorts.")
print("Rows:")
print(nrow(d))
d$t = ms('0:0')
d[nchar(d$time) == 5,]$t = ms(d[nchar(d$time) == 5,]$time)
d[nchar(d$time) > 5,]$t = hms(d[nchar(d$time) > 5,]$time)
print("Getting HMS.")
d$seconds <- period_to_seconds(d$t)
d = d[!(d$age %in% c("---", "10", "11-14", "15-17", "C", "", "85-89", "80-84", "75-79", "70-74")),]
d = d[d$t < ms('30:00'),]
m = d[d$sex == 'M',]
#m = m[
#	m$club %in% c(
#		"Portmarnock Athletic Club",
#		"Raheny Shamrock AC",
#		"Clonliffe Harriers A.C.",
#		"Lusk Athletic Club"
#	),
#]
print("Plotting.")
p = ggplot(m, aes(x=seconds, fill=`club`)) +
	geom_histogram(
		binwidth=16,
		position="dodge"
	) +
	scale_x_continuous(
		breaks = seq(0, 3600, by=120),  # One tick per 15s
		labels = function(x) format(as.POSIXct(x, origin = "1970-01-01", tz = "UTC"), "%H:%M")
	)
print("Saving.")
#ggsave("plot.png", p, width=16, height=8, unit="in")
#saveWidget(ggplotly(p), file = "plot.html")
m = aggregate(m$seconds, by=list(club=m$club, runner=m$runner), FUN=min)
m = data.frame(club=m$club, runner=m$runner, seconds=m$x)
club_means = aggregate(
	m$seconds, by=list(club=m$club), FUN=mean
)
club_means = data.frame(club=club_means$club, mean=club_means$x)
club_totals = aggregate(
	m$seconds, by=list(club=m$club), FUN=length
)
club_totals = data.frame(club=club_totals$club, total=club_totals$x)
club_mins = aggregate(
	m$seconds, by=list(club=m$club), FUN=min
)
club_mins = data.frame(club=club_mins$club, mins=club_mins$x)
means_and_totals = merge(club_means, club_totals, by=c("club"))
means_and_totals = merge(means_and_totals, club_mins, by=c("club"))
means_and_totals = means_and_totals[means_and_totals$total > 20,]
print(means_and_totals[order(means_and_totals$mean),])
