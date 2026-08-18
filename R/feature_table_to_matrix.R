#' Convert engineered long features to a complete matrix
#' @param features Long table containing series_id, feature_index and value.
#' @return Complete series-by-feature matrix with column-median gap filling.
feature_table_to_matrix <- function(features) {
  ids <- sort(unique(features$series_id))
  feature_ids <- sort(unique(features$feature_index))
  matrix <- matrix(NA_real_,
    nrow = length(ids), ncol = length(feature_ids),
    dimnames = list(ids, feature_ids)
  )
  matrix[cbind(match(features$series_id, ids), match(
    features$feature_index,
    feature_ids
  ))] <- features$value

  for (column in seq_len(ncol(matrix))) {
    missing <- is.na(matrix[, column])
    if (any(missing)) matrix[missing, column] <- stats::median(matrix[, column], na.rm = TRUE)
  }
  matrix
}
