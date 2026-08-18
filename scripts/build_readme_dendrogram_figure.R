#!/usr/bin/env Rscript

source("R/load_project_functions.R")
load_project_functions(".")

artifact <- readRDS("results/demo/shiny_benchmark.rds")
result <- artifact$result
candidate <- result$metrics[
    result$metrics$status == "ok" &
    result$metrics$representation == "typical_week" &
    result$metrics$algorithm == "hierarchical" &
    result$metrics$k == 3L,
  ,
  drop = FALSE
]
if (nrow(candidate) != 1L) {
  stop("No unique typical-week hierarchical result is available for k = 3.")
}

fit <- result$benchmark_models[[candidate$model_key[[1]]]]
clusters <- fit$cluster
assignments <- data.frame(
  series_id = names(clusters) %||% rownames(result$weekly_matrix),
  cluster = as.integer(clusters),
  stringsAsFactors = FALSE
)
selected <- result
selected$fit <- fit
selected$assignments <- assignments
selected$cluster_members <- build_cluster_member_curves(
  result$typical_week,
  result$weekly_matrix,
  assignments
)
figure <- build_hierarchical_overview_figure(selected)
output <- "docs/assets/hierarchical-dtw-overview.png"
dir.create(dirname(output), recursive = TRUE, showWarnings = FALSE)

ggplot2::ggsave(
  output,
  plot = figure,
  width = 22,
  height = 9,
  units = "in",
  dpi = 180,
  bg = "white"
)
cat("README figure written to", output, "\n")
cat("Hierarchical cut used: k =", candidate$k[[1L]], "\n")
