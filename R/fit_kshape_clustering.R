#' Fit k-Shape clustering
#' @param matrix Series-by-time matrix. k-Shape z-normalization is applied here.
#' @param k Number of clusters.
#' @param seed Random seed.
#' @return Standardized clustering result.
fit_kshape_clustering <- function(matrix, k, seed = 4107L) {
  if (!requireNamespace("dtwclust", quietly = TRUE)) {
    stop("Package 'dtwclust' is required for k-Shape.")
  }
  effective_matrix <- normalize_load_curve(matrix, "zscore")
  series <- lapply(seq_len(nrow(effective_matrix)), function(i) {
    as.numeric(effective_matrix[i, ])
  })
  names(series) <- rownames(matrix)
  fit <- dtwclust::tsclust(series,
    type = "p", k = k, distance = "sbd",
    centroid = "shape", preproc = NULL, seed = seed, trace = FALSE
  )
  clusters <- fit@cluster
  names(clusters) <- rownames(matrix)
  prototypes <- do.call(rbind, lapply(fit@centroids, as.numeric))
  list(
    cluster = clusters, prototypes = prototypes, model = fit,
    algorithm = "kshape", distance = "sbd",
    effective_normalization = "zscore"
  )
}
