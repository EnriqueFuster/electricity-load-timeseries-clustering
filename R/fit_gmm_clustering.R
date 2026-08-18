#' Fit a Gaussian finite mixture with a fixed component count
#' @param matrix Series-by-feature matrix.
#' @param k Number of mixture components.
#' @param seed Random seed.
#' @return Standardized clustering result with posterior probabilities.
fit_gmm_clustering <- function(matrix, k, seed = 4107L) {
  if (!requireNamespace("mclust", quietly = TRUE)) stop("Package 'mclust' is required for GMM.")
  set.seed(seed)
  embedding <- matrix
  if (ncol(matrix) >= nrow(matrix) - 1L) {
    pca <- stats::prcomp(matrix, center = TRUE, scale. = TRUE)
    dimensions <- max(2L, min(nrow(matrix) - 2L, ncol(pca$x)))
    embedding <- pca$x[, seq_len(dimensions), drop = FALSE]
  }
  model_environment <- new.env(parent = asNamespace("mclust"))
  model_environment$embedding <- embedding
  model_environment$groups <- k
  model <- eval(
    quote(Mclust(
      embedding,
      G = groups,
      modelNames = c("EII", "VII", "EEI", "VEI", "EVI", "VVI"),
      verbose = FALSE
    )),
    envir = model_environment
  )
  clusters <- as.integer(model$classification)
  names(clusters) <- rownames(matrix)
  list(
    cluster = clusters,
    prototypes = calculate_cluster_prototypes(matrix, clusters),
    model = model,
    membership_probability = apply(model$z, 1, max),
    embedding = embedding,
    distance_matrix = stats::dist(embedding),
    algorithm = "gmm",
    distance = "model_based",
    fit_geometry = "Gaussian mixture likelihood with spherical or diagonal covariance",
    validation_geometry = "Euclidean dissimilarity in the fitted GMM feature embedding"
  )
}
