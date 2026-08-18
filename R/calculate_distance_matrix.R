#' Calculate method-consistent pairwise distances
#' @param matrix Series-by-time matrix.
#' @param method euclidean, dtw_basic, or sbd.
#' @param window_size DTW window size.
#' @return A dist object.
calculate_distance_matrix <- function(matrix, method = "euclidean", window_size = 12L) {
  if (method %in% c("euclidean", "manhattan")) {
    return(stats::dist(matrix, method = method))
  }
  if (!requireNamespace("dtwclust", quietly = TRUE)) stop("Package 'dtwclust' is required.")
  series <- lapply(seq_len(nrow(matrix)), function(i) as.numeric(matrix[i, ]))
  if (method == "dtw_basic") {
    return(proxy::dist(series, method = "dtw_basic", window.size = as.integer(window_size)))
  }
  if (method == "soft_dtw") {
    return(proxy::dist(series, method = "sdtw", gamma = 0.05))
  }
  proxy::dist(series, method = "sbd")
}
