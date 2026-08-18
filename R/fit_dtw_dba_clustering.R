#' Fit partitional DTW clustering with DBA centroids
#' @param matrix Series-by-time matrix.
#' @param k Number of clusters.
#' @param seed Random seed.
#' @param window_size Sakoe-Chiba window in time steps.
#' @return Standardized clustering result.
fit_dtw_dba_clustering <- function(matrix, k, seed = 4107L, window_size = 12L) {
  if (!requireNamespace("dtwclust", quietly = TRUE)) {
    stop("Package 'dtwclust' is required for DTW + DBA.")
  }
  series <- lapply(seq_len(nrow(matrix)), function(i) as.numeric(matrix[i, ]))
  names(series) <- rownames(matrix)
  fit <- dtwclust::tsclust(series,
    type = "p", k = k, distance = "dtw_basic",
    centroid = "dba", seed = seed, trace = FALSE,
    args = dtwclust::tsclust_args(dist = list(window.size = as.integer(window_size)))
  )
  clusters <- fit@cluster
  names(clusters) <- rownames(matrix)
  prototypes <- do.call(rbind, lapply(fit@centroids, as.numeric))
  list(
    cluster = clusters, prototypes = prototypes, model = fit,
    algorithm = "dtw_dba", distance = "dtw_basic"
  )
}
