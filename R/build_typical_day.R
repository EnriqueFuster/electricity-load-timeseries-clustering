#' Build a 24-value hour-of-day representation
#' @param data Canonical data.
#' @param statistic Either median or mean.
#' @return Long daily representation.
build_typical_day <- function(data, statistic = "median") {
  fun <- switch(statistic,
    mean = mean,
    median = stats::median,
    stop("Unsupported statistic.")
  )
  data$hour_of_day <- as.POSIXlt(data$timestamp, tz = "UTC")$hour + 1L
  stats::aggregate(value ~ series_id + hour_of_day, data, fun, na.rm = TRUE)
}
