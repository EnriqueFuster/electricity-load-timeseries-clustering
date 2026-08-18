#' Calculate the Dunn index from a distance matrix
#' @param clusters Cluster labels.
#' @param distances A dist object.
#' @return Dunn index.
calculate_dunn_index <- function(clusters, distances) {
  d <- as.matrix(distances)
  groups <- split(seq_along(clusters), clusters)
  diameters <- vapply(groups, function(ix) if (length(ix) < 2L) 0 else max(d[ix, ix]), numeric(1))
  pairs <- utils::combn(seq_along(groups), 2)
  separation <- apply(pairs, 2, function(p) min(d[groups[[p[1]]], groups[[p[2]]], drop = FALSE]))
  min(separation) / max(diameters)
}
