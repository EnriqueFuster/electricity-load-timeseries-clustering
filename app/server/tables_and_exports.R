quality_labels <- c(
  series_id = "Profile", quality_status = "Quality status", exclusion_reason = "Exclusion reason",
  start = "Observed from", end = "Observed to", observations = "Observed hours",
  expected_observations = "Expected hours", missing_count = "Missing hours",
  missing_pct = "Missing (%)", imputed_pct = "Imputed (%)",
  duplicated_timestamps = "Duplicate timestamps", negative_values = "Negative values",
  coverage_days = "Coverage (days)", complete_natural_years = "Complete years",
  selected_year = "Selected year", minimum = "Minimum", q1 = "Q1",
  mean = "Mean", median = "Median", q3 = "Q3", maximum = "Maximum"
)
metrics_labels <- c(
  recommended = "Recommended", active = "Active", representation = "Representation",
  algorithm = "Algorithm", distance = "Distance", k = "Clusters (K)",
  silhouette = "Silhouette", stability = "Stability", dunn = "Dunn index",
  cluster_balance = "Cluster balance", smallest_cluster_share = "Smallest cluster share",
  noise_share = "Noise share", runtime_seconds = "Runtime (s)", feature_count = "Features",
  normalization = "Normalization", method_tier = "Method tier", status = "Fit status",
  reason = "Status detail", recipe = "Method configuration", model_key = "Model key",
  representation_family = "Representation family", parameter_name = "Parameter",
  parameter_value = "Parameter value"
)
assignment_labels <- c(
  series_id = "Profile", cluster = "Cluster", is_noise = "Noise profile",
  cluster_size = "Cluster size", cluster_share = "Cluster share",
  silhouette = "Profile silhouette",
  mean_peer_distance = "Mean peer dissimilarity",
  nearest_cluster = "Nearest alternative cluster",
  nearest_cluster_distance = "Alternative-cluster dissimilarity",
  separation_margin = "Separation margin",
  atypicality_percentile = "Within-cluster atypicality percentile",
  membership_probability = "Membership probability",
  outlier_score = "Density outlier score",
  som_unit = "SOM map unit",
  som_quantization_distance = "SOM quantization distance",
  reconstruction_error = "Reconstruction error"
)

quality_table_data <- shiny::reactive({
  run <- benchmark_run()
  distribution_data <- anonymize_series_ids(
    run$data,
    enabled = run$config$privacy$anonymize_series_ids %||% FALSE,
    prefix = run$config$privacy$id_prefix %||% "profile"
  )
  distribution <- summarize_profile_distribution(distribution_data)
  quality <- merge(active_result()$quality, distribution,
    by = "series_id", all.x = TRUE,
    sort = FALSE
  )
  preferred_order <- c(
    "series_id", "quality_status", "exclusion_reason", "start", "end",
    "observations", "expected_observations", "missing_count", "missing_pct",
    "imputed_pct", "duplicated_timestamps", "negative_values", "coverage_days",
    "complete_natural_years", "selected_year", "minimum", "q1", "mean",
    "median", "q3", "maximum"
  )
  quality <- quality[c(intersect(preferred_order, names(quality)), setdiff(
    names(quality),
    preferred_order
  ))]
  quality
})

metrics_table_data <- shiny::reactive({
  metrics <- comparison_metrics()
  metrics$recommended <- metrics$model_key == benchmark_run()$result$benchmark_recommendation_key
  metrics$active <- metrics$model_key == active_result()$recommended$model_key
  preferred_order <- c(
    "recommended", "active", "representation", "algorithm", "distance", "k",
    "silhouette", "stability", "dunn", "cluster_balance", "smallest_cluster_share",
    "noise_share", "runtime_seconds", "feature_count", "normalization", "method_tier",
    "status", "reason", "recipe", "model_key", "representation_family",
    "parameter_name", "parameter_value"
  )
  metrics <- metrics[c(intersect(preferred_order, names(metrics)), setdiff(
    names(metrics),
    preferred_order
  ))]
  metrics
})

