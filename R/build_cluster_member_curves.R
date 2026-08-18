#' Attach selected clusters to their weekly member curves
#' @param typical_week Long 168-hour representation.
#' @param normalized_week_matrix Normalized 168-hour matrix.
#' @param assignments Selected cluster assignments.
#' @return Long table containing original and normalized weekly values.
build_cluster_member_curves <- function(typical_week, normalized_week_matrix, assignments) {
  normalized <- data.frame(
    series_id = rep(rownames(normalized_week_matrix), each = ncol(normalized_week_matrix)),
    hour_of_week = rep(seq_len(ncol(normalized_week_matrix)), nrow(normalized_week_matrix)),
    normalized_value = as.vector(t(normalized_week_matrix)),
    stringsAsFactors = FALSE
  )

  members <- merge(typical_week, normalized, by = c("series_id", "hour_of_week"), sort = FALSE)
  members <- merge(members, assignments[c("series_id", "cluster")], by = "series_id", sort = FALSE)
  members[order(members$cluster, members$series_id, members$hour_of_week), ]
}
