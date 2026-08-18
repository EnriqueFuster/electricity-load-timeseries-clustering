#' Aggregate selected clusters by calendar day and hour
#' @param clean Clean hourly observations.
#' @param assignments Selected cluster assignments.
#' @return Cluster, day-of-year and hour intensity table.
calculate_cluster_calendar_heatmap <- function(clean, assignments) {
  data <- merge(clean, assignments[c("series_id", "cluster")], by = "series_id", sort = FALSE)
  calendar <- as.POSIXlt(data$timestamp, tz = "UTC")
  data$day_of_year <- calendar$yday + 1L
  data$hour_of_day <- calendar$hour

  series_mean <- ave(data$value, data$series_id, FUN = function(x) mean(x, na.rm = TRUE))
  data$relative_intensity <- ifelse(series_mean > 0, data$value / series_mean, 0)

  raw <- stats::aggregate(
    value ~ cluster + day_of_year + hour_of_day,
    data,
    mean,
    na.rm = TRUE
  )
  relative <- stats::aggregate(
    relative_intensity ~ cluster + day_of_year + hour_of_day,
    data,
    mean,
    na.rm = TRUE
  )

  observed <- merge(raw, relative, by = c("cluster", "day_of_year", "hour_of_day"))
  grid <- expand.grid(
    cluster = sort(unique(assignments$cluster)),
    day_of_year = seq_len(366L),
    hour_of_day = 0:23
  )
  output <- merge(grid, observed, by = c("cluster", "day_of_year", "hour_of_day"), all.x = TRUE)
  names(output)[names(output) == "value"] <- "mean_consumption"
  output$observed <- !is.na(output$mean_consumption)
  output[order(output$cluster, output$day_of_year, output$hour_of_day), ]
}
