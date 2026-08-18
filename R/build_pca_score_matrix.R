#' Reduce a profile matrix with principal component analysis
#' @param matrix Normalized series-by-time matrix.
#' @param explained_variance Target cumulative variance.
#' @param max_components Optional upper limit for the retained components.
#' @return PCA scores with the fitted model stored as an attribute.
build_pca_score_matrix <- function(matrix, explained_variance = 0.95, max_components = NULL) {
  if (!is.numeric(explained_variance) || explained_variance <= 0 || explained_variance > 1) {
    stop("explained_variance must be in (0, 1].")
  }

  fit <- stats::prcomp(matrix, center = TRUE, scale. = FALSE)
  cumulative <- cumsum(fit$sdev^2) / sum(fit$sdev^2)
  components <- which(cumulative >= explained_variance)[1]
  if (!is.null(max_components)) components <- min(components, as.integer(max_components))
  scores <- fit$x[, seq_len(components), drop = FALSE]
  attr(scores, "pca_model") <- fit
  attr(scores, "explained_variance") <- cumulative[components]
  scores
}
