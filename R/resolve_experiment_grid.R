#' Resolve explicit experiments or legacy representation/recipe cross-products
#' @param modeling Modeling configuration.
#' @return Data frame with representation and recipe columns.
resolve_experiment_grid <- function(modeling) {
  if (length(modeling$experiments)) {
    grid <- do.call(rbind, lapply(modeling$experiments, function(experiment) {
      values <- as.data.frame(experiment, stringsAsFactors = FALSE)
      values[c("representation", "recipe", setdiff(names(values), c("representation", "recipe")))]
    }))
  } else {
    grid <- expand.grid(
      representation = modeling$representations %||% "typical_week",
      recipe = modeling$recipes %||% modeling$algorithms %||% "kmeans_euclidean",
      stringsAsFactors = FALSE
    )
  }
  unique(grid)
}
