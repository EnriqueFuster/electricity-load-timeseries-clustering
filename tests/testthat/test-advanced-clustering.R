test_that("the advanced recipe catalog keeps method layers explicit", {
  catalog <- get_clustering_recipe_catalog()
  expected <- c("som_euclidean", "gmm_model", "hdbscan_euclidean", "soft_dtw", "deep_autoencoder")

  expect_true(all(expected %in% catalog$recipe))
  expect_true(is_recipe_compatible(
    catalog[catalog$recipe == "soft_dtw", ], "typical_week",
    "whole-series"
  ))
  expect_false(is_recipe_compatible(
    catalog[catalog$recipe == "soft_dtw", ],
    "behavioral_features", "feature-based"
  ))
})

test_that("a complete natural year is detected without treating a short series as annual", {
  annual <- seq(as.POSIXct("2023-01-01", tz = "UTC"), by = "hour", length.out = 8760)
  full <- data.frame(timestamp = annual, value = 1 + sin(seq_along(annual) / 24))
  short <- full[seq_len(24 * 56), ]

  expect_true(find_complete_natural_years(full, 0)$complete)
  expect_false(find_complete_natural_years(short, 0)$complete)

  quality <- summarize_data_quality(
    transform(full, series_id = "annual", imputed = 0L),
    list(
      max_missing_pct = 0, complete_year_max_missing_pct = 0,
      warning_missing_pct = 0, min_coverage_days = 365,
      require_complete_natural_year = TRUE, negative_values = "exclude"
    )
  )
  expect_equal(quality$quality_status, "pass")
})

test_that("SOM and GMM return standardized partitions", {
  skip_if_not_installed("kohonen")
  skip_if_not_installed("mclust")
  set.seed(10)
  matrix <- rbind(matrix(rnorm(60, -2), 6), matrix(rnorm(60, 2), 6))
  rownames(matrix) <- paste0("meter_", seq_len(nrow(matrix)))

  som <- fit_som_clustering(matrix, 2, rlen = 5)
  gmm <- fit_gmm_clustering(matrix, 2)

  expect_equal(length(som$cluster), nrow(matrix))
  expect_equal(length(gmm$cluster), nrow(matrix))
  expect_equal(ncol(gmm$model$z), 2)
})

test_that("Soft-DTW returns a time-series partition", {
  skip_if_not_installed("dtwclust")
  set.seed(12)
  matrix <- rbind(matrix(rnorm(60, -1), 6), matrix(rnorm(60, 1), 6))
  rownames(matrix) <- paste0("meter_", seq_len(nrow(matrix)))
  fit <- suppressWarnings(fit_soft_dtw_clustering(matrix, 2, gamma = 0.05))

  expect_equal(length(fit$cluster), nrow(matrix))
  expect_equal(fit$distance, "soft_dtw")
})
