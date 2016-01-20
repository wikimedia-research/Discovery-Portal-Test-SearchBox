# The actual analysis!

# Dependencies
library(wmf)
library(BCDA)
library(data.table)
library(lubridate)
library(ggplot2)
library(ggthemes)

theme_gg <- function (base_size = 12, base_family = "sans") {
  (theme_foundation(base_size = base_size, base_family = base_family) + 
     theme(line = element_line(), rect = element_rect(fill = ggthemes:::ggthemes_data$fivethirtyeight["ltgray"], 
                                                      linetype = 0, colour = NA), text = element_text(colour = ggthemes:::ggthemes_data$fivethirtyeight["dkgray"]), 
           axis.title.y = element_text(size = rel(1.5), angle = 90, 
                                       vjust = 1.5), axis.text = element_text(size=rel(1.5)), axis.title.x = element_text(size = rel(1.5)), 
           axis.ticks = element_blank(), axis.line = element_blank(), 
           legend.background = element_rect(), legend.position = "bottom", 
           legend.direction = "horizontal", legend.box = "vertical", 
           panel.grid = element_line(colour = NULL), panel.grid.major = element_line(colour = ggthemes:::ggthemes_data$fivethirtyeight["medgray"]), 
           panel.grid.minor = element_blank(), plot.title = element_text(hjust = 0, size = rel(1.5), face = "bold"), strip.background = element_rect(),
           legend.text = element_text(size=18), legend.title = element_text(size=rel(1.5)),
           legend.key.size = unit(1,"in")))
}
# Grab the data

data <- wmf::mysql_read("SELECT LEFT(timestamp,8) AS date, event_session_id AS session,
                         event_cohort AS cohort, event_event_type AS event_type,
                         event_section_used AS Section_used
                         FROM WikipediaPortal_14377354
                         WHERE LEFT(timestamp,8) BETWEEN 20160113 AND 20160120
                         AND event_cohort IN('abtest1','abtest2','control')",
                        "log")
data <- as.data.table(data)
data$date <- as.Date(lubridate::ymd(data$date))

# Exploratory data analysis

sessions_group_day <- data[,list(length(unique(session))), by = c("date", "cohort")]

ggsave(filename = "eda_sessions_by_day.png",
       plot = ggplot(sessions_group_day, aes(date, V1, group = cohort, colour = cohort)) +
         geom_line() + theme_gg() + labs(title = "Unique users in the test, by day and group",
                                         x = "Date", y = "Users"))

sessions_group <- data[,list(length(unique(session))), by = c("cohort")]
ggsave(filename = "eda_sessions.png",
       plot = ggplot(sessions_group, aes(cohort, V1)) +
         geom_bar(stat="identity", fill="#56B4E9") + theme_gg() +
         labs(title = "Unique users in the test, by group", x = "Group", y = "Users"))

