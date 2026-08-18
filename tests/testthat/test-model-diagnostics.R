test_that("common diagnostics use the exact declared distance", {
  matrix <- rbind(a = c(0, 0), b = c(0, 1), c = c(8, 8), d = c(9, 8))
  fit <- fit_kmeans_clustering(matrix, 2, 10)
  result <- list(
    matrix = matrix, fit = fit,
    config = list(modeling = list(dtw_window_size = 2L))
  )

  diagnostics <- build_common_diagnostic_data(result)

  expect_equal(diagnostics$distance_matrix, as.matrix(stats::dist(matrix)))
  expect_equal(nrow(diagnostics$silhouette), nrow(matrix))
  expect_true(all(is.finite(diagnostics$silhouette$silhouette)))
  expect_equal(nrow(diagnostics$dissimilarity_heatmap), nrow(matrix)^2)
  expect_equal(nrow(diagnostics$peer_distance), nrow(matrix))
  expect_true(all(c(
    "nearest_cluster",
    "nearest_cluster_distance",
    "separation_margin"
  ) %in% names(diagnostics$peer_distance)))
  expect_true(all(diagnostics$peer_distance$separation_margin > 0))
})

test_that("noise is excluded from silhouette but retained for inspection", {
  matrix <- rbind(a = c(0, 0), b = c(0, 1), c = c(8, 8), d = c(9, 8), noise = c(20, 20))
  clusters <- c(a = 1L, b = 1L, c = 2L, d = 2L, noise = 0L)
  fit <- list(cluster = clusters, distance = "euclidean", distance_matrix = stats::dist(matrix))
  diagnostics <- build_common_diagnostic_data(list(
    matrix = matrix, fit = fit,
    config = list(modeling = list(dtw_window_size = 2L))
  ))

  expect_true(is.na(diagnostics$silhouette$silhouette[diagnostics$silhouette$series_id == "noise"]))
  expect_true("noise" %in% diagnostics$peer_distance$series_id)
  expect_true(any(diagnostics$dissimilarity_heatmap$row_cluster == 0L))
})

test_that("K-means and PAM expose native method diagnostics", {
  matrix <- rbind(a = c(0, 0), b = c(0, 1), c = c(8, 8), d = c(9, 8))
  metric_row <- function(algorithm) data.frame(algorithm = algorithm, stringsAsFactors = FALSE)

  kmeans_result <- list(
    matrix = matrix, fit = fit_kmeans_clustering(matrix, 2, 4),
    recommended = metric_row("kmeans")
  )
  kmeans_plots <- build_algorithm_diagnostic_plots(kmeans_result)
  expect_match(kmeans_plots$title, "K-means")
  expect_equal(kmeans_plots$tab_names, c("Objective decomposition", "Arithmetic centroids"))
  expect_length(kmeans_plots$plots, 2)
  expect_true(all(vapply(kmeans_plots$plots, inherits, logical(1), "ggplot")))

  pam_result <- list(
    matrix = matrix, fit = fit_pam_clustering(matrix, 2, "euclidean"),
    recommended = metric_row("pam")
  )
  pam_plots <- build_algorithm_diagnostic_plots(pam_result)
  expect_match(pam_plots$title, "PAM")
  expect_equal(pam_plots$tab_names, c("Distance to medoids", "Observed medoids"))
  expect_length(pam_plots$plots, 2)
  expect_true(all(vapply(pam_plots$plots, inherits, logical(1), "ggplot")))
})

test_that("the dendrogram belongs only to the active hierarchical fit", {
  matrix <- rbind(a = c(0, 0), b = c(0, 1), c = c(8, 8), d = c(9, 8))
  fit <- fit_dtw_hierarchical_clustering(matrix, 2,
    window_size = 1L,
    distance_matrix = stats::dist(matrix)
  )
  result <- list(matrix = matrix, fit = fit, recommended = data.frame(algorithm = "hierarchical"))

  diagnostics <- build_algorithm_diagnostic_plots(result)

  expect_match(diagnostics$title, "Hierarchical")
  expect_length(diagnostics$plots, 1)
  expect_s3_class(diagnostics$plots[[1]], "ggplot")
  expect_gte(length(diagnostics$plots[[1]]$layers), 3)
  expect_match(diagnostics$plots[[1]]$labels$caption, "dashed line", fixed = TRUE)
  expect_match(diagnostics$description, "Coloured branches", fixed = TRUE)
})

