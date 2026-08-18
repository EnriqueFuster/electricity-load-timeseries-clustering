#' Convert a long representation to a complete matrix
#' @param representation Long representation.
#' @return Matrix with series in rows.
representation_to_matrix <- function(representation) {
  ids <- sort(unique(representation$series_id))
  hours <- sort(unique(representation[[2]]))
  out <- matrix(NA_real_, nrow = length(ids), ncol = length(hours), dimnames = list(ids, hours))
  out[cbind(match(representation$series_id, ids), match(
    representation[[2]],
    hours
  ))] <- representation$value
  if (anyNA(out)) stop("Representation is incomplete after preprocessing.")
  out
}
