#' Materialize the outputs of one fitted benchmark candidate
#' @param result Complete output from run_clustering_pipeline().
#' @param model_key Candidate key stored in result$metrics.
#' @return Pipeline result with selected-model artifacts replaced.
select_pipeline_model <- function(result, model_key) {
  candidate <- result$metrics[
    result$metrics$model_key == model_key & result$metrics$status == "ok",
    ,
    drop = FALSE
  ]
  if (nrow(candidate) != 1L) {
    stop("The selected benchmark model is not available.")
  }

  is_recommendation <- !is.null(result$recommended) &&
    identical(as.character(result$recommended$model_key), model_key)
  if (is_recommendation) {
    candidate <- result$recommended
  }

  matrix <- result$representation_matrices[[candidate$representation]]
  fit <- result$benchmark_models[[model_key]]
  # Benchmarks serialized by earlier versions may contain the dtwclust S4
  # object directly instead of the standardized fit list used by the app.
  if (isS4(fit)) {
    model <- fit
    clusters <- methods::slot(model, "cluster")
    names(clusters) <- rownames(matrix)
    centroids <- if ("centroids" %in% methods::slotNames(model)) {
      do.call(rbind, lapply(methods::slot(model, "centroids"), as.numeric))
    } else {
      calculate_cluster_prototypes(matrix, clusters)
    }
    distance_name <- as.character(candidate$distance[[1]])
    distance <- calculate_distance_matrix(
      matrix,
      distance_name,
      result$config$modeling$dtw_window_size %||% 12L
    )
    fit <- list(
      cluster = clusters,
      prototypes = centroids,
      model = model,
      distance_matrix = distance,
      algorithm = as.character(candidate$algorithm[[1]]),
      distance = distance_name
    )
  }
  model_prototypes <- calculate_cluster_prototypes(matrix, fit$cluster)
  distances <- calculate_within_cluster_distance(
    matrix, fit$cluster, fit, result$config$modeling$dtw_window_size %||% 12L
  )
  assignments <- create_cluster_assignments(fit$cluster, distances)

  synthetic_matrix <- calculate_cluster_prototypes(result$weekly_matrix, fit$cluster)
  synthetic_profiles <- data.frame(
    cluster = rep(as.integer(rownames(synthetic_matrix)), each = ncol(synthetic_matrix)),
    hour_of_week = rep(seq_len(ncol(synthetic_matrix)), nrow(synthetic_matrix)),
    value = as.vector(t(synthetic_matrix))
  )
  cluster_members <- build_cluster_member_curves(
    result$typical_week, result$weekly_matrix,
    assignments
  )
  cluster_heatmap <- calculate_cluster_calendar_heatmap(result$clean, assignments)

  if (!is_recommendation) {
    candidate$selection_reason <- paste0(
      "Selected by the user from the completed benchmark"
    )
  }

  result$recommended <- candidate
  result$matrix <- matrix
  result$fit <- fit
  result$assignments <- assignments
  result$prototypes <- synthetic_profiles
  result$synthetic_profiles <- synthetic_profiles
  result$cluster_members <- cluster_members
  result$cluster_heatmap <- cluster_heatmap
  result$dendrogram_fit <- if (inherits(fit$model, "hclust")) fit else NULL
  result$common_diagnostics <- build_common_diagnostic_data(result)
  result
}
