#' Summarize data quality by series
#' @param data Canonical load curves.
#' @param config Quality configuration.
#' @return Quality data frame.
summarize_data_quality <- function(data, config) {
  validate_load_curve_schema(data)
  rows <- lapply(split(data, data$series_id), function(x) {
    valid_time <- x$timestamp[!is.na(x$timestamp)]
    start <- if (length(valid_time)) min(valid_time) else as.POSIXct(NA)
    end <- if (length(valid_time)) max(valid_time) else as.POSIXct(NA)
    expected <- if (length(valid_time)) {
      as.integer(difftime(end, start,
        units = "hours"
      )) + 1L
    } else {
      0L
    }
    gaps <- max(0L, expected - length(unique(valid_time)))
    miss <- sum(is.na(x$value)) + gaps
    pct <- if (expected > 0) 100 * miss / expected else 100
    dup <- sum(duplicated(x$timestamp[!is.na(x$timestamp)]))
    neg <- sum(x$value < 0, na.rm = TRUE)
    coverage <- if (length(valid_time)) expected / 24 else 0
    constant <- stats::sd(x$value, na.rm = TRUE) < .Machine$double.eps^0.5
    annual <- find_complete_natural_years(
      x,
      config$complete_year_max_missing_pct %||% config$max_missing_pct
    )
    complete_years <- if (nrow(annual)) annual$year[annual$complete] else integer()
    selected_year <- if (length(complete_years)) max(complete_years) else NA_integer_
    require_year <- isTRUE(config$require_complete_natural_year %||% FALSE)
    reasons <- c(
      if (anyNA(x$timestamp)) "invalid_timestamp", if (dup) "duplicate_timestamp",
      if (neg && identical(config$negative_values, "exclude")) "negative_values",
      if (pct > config$max_missing_pct) "excess_missingness",
      if (coverage < config$min_coverage_days) "short_coverage",
      if (require_year && !length(complete_years)) "no_complete_natural_year",
      if (constant) "constant_curve"
    )
    status <- if (length(reasons)) {
      "exclude"
    } else if (pct > config$warning_missing_pct) {
      "warning"
    } else {
      "pass"
    }
    data.frame(
      series_id = x$series_id[1], start, end, observations = nrow(x),
      expected_observations = expected, missing_count = miss,
      missing_pct = round(pct, 3), duplicated_timestamps = dup,
      negative_values = neg, coverage_days = round(coverage, 1),
      complete_natural_years = length(complete_years), selected_year,
      imputed_pct = round(100 * mean(x$imputed %||% 0, na.rm = TRUE), 3),
      quality_status = status, exclusion_reason = paste(reasons, collapse = ";")
    )
  })
  do.call(rbind, rows)
}
