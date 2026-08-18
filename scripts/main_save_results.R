main_save_results <- function(analysis, config, output_path, save_plots = TRUE) {
  dir.create(output_path, recursive = TRUE, showWarnings = FALSE)

  save_run_artifacts(
    output_dir = output_path,
    assignments = analysis$assignments,
    metrics = analysis$metrics,
    quality = analysis$quality,
    prototypes = analysis$prototypes,
    config = config,
    cluster_members = analysis$cluster_members,
    cluster_heatmap = analysis$cluster_heatmap
  )

  saveRDS(analysis$typical_week, file.path(output_path, "typical_week.rds"))
  saveRDS(analysis$fit, file.path(output_path, "selected_model.rds"))

  benchmark_path <- file.path(output_path, "benchmark")
  selected_path <- file.path(output_path, "selected_model")
  dir.create(benchmark_path, recursive = TRUE, showWarnings = FALSE)

  utils::write.csv(
    analysis$metrics,
    file.path(benchmark_path, "all_model_metrics.csv"),
    row.names = FALSE
  )
  utils::write.csv(
    analysis$representation_metadata,
    file.path(benchmark_path, "representation_catalog.csv"),
    row.names = FALSE
  )
  if (isTRUE(config$output$save_models)) {
    saveRDS(analysis$benchmark_models, file.path(benchmark_path, "fitted_models.rds"))
  }

  save_run_artifacts(
    output_dir = selected_path,
    assignments = analysis$assignments,
    metrics = analysis$recommended,
    quality = analysis$quality,
    prototypes = analysis$prototypes,
    config = config,
    cluster_members = analysis$cluster_members,
    cluster_heatmap = analysis$cluster_heatmap
  )
  saveRDS(analysis$fit, file.path(selected_path, "model.rds"))

  writeLines(
    c("# Run conclusions", "", paste0("- ", analysis$conclusions)),
    file.path(output_path, "conclusions.md")
  )

  if (save_plots) {
    plot_path <- file.path(output_path, "plots")
    dir.create(plot_path, recursive = TRUE, showWarnings = FALSE)

    save_plot <- function(plot, plot_name) {
      plot_height <- if (plot_name %in% c(
        "prototypes", "cluster_members",
        "cluster_heatmap"
      )) {
        8
      } else {
        5.5
      }

      ggplot2::ggsave(
        filename = file.path(plot_path, paste0(plot_name, ".png")),
        plot = plot,
        width = 9,
        height = plot_height,
        dpi = 160,
        bg = "white"
      )
    }

    invisible(Map(save_plot, analysis$plots, names(analysis$plots)))
  }

  message("Results saved in ", normalizePath(output_path))
  message("  Full benchmark: ", normalizePath(benchmark_path))
  message("  Selected model: ", normalizePath(selected_path))
  invisible(output_path)
}
