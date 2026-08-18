#' Find natural years with adequate hourly coverage
#' @param data One canonical hourly series.
#' @param max_missing_pct Maximum absent or missing-value share.
#' @return Data frame describing every calendar year present.
find_complete_natural_years <- function(data, max_missing_pct = 2) {
  valid <- data[!is.na(data$timestamp), , drop = FALSE]
  if (!nrow(valid)) {
    return(data.frame())
  }
  years <- sort(unique(as.integer(format(valid$timestamp, "%Y", tz = "UTC"))))

  rows <- lapply(years, function(year) {
    start <- as.POSIXct(sprintf("%d-01-01 00:00:00", year), tz = "UTC")
    end <- as.POSIXct(sprintf("%d-12-31 23:00:00", year), tz = "UTC")
    expected <- as.integer(difftime(end, start, units = "hours")) + 1L
    sample <- valid[valid$timestamp >= start & valid$timestamp <= end, , drop = FALSE]
    unique_hours <- length(unique(sample$timestamp))
    missing_values <- sum(is.na(sample$value))
    missing <- max(0L, expected - unique_hours) + missing_values
    missing_pct <- 100 * missing / expected

    data.frame(
      year = year,
      expected_hours = expected,
      observed_hours = unique_hours,
      missing_hours = missing,
      missing_pct = missing_pct,
      complete = unique_hours > 0L && missing_pct <= max_missing_pct
    )
  })
  do.call(rbind, rows)
}
