test_that("explicit experiment parameters survive grid resolution", {
  modeling <- list(experiments = list(
    list(
      representation = "typical_week", recipe = "soft_dtw",
      aggregation = "median", normalization = "zscore",
      soft_dtw_gamma = 0.05, dtw_window = 8L
    ),
    list(
      representation = "typical_week", recipe = "soft_dtw",
      aggregation = "median", normalization = "zscore",
      soft_dtw_gamma = 0.20, dtw_window = 16L
    )
  ))

  grid <- resolve_experiment_grid(modeling)

  expect_equal(nrow(grid), 2L)
  expect_equal(grid$soft_dtw_gamma, c(0.05, 0.20))
  expect_equal(grid$dtw_window, c(8L, 16L))
})

test_that("model key suffixes keep parameterized fits independent", {
  matrix <- rbind(
    a = c(0, 0, 1), b = c(0, .1, 1),
    c = c(1, 1, 0), d = c(1, .9, 0)
  )
  config <- list(
    recipes = "kmeans_euclidean", k_min = 2L, k_max = 2L,
    seed = 1L, repeats = 2L, dtw_window_size = 1L,
    normalization = "zscore", advanced = list()
  )

  first <- benchmark_clustering_models(matrix, config, model_key_suffix = "e1", verbose = FALSE)
  second <- benchmark_clustering_models(matrix, config, model_key_suffix = "e2", verbose = FALSE)

  expect_false(identical(first$metrics$model_key, second$metrics$model_key))
  expect_match(first$metrics$model_key, "__e1$", perl = TRUE)
  expect_match(second$metrics$model_key, "__e2$", perl = TRUE)
})
