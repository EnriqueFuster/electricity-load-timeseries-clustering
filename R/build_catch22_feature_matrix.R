#' Extract catch22 or catch24 features from annual load curves
#' @param annual_matrix Series-by-hour annual matrix.
#' @param seasonal Extract a separate feature block for each meteorological season.
#' @param include_mean_sd Add mean and standard deviation (the catch24 extension).
#' @return Standardized series-by-feature matrix.
build_catch22_feature_matrix <- function(annual_matrix, seasonal = FALSE, include_mean_sd = FALSE) {
  if (!requireNamespace("Rcatch22", quietly = TRUE)) {
    stop("Representation requires package 'Rcatch22'. Run renv::restore() before using catch22.")
  }

  hour_dates <- seq(
    as.POSIXct("2021-01-01 00:00:00", tz = "UTC"),
    as.POSIXct("2021-12-31 23:00:00", tz = "UTC"),
    by = "hour"
  )
  month <- as.integer(format(hour_dates, "%m", tz = "UTC"))
  blocks <- if (isTRUE(seasonal)) {
    seasonal_catch22_blocks(month)
  } else {
    list(annual = seq_len(ncol(annual_matrix)))
  }

  extract_features <- function(values) {
    result <- suppressWarnings(Rcatch22::catch22_all(as.numeric(values), catch24 = FALSE))
    if (is.data.frame(result) && all(c("names", "values") %in% names(result))) {
      features <- stats::setNames(as.numeric(result$values), result$names)
    } else {
      features <- unlist(result, use.names = TRUE)
    }
    if (isTRUE(include_mean_sd)) {
      features <- c(features,
        mean = mean(values),
        sd = stats::sd(values)
      )
    }
    features
  }

  rows <- lapply(seq_len(nrow(annual_matrix)), function(row_index) {
    unlist(lapply(names(blocks), function(block_name) {
      values <- extract_features(annual_matrix[row_index, blocks[[block_name]]])
      stats::setNames(values, paste(block_name, names(values), sep = "__"))
    }), use.names = TRUE)
  })
  features <- do.call(rbind, rows)
  rownames(features) <- rownames(annual_matrix)

  invalid <- !is.finite(features)
  if (any(invalid)) features[invalid] <- NA_real_
  medians <- apply(features, 2L, stats::median, na.rm = TRUE)
  for (column in seq_len(ncol(features))) {
    features[is.na(features[, column]), column] <- medians[column]
  }
  varying <- apply(features, 2L, stats::sd) > 0
  if (!any(varying)) stop("catch22 produced no varying finite features.")
  scale(features[, varying, drop = FALSE])
}
