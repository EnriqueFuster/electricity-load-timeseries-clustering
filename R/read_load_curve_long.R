#' Read a canonical long-format CSV
#' @param path CSV path.
#' @param timezone IANA timezone.
#' @return Canonical load-curve data frame.
read_load_curve_long <- function(path, timezone = "UTC") {
  raw <- utils::read.csv(path, stringsAsFactors = FALSE)
  if (!all(c("series_id", "timestamp", "value") %in% names(raw))) {
    stop("Long input requires series_id, timestamp and value columns.")
  }
  timestamps <- as.POSIXct(raw$timestamp, format = "%Y-%m-%d %H:%M:%S", tz = timezone)
  iso <- is.na(timestamps)
  timestamps[iso] <- as.POSIXct(raw$timestamp[iso], format = "%Y-%m-%dT%H:%M:%SZ", tz = "UTC")
  date_only <- is.na(timestamps)
  timestamps[date_only] <- as.POSIXct(raw$timestamp[date_only], format = "%Y-%m-%d", tz = timezone)
  raw$timestamp <- timestamps
  raw$value <- suppressWarnings(as.numeric(raw$value))
  if (!"imputed" %in% names(raw)) raw$imputed <- 0L
  raw[c("series_id", "timestamp", "value", "imputed")]
}
