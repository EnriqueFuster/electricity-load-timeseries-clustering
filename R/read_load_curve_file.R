#' Read one load-curve CSV into the canonical schema
#' @param path CSV path.
#' @param config Input configuration.
#' @return A data frame with series_id, timestamp, value and imputed.
read_load_curve_file <- function(path, config) {
  raw <- utils::read.csv(path,
    sep = config$delimiter %||% ",", check.names = FALSE,
    stringsAsFactors = FALSE
  )
  tc <- config$timestamp_column
  vc <- config$value_column
  if (!all(c(tc, vc) %in% names(raw))) stop("Missing required columns in ", basename(path))
  idc <- config$series_id_column
  ids <- if (!is.null(idc) && idc %in% names(raw)) {
    raw[[idc]]
  } else {
    tools::file_path_sans_ext(basename(path))
  }
  timestamps <- as.POSIXct(raw[[tc]],
    format = "%Y-%m-%d %H:%M:%S",
    tz = config$timezone %||% "UTC"
  )
  iso <- is.na(timestamps)
  timestamps[iso] <- as.POSIXct(raw[[tc]][iso], format = "%Y-%m-%dT%H:%M:%SZ", tz = "UTC")
  date_only <- is.na(timestamps)
  timestamps[date_only] <- as.POSIXct(raw[[tc]][date_only],
    format = "%Y-%m-%d",
    tz = config$timezone %||% "UTC"
  )
  data.frame(
    series_id = as.character(ids), timestamp = timestamps,
    value = suppressWarnings(as.numeric(raw[[vc]])),
    imputed = if ("imputed" %in% names(raw)) as.integer(raw$imputed) else 0L
  )
}
