#' Linearly impute internal gaps in one series
#' @param data One regularized series.
#' @param max_gap Maximum consecutive hours to interpolate.
#' @return Data frame with transparent imputation flags.
impute_load_curve <- function(data, max_gap = 24L) {
  values <- data$value
  missing <- is.na(values)
  if (any(missing) && sum(!missing) >= 2L) {
    candidate <- stats::approx(which(!missing), values[!missing],
      xout = seq_along(values),
      rule = 1
    )$y
    runs <- rle(missing)
    ends <- cumsum(runs$lengths)
    starts <- ends - runs$lengths + 1L
    for (i in which(runs$values & runs$lengths <= max_gap)) {
      values[starts[i]:ends[i]] <- candidate[starts[i]:ends[i]]
    }
  }
  data$imputed[missing & !is.na(values)] <- 1L
  data$value <- values
  data
}
