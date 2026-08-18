#' Save machine-readable run artifacts
#' @param output_dir Destination folder.
#' @param assignments Assignment table.
#' @param metrics Metrics table.
#' @param quality Quality table.
#' @param prototypes Prototype table.
#' @param config Resolved configuration.
#' @param cluster_members Optional long table of curves associated with clusters.
#' @param cluster_heatmap Optional calendar-hour cluster summary.
#' @return Invisibly, output directory.
save_run_artifacts <- function(output_dir, assignments, metrics, quality, prototypes, config,
                               cluster_members = NULL, cluster_heatmap = NULL) {
  dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)
  utils::write.csv(assignments, file.path(output_dir, "cluster_assignments.csv"), row.names = FALSE)
  utils::write.csv(metrics, file.path(output_dir, "model_metrics.csv"), row.names = FALSE)
  utils::write.csv(quality, file.path(output_dir, "data_quality.csv"), row.names = FALSE)
  utils::write.csv(prototypes, file.path(output_dir, "cluster_prototypes.csv"), row.names = FALSE)
  utils::write.csv(prototypes, file.path(output_dir, "synthetic_cluster_profiles.csv"),
    row.names = FALSE
  )
  if (!is.null(cluster_members)) {
    utils::write.csv(cluster_members, file.path(output_dir, "cluster_member_curves.csv"),
      row.names = FALSE
    )
  }
  if (!is.null(cluster_heatmap)) {
    utils::write.csv(cluster_heatmap, file.path(output_dir, "cluster_calendar_heatmap.csv"),
      row.names = FALSE
    )
  }
  if (!requireNamespace("jsonlite", quietly = TRUE)) stop("Package 'jsonlite' is required.")
  jsonlite::write_json(config, file.path(output_dir, "run_config.json"),
    pretty = TRUE,
    auto_unbox = TRUE
  )
  invisible(output_dir)
}