test_that("Shiny exposes shared and method-specific diagnostic workspaces", {
  ui_source <- read_app_source("ui")
  server_source <- read_app_source("server")

  expect_match(ui_source, '"Algorithm-specific"', fixed = TRUE)
  expect_match(ui_source, '"silhouette_detail_plot"', fixed = TRUE)
  expect_match(ui_source, '"dissimilarity_plot"', fixed = TRUE)
  expect_match(ui_source, 'class = "result-tab-guide"', fixed = TRUE)
  expect_match(ui_source, '"Cohesion & separation"', fixed = TRUE)
  expect_false(grepl('nav_panel(\n        "Dissimilarity"', ui_source, fixed = TRUE))
  expect_match(ui_source, "(b(i) - a(i)) / max(a(i), b(i))", fixed = TRUE)
  expect_match(ui_source, "The diagonal is zero", fixed = TRUE)
  expect_match(ui_source, "Hover a cell to identify both profiles", fixed = TRUE)
  expect_match(ui_source, "more distant than roughly 95%", fixed = TRUE)
  expect_match(ui_source, "col_widths = c(8, 4)", fixed = TRUE)
  expect_match(ui_source, "Share assigned to the largest cluster", fixed = TRUE)
  expect_match(ui_source, "assignment-field-guide", fixed = TRUE)
  expect_match(server_source, "membership_probability = result$fit$membership_probability",
    fixed = TRUE
  )
  expect_match(server_source, "if (is.null(model) || isS4(model) || !is.list(model))",
    fixed = TRUE
  )
  expect_false(grepl("result$fit$model$unit.classif", server_source, fixed = TRUE))
  expect_match(server_source, "build_algorithm_diagnostic_plots(active_result())", fixed = TRUE)
  expect_match(server_source, "analysis$tab_names", fixed = TRUE)
  expect_match(ui_source, 'class = "summary-metric-grid summary-metric-grid-nine"', fixed = TRUE)
  expect_match(server_source, 'class = "result-interpretation"', fixed = TRUE)
  expect_match(server_source, '"HIGHEST ATYPICALITY"', fixed = TRUE)
  expect_false(grepl("DECISION BRIEF", server_source, fixed = TRUE))
  expect_false(grepl("Primary evidence", server_source, fixed = TRUE))
  expect_false(grepl("dendrogram_matches", server_source, fixed = TRUE))
})

test_that("the dendrogram safely ignores non-hierarchical S4 models", {
  skip_if_not_installed("dtwclust")
  matrix <- rbind(a = c(0, 0, 1), b = c(0, 1, 1), c = c(8, 8, 9), d = c(8, 9, 9))
  fit <- suppressWarnings(fit_soft_dtw_clustering(matrix, 2, gamma = 0.05))

  expect_null(build_dendrogram_plot(fit$model))
})

test_that("every precomputed hierarchical result produces its dendrogram", {
  artifact <- readRDS(test_path("..", "..", "results", "demo", "shiny_benchmark.rds"))
  result <- artifact$result
  rows <- result$metrics[
    result$metrics$status == "ok" & result$metrics$algorithm == "hierarchical",
    ,
    drop = FALSE
  ]

  expect_equal(sort(as.integer(rows$k)), 2:5)
  for (key in rows$model_key) {
    selected <- select_pipeline_model(result, key)
    diagnostic <- build_algorithm_diagnostic_plots(selected)
    expect_identical(diagnostic$tab_names, "Dendrogram")
    expect_s3_class(diagnostic$plots[[1]], "ggplot")
    expect_gte(length(diagnostic$plots[[1]]$layers), 3L)
  }
})

test_that("the README hierarchical overview is reproducible", {
  artifact <- readRDS(test_path("..", "..", "results", "demo", "shiny_benchmark.rds"))
  result <- artifact$result
  row <- result$metrics[
    result$metrics$status == "ok" &
      result$metrics$representation == "typical_week" &
      result$metrics$algorithm == "hierarchical" &
      result$metrics$k == 3L,
    ,
    drop = FALSE
  ]

  expect_equal(nrow(row), 1L)
  expect_equal(row$k, 3L)
  figure <- build_hierarchical_overview_figure(
    select_pipeline_model(result, row$model_key[[1]])
  )
  expect_s3_class(figure, "gtable")
  expect_true(file.exists(test_path(
    "..", "..", "docs", "assets", "hierarchical-dtw-overview.png"
  )))

  source_text <- paste(readLines(
    test_path("..", "..", "R", "build_hierarchical_overview_figure.R"),
    warn = FALSE
  ), collapse = "\n")
  expect_match(source_text, "ggplot2::geom_ribbon", fixed = TRUE)
  expect_match(source_text, "build_cluster_profile_view(", fixed = TRUE)
  expect_match(source_text, "ymin = lower, ymax = upper", fixed = TRUE)
  expect_false(grepl("ggplot2::geom_area", source_text, fixed = TRUE))
  expect_match(source_text, "ggplot2::aes(hour_of_week, normalized_value", fixed = TRUE)
  expect_false(grepl("kWh", source_text, fixed = TRUE))
  expect_match(source_text, "ggplot2::facet_grid(cluster ~ ., scales = \"free_y\", switch = \"y\")",
    fixed = TRUE
  )
})

test_that("PCA diagnostic distinguishes the two-axis view from retained variance", {
  plot_source <- paste(
    readLines(
      test_path("..", "..", "R", "build_pipeline_plots.R"),
      warn = FALSE
    ),
    collapse = "\n"
  )

  expect_match(plot_source, "PC1 + PC2 explain %.1f%%", fixed = TRUE)
  expect_match(plot_source, "required to reach at least 95%%", fixed = TRUE)
  expect_match(plot_source, 'x = sprintf("PC1', fixed = TRUE)
  expect_match(plot_source, 'y = sprintf("PC2', fixed = TRUE)
  expect_match(plot_source, '"<br>Column cluster: "', fixed = TRUE)
  expect_match(plot_source, '"<br>Row cluster: "', fixed = TRUE)
})
