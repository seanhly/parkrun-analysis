library(ggplot2)
library(plotly)
library(htmlwidgets)
for (infix in c("_", "_pb_")) {
	d = read.csv(paste("results/general", infix, "distribution.csv", sep=""))
	p = ggplot(d, aes(x=minutes, y=p)) +
		geom_col(width=0.25) +
		geom_vline(aes(xintercept=19), color="red", linewidth=2)
	ggsave(paste("plots/general", infix, "distribution.png", sep=""), p, width=16, height=8, unit="in")
}
for (infix in c("_", "_pb_")) {
	d = read.csv(paste("results/sex", infix, "distribution.csv", sep=""))
	p = ggplot(d, aes(x=minutes, y=p, fill=sex)) +
		geom_col(width=0.25, position="dodge") +
		geom_vline(aes(xintercept=19), color="red", linewidth=2)
	ggsave(paste("plots/sex", infix, "distribution.png", sep=""), p, width=16, height=8, unit="in")
}
for (infix in c("_", "_pb_")) {
	d = read.csv(paste("results/young", infix, "distribution.csv", sep=""))
	p = ggplot(d, aes(x=minutes, y=p, fill=sex)) +
		geom_col(width=0.25, position="dodge") +
		geom_vline(aes(xintercept=19), color="red", linewidth=2)
	ggsave(paste("plots/young", infix, "distribution.png", sep=""), p, width=16, height=8, unit="in")
}
for (infix in c("_", "_pb_")) {
	d = read.csv(paste("results/club", infix, "distributions.csv", sep=""))
	p = ggplot(d, aes(x=minutes, y=p, color=sex, linetype=in_club)) +
		geom_line() +
		geom_vline(aes(xintercept=19), color="red", linewidth=2)
	ggsave(paste("plots/club", infix, "distributions.png", sep=""), p, width=16, height=8, unit="in")
}
for (infix in c("_", "_pb_")) {
	d = read.csv(paste("results/club_young", infix, "distributions.csv", sep=""))
	p = ggplot(d, aes(x=minutes, y=p, color=sex, linetype=in_club)) +
		geom_line() +
		geom_vline(aes(xintercept=19), color="red", linewidth=2) +
		geom_vline(aes(xintercept=17), color="green", linewidth=2)
	ggsave(paste("plots/club_young", infix, "distributions.png", sep=""), p, width=16, height=8, unit="in")
}
for (infix in c("_", "_pb_")) {
	d = read.csv(paste("results/club_young_and_good", infix, "distributions.csv", sep=""))
	p = ggplot(d, aes(x=minutes, y=p, color=sex, linetype=in_club)) +
		geom_line() +
		geom_vline(aes(xintercept=19), color="red", linewidth=2) +
		geom_vline(aes(xintercept=17), color="green", linewidth=2)
	ggsave(paste("plots/club_young_and_good", infix, "distributions.png", sep=""), p, width=16, height=8, unit="in")
}
d = read.csv("results/country_pb_distributions.csv")
p = ggplot(d, aes(x=minutes, y=p, color=country, linetype=paste(sex, in_club))) +
	geom_line() +
	geom_vline(aes(xintercept=19), color="red", linewidth=2)
ggsave("plots/country_pb_distributions.png", p, width=16, height=8, unit="in")
saveWidget(ggplotly(p), file = "plots/country_pb_distributions.html")
