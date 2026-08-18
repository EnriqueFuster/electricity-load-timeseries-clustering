#' Fit HDBSCAN using a declared dissimilarity
#' @param matrix Series-by-feature matrix.
#' @param min_points Minimum neighborhood size.
#' @param distance_name Euclidean or Manhattan.
#' @return Standardized density-clustering result; zero denotes noise.
fit_hdbscan_clustering <- function(matrix, min_points = 5L, distance_name = "euclidean") {
  if (!requireNamespace("dbscan", quietly = TRUE)) stop("Package 'dbscan' is required for HDBSCAN.")
  distance <- stats::dist(matrix, method = distance_name)
  model <- dbscan::hdbscan(distance, minPts = as.integer(min_points))
  clusters <- model$cluster
  names(clusters) <- rownames(matrix)
  if (length(setdiff(unique(clusters), 0L)) < 2L) {
    stop(paste0(
      "HDBSCAN found fewer than two non-noise clusters; adjust min_points or the ",
      "representation."
    ))
  }
  list(
    cluster = clusters,
    prototypes = calculate_cluster_prototypes(matrix, clusters),
    model = model,
    membership_probability = model$membership_prob,
    outlier_score = model$outlier_scores,
    algorithm = "hdbscan",
    distance = distance_name,
    distance_matrix = distance
  )
}
