#' Fit Partitioning Around Medoids with a declared distance
#' @param matrix Series-by-feature matrix.
#' @param k Number of clusters.
#' @param distance_name Euclidean, Manhattan or constrained DTW.
#' @param window_size DTW warping window.
#' @param distance_matrix Optional previously computed distance matrix.
#' @return Standardized clustering result.
fit_pam_clustering <- function(matrix, k, distance_name = "euclidean", window_size = 12L,
                               distance_matrix = NULL) {
  distance <- distance_matrix %||% calculate_distance_matrix(matrix, distance_name, window_size)
  fit <- cluster::pam(distance, k = k, diss = TRUE)
  clusters <- fit$clustering
  names(clusters) <- rownames(matrix)
  medoid_rows <- match(fit$medoids, rownames(matrix))
  list(
    cluster = clusters,
    prototypes = matrix[medoid_rows, , drop = FALSE],
    model = fit,
    algorithm = "pam",
    distance = distance_name,
    distance_matrix = distance
  )
}
