#' Validate the canonical load-curve schema
#' @param data Canonical data frame.
#' @return Invisibly TRUE or an error.
validate_load_curve_schema <- function(data) {
  required <- c("series_id", "timestamp", "value")
  missing <- setdiff(required, names(data))
  if (length(missing)) stop("Missing canonical columns: ", paste(missing, collapse = ", "))
  if (!inherits(data$timestamp, "POSIXct")) stop("timestamp must be POSIXct.")
  if (!is.numeric(data$value)) stop("value must be numeric.")
  if (any(!nzchar(as.character(data$series_id)))) stop("series_id cannot be blank.")
  invisible(TRUE)
}
