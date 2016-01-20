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

# Now that we've done the EDA, let's do the actual analysis.

# Ignore sessions that involved clickthroughs but didn't involve search,
# for the time being.

# Analysis!
bae <- function(data){
  
  # For each cohort, identify the clickthrough rate
  split_data <- split(data, f = data$cohort)
  
  by_group_rates <- lapply(split_data, function(x){
    
    # Produce, for each session, a TRUE or FALSE
    results <- x[,j = {
      if(.N == 1 || !("clickthrough" %in% event_type)){
        FALSE
      } else {
        TRUE
      }
    }, by = "session"]
    
    # Return the number of failures and successes
    return(c(sum(results$V1), (nrow(results) - sum(results$V1))))
  })
  
  output <- list()
  
  # Test the first AB group against the control
  first_control <- matrix(c(by_group_rates$abtest1, by_group_rates$control), ncol=2, byrow = TRUE,
                          dimnames = list(c("Test","Control"), c("Success", "Failure")))
  output$first_control_diff_tail <- ci_prop_diff_tail(first_control) # -0.009389691  0.028738770
  output$first_control_risk <- ci_relative_risk(first_control) # 0.9772447 1.0729769
  
  # Second against control
  second_control <- matrix(c(by_group_rates$abtest2, by_group_rates$control), ncol=2, byrow = TRUE,
                           dimnames = list(c("Test","Control"), c("Success", "Failure")))
  output$second_control_diff_tail <- ci_prop_diff_tail(second_control) # 0.01672383 0.05504235
  output$second_control_risk <- ci_relative_risk(second_control) # 1.040519 1.139807
  
  return(output)
}

output <- list()

# Search-only
search_only <- data[,j={
  if("clickthrough" %in% event_type && !("search" %in% Section_used)){
    NULL
  } else {
    .SD
  }
}, by = "session"]

output$search_only <- bae(search_only)

# Non-search-only
non_search_only <- data[,j={
  if("clickthrough" %in% event_type && ("search" %in% Section_used)){
    NULL
  } else {
    .SD
  }
}, by = "session"]

output$non_search_only <- bae(non_search_only)

# Overall
output$overall <- bae(data)
save(output, file = "results.RData")