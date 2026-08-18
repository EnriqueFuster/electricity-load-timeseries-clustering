#!/usr/bin/env Rscript

source("R/load_project_functions.R")
load_project_functions(".")

config <- read_project_config("config/demo.yml")
data <- read_load_curve_long("data/demo/load_curves.csv", config$input$timezone)
result <- run_clustering_pipeline(data, config)

artifact <- list(
  data = data,
  config = config,
  result = result,
  source_label = "Bundled anonymized GoiEner sample",
  run_time = Sys.time()
)

output <- "results/demo/shiny_benchmark.rds"
dir.create(dirname(output), recursive = TRUE, showWarnings = FALSE)
saveRDS(artifact, output, version = 3)

hierarchical <- result$metrics[
  result$metrics$status == "ok" & result$metrics$algorithm == "hierarchical",
  ,
  drop = FALSE
]
if (!nrow(hierarchical)) {
  stop("The Shiny benchmark contains no successful hierarchical result.")
}

cat("Shiny benchmark written to", output, "\n")
cat("Successful hierarchical results:", nrow(hierarchical), "\n")
