main_review_results <- function(analysis, show_plots = interactive()) {
  analysis$plots <- build_pipeline_plots(analysis)
  analysis$conclusions <- summarize_pipeline_results(analysis)

  cat("\nDATA QUALITY\n")
  print(table(analysis$quality$quality_status))

  cat("\nMODEL COMPARISON\n")
  successful_models <- analysis$metrics[analysis$metrics$status == "ok", ]
  successful_models <- successful_models[
    order(successful_models$silhouette, decreasing = TRUE),
  ]
  print(successful_models, row.names = FALSE)

  cat("\nSELECTED MODEL\n")
  print(analysis$recommended, row.names = FALSE)

  cat("\nCLUSTER SIZES\n")
  print(table(analysis$assignments$cluster))

  cat("\nCONCLUSIONS\n")
  cat(paste0("- ", analysis$conclusions, collapse = "\n"), "\n")

  if (show_plots) {
    invisible(lapply(analysis$plots, print))
  }

  analysis
}
