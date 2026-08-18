#' Fit a Self-Organising Map followed by clustering of map prototypes
#' @param matrix Series-by-feature matrix.
#' @param k Final number of clusters.
#' @param seed Random seed.
#' @param rlen SOM training iterations.
#' @return Standardized clustering result.
fit_som_clustering <- function(matrix, k, seed = 4107L, rlen = 100L) {
  if (!requireNamespace("kohonen", quietly = TRUE)) stop("Package 'kohonen' is required for SOM.")
  set.seed(seed)
  units <- min(nrow(matrix), max(k, min(25L, ceiling(5 * sqrt(nrow(matrix))))))
  xdim <- max(1L, floor(sqrt(units)))
  ydim <- max(1L, floor(units / xdim))
  grid <- kohonen::somgrid(xdim = xdim, ydim = ydim, topo = "hexagonal")
  model <- kohonen::som(matrix, grid = grid, rlen = as.integer(rlen), keep.data = TRUE)
  codes <- model$codes[[1]]
  code_groups <- stats::kmeans(codes, centers = k, nstart = 25)$cluster
  clusters <- code_groups[model$unit.classif]
  names(clusters) <- rownames(matrix)
  list(
    cluster = clusters,
    prototypes = calculate_cluster_prototypes(matrix, clusters),
    model = model,
    code_groups = code_groups,
    algorithm = "som",
    distance = "euclidean"
  )
}
