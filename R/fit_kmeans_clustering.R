#' Fit a reproducible K-means baseline
#' @param matrix Series-by-feature matrix.
#' @param k Number of clusters.
#' @param seed Random seed.
#' @return Standardized clustering result.
fit_kmeans_clustering <- function(matrix, k, seed = 4107L) {
  set.seed(seed)
  fit <- stats::kmeans(matrix, centers = k, nstart = 25, iter.max = 100)
  list(
    cluster = fit$cluster, prototypes = fit$centers, model = fit,
    algorithm = "kmeans", distance = "euclidean"
  )
}