assignments_table_data <- shiny::reactive({
  result <- active_result()
  assignments <- result$assignments
  diagnostics <- result$common_diagnostics

  assignments$mean_within_cluster_dissimilarity <- NULL
  assignments$is_noise <- assignments$cluster == 0L

  cluster_sizes <- table(assignments$cluster)
  assignments$cluster_size <- as.integer(cluster_sizes[as.character(assignments$cluster)])
  assignments$cluster_share <- assignments$cluster_size / nrow(assignments)

  silhouette <- diagnostics$silhouette[c("series_id", "silhouette")]
  distances <- diagnostics$peer_distance[c(
    "series_id",
    "mean_peer_distance",
    "nearest_cluster",
    "nearest_cluster_distance",
    "separation_margin"
  )]
  assignments <- merge(assignments, silhouette,
    by = "series_id",
    all.x = TRUE,
    sort = FALSE
  )
  assignments <- merge(assignments, distances,
    by = "series_id",
    all.x = TRUE,
    sort = FALSE
  )

  align_fit_value <- function(values) {
    if (is.null(values)) {
      return(NULL)
    }
    if (!is.null(names(values))) {
      return(as.numeric(values[assignments$series_id]))
    }
    profile_order <- names(result$fit$cluster)
    as.numeric(values[match(assignments$series_id, profile_order)])
  }

  model_component <- function(name) {
    model <- result$fit$model
    if (is.null(model) || isS4(model) || !is.list(model)) return(NULL)
    model[[name]] %||% NULL
  }

  optional_fields <- list(
    membership_probability = result$fit$membership_probability,
    outlier_score = result$fit$outlier_score,
    reconstruction_error = result$fit$reconstruction_error,
    som_unit = model_component("unit.classif"),
    som_quantization_distance = model_component("distances")
  )
  for (field in names(optional_fields)) {
    values <- align_fit_value(optional_fields[[field]])
    if (!is.null(values)) {
      assignments[[field]] <- values
    }
  }

  preferred_order <- c(
    "series_id", "cluster", "is_noise", "cluster_size", "cluster_share",
    "silhouette", "mean_peer_distance", "nearest_cluster",
    "nearest_cluster_distance", "separation_margin", "atypicality_percentile",
    "membership_probability", "outlier_score", "som_unit",
    "som_quantization_distance", "reconstruction_error"
  )
  assignments[c(
    intersect(preferred_order, names(assignments)),
    setdiff(names(assignments), preferred_order)
  )]
})

register_column_selector <- function(input_id, data_reactive, labels) {
  shiny::observeEvent(data_reactive(),
    {
      data <- data_reactive()
      available <- names(data)
      display <- ifelse(available %in% names(labels), labels[available], available)
      current <- shiny::isolate(input[[input_id]])
      selected <- if (is.null(current) || !length(current)) {
        available
      } else {
        intersect(
          current,
          available
        )
      }
      shiny::updateSelectizeInput(session, input_id,
        choices = stats::setNames(available, display), selected = selected, server = FALSE
      )
    },
    ignoreInit = FALSE
  )
}
register_column_visibility <- function(output_id, input_id, data_reactive) {
  proxy <- DT::dataTableProxy(output_id, session = session)
  shiny::observeEvent(list(input[[input_id]], names(data_reactive())),
    {
      available <- names(data_reactive())
      selected <- intersect(input[[input_id]] %||% available, available)
      if (!length(selected)) selected <- available[1]
      visible_indices <- match(selected, available) - 1L
      DT::showCols(proxy, visible_indices, reset = TRUE)
    },
    ignoreInit = FALSE
  )
}

register_column_selector("quality_table_columns", quality_table_data, quality_labels)
register_column_selector("metrics_table_columns", metrics_table_data, metrics_labels)
register_column_selector("assignments_table_columns", assignments_table_data, assignment_labels)
register_column_visibility("quality_table", "quality_table_columns", quality_table_data)
register_column_visibility("metrics_table", "metrics_table_columns", metrics_table_data)
register_column_visibility("assignments_table", "assignments_table_columns", assignments_table_data)

output$quality_table <- DT::renderDT({
  build_premium_datatable(
    quality_table_data(),
    quality_labels,
    page_length = -1L, digits = 3L
  )
})
output$metrics_table <- DT::renderDT({
  build_premium_datatable(
    metrics_table_data(),
    metrics_labels,
    page_length = -1L, digits = 3L
  )
})
output$assignments_table <- DT::renderDT({
  build_premium_datatable(
    assignments_table_data(),
    assignment_labels,
    page_length = -1L, digits = 3L
  )
})

output$download_assignments <- shiny::downloadHandler(
  filename = function() {
    paste0(
      "cluster-assignments-",
      Sys.Date(),
      ".csv"
    )
  },
  content = function(file) {
    utils::write.csv(assignments_table_data(),
      file,
      row.names = FALSE
    )
  }
)
output$download_profiles <- shiny::downloadHandler(
  filename = function() {
    paste0(
      "synthetic-cluster-profiles-", input$profile_horizon, "-",
      Sys.Date(), ".csv"
    )
  },
  content = function(file) {
    utils::write.csv(cluster_profile_view()$summaries, file,
      row.names = FALSE
    )
  }
)
output$download_members <- shiny::downloadHandler(
  filename = function() {
    paste0(
      "cluster-member-curves-", input$profile_horizon, "-", Sys.Date(),
      ".csv"
    )
  },
  content = function(file) utils::write.csv(cluster_profile_view()$members, file, row.names = FALSE)
)
output$download_heatmap <- shiny::downloadHandler(
  filename = function() {
    paste0(
      "cluster-calendar-heatmap-",
      Sys.Date(),
      ".csv"
    )
  },
  content = function(file) {
    utils::write.csv(active_result()$cluster_heatmap,
      file,
      row.names = FALSE
    )
  }
)
