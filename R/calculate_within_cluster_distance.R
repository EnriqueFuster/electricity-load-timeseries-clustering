#' Calculate method-consistent atypicality distances within each cluster
#' @param matrix Active representation matrix.
#' @param clusters Named cluster labels.
#' @param fit Standardized fitted model.
#' @param window_size DTW window used by the experiment.
#' @return Mean distance from each series to the other members of its cluster.
calculate_within_cluster_distance <- function(matrix, clusters, fit, window_size = 12L) {
  distance <- fit$distance_matrix %||% calculate_distance_matrix(matrix, fit$distance, window_size)
  distance <- as.matrix(distance)
  output <- vapply(seq_len(nrow(matrix)), function(index) {
    members <- which(clusters == clusters[index])
    peers <- setdiff(members, index)
    if (!length(peers)) {
      return(0)
    }
    mean(distance[index, peers])
  }, numeric(1))
  names(output) <- rownames(matrix)
  output
}
