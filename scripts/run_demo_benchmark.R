#!/usr/bin/env Rscript

source("R/load_project_functions.R")
load_project_functions(".")
config <- read_project_config("config/demo.yml")
data <- read_load_curve_long("data/demo/load_curves.csv", config$input$timezone)
result <- run_clustering_pipeline(data, config)
save_run_artifacts(
  "results/demo", result$assignments, result$metrics,
  result$quality, result$prototypes, config
)
saveRDS(result$typical_week, "results/demo/typical_week.rds")
cat("Recommended:", result$recommended$algorithm, "k =", result$recommended$k, "\n")
