#' Calculate Euclidean distance to assigned prototype
#' @param matrix Series-by-feature matrix.
#' @param clusters Named labels.
#' @param prototypes Cluster-by-feature matrix.
#' @return Named numeric distances.
calculate_distance_to_prototype <- function(matrix, clusters, prototypes) {
  out <- vapply(seq_len(nrow(matrix)), function(i) {
    sqrt(sum((matrix[i, ] - prototypes[as.character(clusters[i]), ])^2))
  }, numeric(1))
  names(out) <- rownames(matrix)
  out
}
