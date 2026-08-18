#' Replace source identifiers with neutral profile labels
#' @param data Canonical long load-curve data.
#' @param enabled Whether identifiers should be replaced.
#' @param prefix Prefix used for generated identifiers.
#' @return Data with the same rows and optionally anonymized series_id values.
anonymize_series_ids <- function(data, enabled = FALSE, prefix = "profile") {
  if (!isTRUE(enabled)) {
    return(data)
  }

  original_ids <- sort(unique(as.character(data$series_id)))
  width <- max(3L, nchar(length(original_ids)))
  anonymous_ids <- sprintf(paste0(prefix, "_%0", width, "d"), seq_along(original_ids))
  id_lookup <- stats::setNames(anonymous_ids, original_ids)

  data$series_id <- unname(id_lookup[as.character(data$series_id)])
  data
}
