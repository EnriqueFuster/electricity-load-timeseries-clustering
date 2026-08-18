#' Fit complete-linkage hierarchical clustering with DTW distances
#' @param matrix Series-by-time matrix.
#' @param k Number of clusters.
#' @param seed Retained for a common fitting interface; the method is deterministic.
#' @param window_size Sakoe-Chiba window in time steps.
#' @param distance_matrix Optional precomputed DTW distance matrix.
#' @return Standardized clustering result including the dendrogram model.
fit_dtw_hierarchical_clustering <- function(matrix, k, seed = 4107L, window_size = 12L,
                                            distance_matrix = NULL) {
  distance <- distance_matrix %||% calculate_distance_matrix(matrix, "dtw_basic", window_size)
  model <- stats::hclust(distance, method = "complete")
  clusters <- stats::cutree(model, k = k)
  names(clusters) <- rownames(matrix)

  list(
    cluster = clusters,
    model = model,
    algorithm = "dtw_hclust",
    distance = "dtw_basic",
    distance_matrix = distance
  )
}
