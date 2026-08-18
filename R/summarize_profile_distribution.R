#' Summarize the observed consumption distribution for each profile
#' @param data Canonical long load-curve data.
#' @return One row per series with descriptive consumption statistics.
summarize_profile_distribution <- function(data) {
  validate_load_curve_schema(data)

  rows <- lapply(split(data$value, data$series_id), function(values) {
    values <- values[is.finite(values)]
    if (!length(values)) {
      return(data.frame(
        minimum = NA_real_, q1 = NA_real_, mean = NA_real_,
        median = NA_real_, q3 = NA_real_, maximum = NA_real_
      ))
    }
    data.frame(
      minimum = min(values),
      q1 = stats::quantile(values, .25, names = FALSE),
      mean = mean(values),
      median = stats::median(values),
      q3 = stats::quantile(values, .75, names = FALSE),
      maximum = max(values)
    )
  })

  output <- do.call(rbind, rows)
  output$series_id <- rownames(output)
  rownames(output) <- NULL
  output[c("series_id", "minimum", "q1", "mean", "median", "q3", "maximum")]
}
