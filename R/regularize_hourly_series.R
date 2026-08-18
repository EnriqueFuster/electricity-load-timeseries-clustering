#' Put one series on a complete UTC hourly grid
#' @param data One canonical series.
#' @return Regularized data frame.
regularize_hourly_series <- function(data) {
  x <- data[!is.na(data$timestamp), ]
  x <- x[order(x$timestamp), ]
  x <- x[!duplicated(x$timestamp), ]
  grid <- data.frame(timestamp = seq(min(x$timestamp), max(x$timestamp), by = "hour"))
  out <- merge(grid, x, by = "timestamp", all.x = TRUE, sort = TRUE)
  out$series_id <- x$series_id[1]
  out$imputed[is.na(out$imputed)] <- 1L
  out[c("series_id", "timestamp", "value", "imputed")]
}
