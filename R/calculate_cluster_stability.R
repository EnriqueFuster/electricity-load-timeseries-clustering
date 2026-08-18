#' Estimate stability under repeated meter subsampling
#' @param matrix Series-by-feature matrix.
#' @param recipe Clustering recipe identifier.
#' @param k Number of clusters.
#' @param seeds Integer seeds controlling the subsamples and stochastic fits.
#' @param window_size DTW window.
#' @param sample_share Share of meters retained in each repeat.
#' @return Mean adjusted Rand index over shared meters.
calculate_cluster_stability <- function(matrix, recipe, k, seeds, window_size = 12L,
                                        sample_share = 0.8, advanced = list()) {
  sample_size <- max(k + 1L, floor(nrow(matrix) * sample_share))
  sample_size <- min(sample_size, nrow(matrix))

  fits <- lapply(seeds, function(seed) {
    tryCatch(
      {
        set.seed(seed)
        selected <- sort(sample(seq_len(nrow(matrix)), sample_size, replace = FALSE))
        sample_matrix <- matrix[selected, , drop = FALSE]
        fit_clustering_recipe(sample_matrix, recipe, k, seed, window_size,
          advanced = advanced
        )$cluster
      },
      error = function(error) NULL
    )
  })
  fits <- Filter(Negate(is.null), fits)

  if (length(fits) < 2L) {
    return(NA_real_)
  }
  pairs <- utils::combn(seq_along(fits), 2)
  scores <- apply(pairs, 2, function(pair) {
    shared <- intersect(names(fits[[pair[1]]]), names(fits[[pair[2]]]))
    if (length(shared) <= k) {
      return(NA_real_)
    }
    calculate_adjusted_rand(fits[[pair[1]]][shared], fits[[pair[2]]][shared])
  })
  mean(scores, na.rm = TRUE)
}
