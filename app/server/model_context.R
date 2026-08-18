output$run_context <- shiny::renderUI({
  run <- benchmark_run()
  shiny::div(
    class = "run-chip",
    bsicons::bs_icon("database"),
    run$source_label,
    shiny::span("·"),
    paste(
      length(unique(run$data$series_id)),
      "series"
    ),
    shiny::span("·"),
    format(
      run$run_time,
      "%H:%M:%S"
    )
  )
})
model_label <- function(model) {
  paste(model$representation,
    paste(model$algorithm,
      model$distance,
      sep = " + "
    ),
    paste0(
      "k=",
      model$k
    ),
    sep = " · "
  )
}
output$active_model <- shiny::renderText(model_label(active_result()$recommended))
output$active_model_dock <- shiny::renderText({
  active <- active_result()$recommended
  recommended <- benchmark_recommendation()
  algorithm <- algorithm_labels[[as.character(active$algorithm)]] %||%
    as.character(active$algorithm)
  suffix <- if (identical(
    as.character(active$model_key),
    as.character(recommended$model_key)
  )) {
    " · Recommended"
  } else {
    ""
  }
  paste0(algorithm, " · k=", active$k, suffix)
})
output$active_model_status <- shiny::renderUI({
  active <- active_result()$recommended
  recommended <- benchmark_recommendation()
  is_best <- identical(as.character(active$model_key), as.character(recommended$model_key))
  shiny::div(
    class = "active-model-summary",
    shiny::strong(model_label(active)),
    shiny::span(
      class = if (is_best) "model-badge recommended" else "model-badge alternative",
      if (is_best) "Recommended by benchmark" else "User-selected alternative"
    ),
    if (!is_best) {
      shiny::span(
        class = "recommendation-copy",
        paste(
          "Benchmark recommendation:",
          model_label(recommended)
        )
      )
    }
  )
})
output$diagnostics_context <- shiny::renderUI({
  shiny::div(
    class = "model-analysis-context",
    shiny::div(class = "model-analysis-context-icon", bsicons::bs_icon("activity")),
    shiny::div(
      class = "model-analysis-context-copy",
      shiny::span(class = "model-analysis-context-kicker", "SELECTED CLUSTERING RESULT"),
      shiny::strong(model_label(active_result()$recommended)),
      shiny::span(paste0(
        "Review its representative load patterns, cluster composition and validation ",
        "results. Change the selected method from the control above."
      ))
    )
  )
})
output$algorithm_diagnostic_header <- shiny::renderUI({
  analysis <- algorithm_analysis()
  shiny::div(
    class = "algorithm-diagnostic-header",
    shiny::span(class = "method-space-badge", "METHOD-SPECIFIC DIAGNOSTICS"),
    shiny::strong(analysis$title),
    shiny::span(analysis$description)
  )
})
output$algorithm_diagnostic_workspace <- shiny::renderUI({
  analysis <- algorithm_analysis()
  plot_count <- length(analysis$plots)
  tab_names <- analysis$tab_names
  if (is.null(tab_names) || length(tab_names) != plot_count) {
    tab_names <- paste("Diagnostic", seq_len(plot_count))
  }
  panels <- lapply(seq_len(plot_count), function(index) {
    bslib::nav_panel(tab_names[index], analysis_plot_output(paste0("algorithm_plot_", index), 720))
  })
  do.call(
    bslib::navset_card_tab,
    c(list(title = "Diagnostics produced by the selected method"), panels)
  )
})
output$compatibility_note <- shiny::renderUI({
  skipped <- benchmark_run()$result$benchmark_skipped
  if (is.null(skipped) || !nrow(skipped)) {
    return(NULL)
  }
  shiny::div(
    class = "compatibility-note", bsicons::bs_icon("shield-check"),
    paste(
      nrow(skipped), "incompatible method combinations were skipped.",
      "DTW, DBA, hierarchical DTW and SBD are restricted to ordered whole-series inputs."
    )
  )
})
output$heatmap_coverage <- shiny::renderUI({
  heatmap <- active_result()$cluster_heatmap
  shiny::span(sprintf(paste0(
    "Observed calendar coverage: %.1f%%. Coloured cells contain data; grey cells ",
    "are hours absent from the input, not zero consumption."
  ), mean(heatmap$observed) * 100))
})
output$recommended_silhouette <- shiny::renderText(sprintf(
  "%.3f",
  active_result()$recommended$silhouette
))
output$recommended_stability <- shiny::renderText(sprintf(
  "%.3f",
  active_result()$recommended$stability
))
output$active_algorithm <- shiny::renderText(
  algorithm_labels[[as.character(active_result()$recommended$algorithm)]]
)
output$active_clusters <- shiny::renderText(as.integer(active_result()$recommended$k))
output$active_smallest_cluster <- shiny::renderText(sprintf(
  "%.1f%%",
  100 * active_result()$recommended$smallest_cluster_share
))
output$active_noise <- shiny::renderText({
  noise_share <- active_result()$recommended$noise_share
  if (is.null(noise_share) || is.na(noise_share)) noise_share <- 0
  sprintf("%.1f%%", 100 * noise_share)
})
output$active_separation <- shiny::renderText(sprintf(
  "%.3f", active_result()$recommended$silhouette
))
output$active_repeatability <- shiny::renderText(sprintf(
  "%.3f", active_result()$recommended$stability
))
output$active_concentration <- shiny::renderText({
  assignments <- active_result()$assignments
  assigned <- assignments$cluster != 0L
  shares <- prop.table(table(assignments$cluster[assigned]))
  if (!length(shares)) return("N/A")
  sprintf("%.1f%%", 100 * max(shares))
})
output$accepted_series <- shiny::renderText(
  sum(active_result()$quality$quality_status != "exclude")
)
output$conclusions <- shiny::renderUI({
  result <- active_result()
  rec <- result$recommended[1, , drop = FALSE]
  assignments <- result$assignments
  assigned <- assignments$cluster != 0L
  shares <- prop.table(table(assignments$cluster[assigned]))
  largest_share <- if (length(shares)) max(shares) else NA_real_
  noise_count <- sum(!assigned)
  review_profile <- assignments[which.max(assignments$atypicality_percentile), , drop = FALSE]
  shiny::div(
    class = "result-interpretation",
    shiny::div(
      class = "interpretation-item",
      shiny::span("ASSIGNMENTS"),
      shiny::strong(sprintf("%d assigned · %d noise", sum(assigned), noise_count)),
      shiny::p(sprintf("The selected result contains %d clusters.", rec$k[[1]]))
    ),
    shiny::div(
      class = "interpretation-item",
      shiny::span("CLUSTER DISTRIBUTION"),
      shiny::strong(sprintf("%.1f%% largest cluster", 100 * largest_share)),
      shiny::p(sprintf("Cluster balance score: %.3f.", rec$cluster_balance[[1]]))
    ),
    shiny::div(
      class = "interpretation-item",
      shiny::span("HIGHEST ATYPICALITY"),
      shiny::strong(as.character(review_profile$series_id[[1]])),
      shiny::p(sprintf("Cluster %s · within-cluster percentile %.2f.",
                       review_profile$cluster[[1]], review_profile$atypicality_percentile[[1]]))
    )
  )
})
