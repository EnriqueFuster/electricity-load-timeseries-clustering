# Preserve within-profile calendar variability in recurring cluster bands.
build_cluster_ribbon_observations <- function(result, horizon, normalization) {
  annual_matrix <- normalize_load_curve(build_annual_hourly_matrix(result$clean), normalization)
  observations <- do.call(rbind, lapply(rownames(annual_matrix), function(series_id) {
    series <- result$clean[result$clean$series_id == series_id, , drop = FALSE]
    series <- series[format(series$timestamp, "%m-%d", tz = "UTC") != "02-29", , drop = FALSE]
    series <- series[order(series$timestamp), , drop = FALSE]
    if (nrow(series) != ncol(annual_matrix)) {
      stop("Ribbon observations could not be aligned to the annual matrix.")
    }
    calendar <- as.POSIXlt(series$timestamp, tz = "UTC")
    interval <- if (horizon == "daily") {
      calendar$hour + 1L
    } else {
      ((calendar$wday + 6L) %% 7L) * 24L + calendar$hour + 1L
    }
    data.frame(
      series_id = series_id,
      interval = interval,
      normalized_value = as.numeric(annual_matrix[series_id, ]),
      stringsAsFactors = FALSE
    )
  }))
  assignments <- result$assignments[c("series_id", "cluster")]
  merge(observations, assignments, by = "series_id", sort = FALSE)
}
