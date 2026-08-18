#' Calculate arithmetic cluster prototypes
#' @param matrix Series-by-feature matrix.
#' @param clusters Cluster labels.
#' @return Cluster-by-feature matrix.
calculate_cluster_prototypes <- function(matrix, clusters) {
  do.call(rbind, lapply(split(seq_len(nrow(matrix)), clusters), function(ix) {
    cluster_matrix <- matrix[
      ix,
      ,
      drop = FALSE
    ]
    colMeans(cluster_matrix)
  }))
}
