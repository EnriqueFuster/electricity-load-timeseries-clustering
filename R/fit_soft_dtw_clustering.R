#' Fit partitional clustering with Soft-DTW distance and centroids
#' @param matrix Series-by-time matrix.
#' @param k Number of clusters.
#' @param seed Random seed.
#' @param gamma Soft-minimum smoothing parameter.
#' @return Standardized clustering result.
fit_soft_dtw_clustering <- function(matrix, k, seed = 4107L, gamma = 0.05) {
  if (!requireNamespace("dtwclust", quietly = TRUE)) {
    stop("Package 'dtwclust' is required for Soft-DTW.")
  }
  series <- lapply(seq_len(nrow(matrix)), function(index) as.numeric(matrix[index, ]))
  names(series) <- rownames(matrix)
  arguments <- dtwclust::tsclust_args(
    dist = list(gamma = gamma),
    cent = list(gamma = gamma)
  )
  model <- dtwclust::tsclust(
    series,
    type = "p", k = k, distance = "sdtw", centroid = "sdtw_cent",
    seed = seed, trace = FALSE, args = arguments
  )
  clusters <- model@cluster
  names(clusters) <- rownames(matrix)
  list(
    cluster = clusters,
    prototypes = do.call(rbind, lapply(model@centroids, as.numeric)),
    model = model,
    distance_matrix = proxy::dist(series, method = "sdtw", gamma = gamma),
    algorithm = "soft_dtw",
    distance = "soft_dtw"
  )
}
