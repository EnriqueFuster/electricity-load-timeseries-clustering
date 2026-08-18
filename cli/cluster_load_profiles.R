#!/usr/bin/env Rscript

args <- commandArgs(trailingOnly = TRUE)
help <- any(args %in% c("-h", "--help"))
if (help || !length(args)) {
  cat("electricity-load-timeseries-clustering batch CLI\n\n",
    "Usage:\n",
    "  Rscript cli/cluster_load_profiles.R --input PATH --output PATH [--config PATH] [--long]\n\n",
    "Options:\n",
    "  --input   Folder of one-curve-per-file CSVs, or a CSV with --long\n",
    "  --output  Artifact output folder\n",
    "  --config  YAML config (default: config/default.yml)\n",
    "  --long    Treat --input as one canonical long CSV\n",
    sep = ""
  )
  quit(status = 0)
}

value_after <- function(flag, default = NULL) {
  pos <- match(flag, args)
  if (is.na(pos) || pos == length(args)) default else args[pos + 1L]
}

input <- value_after("--input")
output <- value_after("--output")
config_path <- value_after("--config", "config/default.yml")
if (is.null(input) || is.null(output)) stop("--input and --output are required. Run with --help.")

source("R/load_project_functions.R")
load_project_functions(".")
config <- read_project_config(config_path)
if (identical(config$modeling$k_mode %||% "auto", "manual")) {
  config$modeling$k_min <- as.integer(config$modeling$fixed_k)
  config$modeling$k_max <- as.integer(config$modeling$fixed_k)
}
cat("[1/4] Reading and validating input...\n")
batch <- if ("--long" %in% args) {
  list(
    data = read_load_curve_long(
      input,
      config$input$timezone
    ),
    errors = character()
  )
} else {
  read_load_curve_batch(
    input,
    config$input
  )
}
cat("[2/4] Running preprocessing and clustering benchmark...\n")
result <- run_clustering_pipeline(batch$data, config)
cat("[3/4] Saving artifacts...\n")
save_run_artifacts(
  output, result$assignments, result$metrics, result$quality,
  result$prototypes, config, result$cluster_members, result$cluster_heatmap
)
conclusions <- summarize_pipeline_results(result)
writeLines(c(
  "# electricity-load-timeseries-clustering run", "", paste0("- ", conclusions),
  "", "See CSV and JSON artifacts in this directory."
), file.path(output, "run_summary.md"))
if (length(batch$errors)) writeLines(batch$errors, file.path(output, "read_errors.log"))
cat("[4/4] Conclusions\n", paste("-", conclusions, collapse = "\n"), "\n")
cat("Completed. Artifacts written to", normalizePath(output), "\n")
