#' Build a 168-value hour-of-week representation
#' @param data Canonical data for accepted series.
#' @param statistic Either median or mean.
#' @return Long representation with hour_of_week 1..168.
build_typical_week <- function(data, statistic = "median") {
  fun <- switch(statistic,
    mean = mean,
    median = stats::median,
    stop("Unsupported statistic.")
  )
  lt <- as.POSIXlt(data$timestamp, tz = "UTC")
  monday_day <- (lt$wday + 6L) %% 7L
  data$hour_of_week <- monday_day * 24L + lt$hour + 1L
  values <- stats::aggregate(value ~ series_id + hour_of_week, data, fun, na.rm = TRUE)
  complete <- expand.grid(
    series_id = unique(data$series_id), hour_of_week = 1:168,
    stringsAsFactors = FALSE
  )
  out <- merge(complete, values, by = c("series_id", "hour_of_week"), all.x = TRUE, sort = FALSE)
  out$hour_of_week <- as.integer(as.character(out$hour_of_week))
  out[order(out$series_id, out$hour_of_week), ]
}
