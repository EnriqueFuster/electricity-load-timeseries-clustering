#' Build a meter representation conditioned by season, day type and time block
#' @param data Clean hourly observations.
#' @param statistic Aggregation statistic: median or mean.
#' @return Long feature table with one row per meter and observed calendar block.
build_seasonal_daypart_profile <- function(data, statistic = "median") {
  calendar <- as.POSIXlt(data$timestamp, tz = "UTC")
  month <- calendar$mon + 1L
  weekday <- (calendar$wday + 6L) %% 7L + 1L

  data$season <- ifelse(month %in% c(12L, 1L, 2L), "winter",
    ifelse(month %in% 3:5, "spring", ifelse(month %in% 6:8, "summer", "autumn"))
  )
  data$day_type <- ifelse(weekday <= 5L, "weekday", "weekend")
  data$daypart <- calendar$hour %/% 4L

  aggregate_function <- if (identical(statistic, "mean")) mean else stats::median
  profile <- stats::aggregate(
    value ~ series_id + season + day_type + daypart,
    data,
    aggregate_function,
    na.rm = TRUE
  )

  profile$feature_name <- paste(profile$season, profile$day_type,
    sprintf("h%02d_%02d", profile$daypart * 4L, (profile$daypart + 1L) * 4L),
    sep = "__"
  )
  feature_order <- sort(unique(profile$feature_name))
  profile$feature_index <- match(profile$feature_name, feature_order)
  profile[order(profile$series_id, profile$feature_index), ]
}
