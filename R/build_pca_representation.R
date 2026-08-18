#' Fit PCA and retain a target share of variance
#' @param matrix Feature matrix.
#' @param variance_threshold Cumulative explained variance target.
#' @return PCA model, scores and explained variance.
build_pca_representation <- function(matrix, variance_threshold = 0.95) {
  fit <- stats::prcomp(matrix, center = TRUE, scale. = TRUE)
  explained <- fit$sdev^2 / sum(fit$sdev^2)
  n <- which(cumsum(explained) >= variance_threshold)[1]
  list(
    model = fit, scores = fit$x[, seq_len(n), drop = FALSE],
    explained_variance = explained, components = n
  )
}
