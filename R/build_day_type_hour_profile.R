#' Build a compact weekday/weekend hourly representation
#' @param data Canonical hourly load curves.
#' @param statistic Either median or mean.
#' @return Long representation with 48 ordered features per series.
build_day_type_hour_profile <- function(data, statistic = "median") {
  aggregate_function <- switch(statistic,
    mean = mean,
    median = stats::median,
    stop("Unsupported statistic.")
  )

  calendar <- as.POSIXlt(data$timestamp, tz = "UTC")
  weekday <- (calendar$wday + 6L) %% 7L + 1L
  data$day_type <- ifelse(weekday <= 5L, "weekday", "weekend")
  data$hour_of_day <- calendar$hour + 1L

  profile <- stats::aggregate(
    value ~ series_id + day_type + hour_of_day,
    data,
    aggregate_function,
    na.rm = TRUE
  )
  profile$feature_index <- ifelse(
    profile$day_type == "weekday",
    profile$hour_of_day,
    24L + profile$hour_of_day
  )
  profile <- profile[order(profile$series_id, profile$feature_index), ]
  profile[c("series_id", "feature_index", "day_type", "hour_of_day", "value")]
}
