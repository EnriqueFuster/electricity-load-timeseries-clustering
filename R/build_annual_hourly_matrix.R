#' Align complete natural years on a common 8,760-hour calendar
#'
#' Leap-day observations are removed so meters selected from different years can
#' be compared at the same month, day and hour coordinates.
#' @param data Clean canonical hourly data for one selected year per series.
#' @return Series-by-hour matrix with 8,760 ordered columns.
build_annual_hourly_matrix <- function(data) {
  reference_hours <- seq(
    as.POSIXct("2021-01-01 00:00:00", tz = "UTC"),
    as.POSIXct("2021-12-31 23:00:00", tz = "UTC"),
    by = "hour"
  )
  reference_keys <- format(reference_hours, "%m-%d %H", tz = "UTC")

  month_day <- format(data$timestamp, "%m-%d", tz = "UTC")
  annual_data <- data[month_day != "02-29", , drop = FALSE]
  annual_data$calendar_key <- format(annual_data$timestamp, "%m-%d %H", tz = "UTC")

  ids <- sort(unique(annual_data$series_id))
  annual_matrix <- matrix(
    NA_real_,
    nrow = length(ids), ncol = length(reference_keys),
    dimnames = list(ids, sprintf("hour_%04d", seq_along(reference_keys)))
  )
  positions <- cbind(
    match(annual_data$series_id, ids),
    match(annual_data$calendar_key, reference_keys)
  )
  annual_matrix[positions] <- annual_data$value

  incomplete <- rowSums(!is.finite(annual_matrix)) > 0L
  if (any(incomplete)) {
    stop(
      paste0(
        "Annual representations require 8,760 finite hourly values after ",
        "imputation. Incomplete series:"
      ),
      paste(rownames(annual_matrix)[incomplete], collapse = ", ")
    )
  }
  annual_matrix
}
