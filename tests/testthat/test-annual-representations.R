test_that("annual alignment removes leap day and preserves calendar coordinates", {
  timestamps <- seq(
    as.POSIXct("2020-01-01", tz = "UTC"),
    as.POSIXct("2020-12-31 23:00:00", tz = "UTC"),
    by = "hour"
  )
  data <- data.frame(series_id = "meter_a", timestamp = timestamps, value = seq_along(timestamps))
  annual <- build_annual_hourly_matrix(data)

  expect_equal(dim(annual), c(1, 8760))
  expect_false(anyNA(annual))
})

test_that("annual compositional transformations have their stated invariants", {
  matrix <- rbind(a = c(0, 1, 3, 4), b = c(2, 2, 2, 2))
  closed <- close_annual_composition(matrix)
  positive <- replace_compositional_zeros(closed, fraction = 0.5)
  clr <- apply_clr_transform(positive)

  expect_equal(rowSums(closed), c(a = 1, b = 1))
  expect_true(all(positive > 0))
  expect_equal(rowSums(positive), c(a = 1, b = 1))
  expect_equal(rowMeans(clr), c(a = 0, b = 0), tolerance = 1e-12)
})

test_that("PCA respects its component cap", {
  set.seed(4)
  matrix <- matrix(stats::rnorm(200), nrow = 10)
  scores <- build_pca_score_matrix(matrix, explained_variance = 0.99, max_components = 3)
  expect_lte(ncol(scores), 3)
})

test_that("catch22 feature families have the expected maximum widths", {
  skip_if_not_installed("Rcatch22")
  set.seed(8)
  annual <- rbind(a = stats::rnorm(8760), b = stats::rnorm(8760, 0.2))
  global <- build_catch22_feature_matrix(annual)
  seasonal <- build_catch22_feature_matrix(annual, seasonal = TRUE)
  catch24 <- build_catch22_feature_matrix(annual, seasonal = TRUE, include_mean_sd = TRUE)

  expect_equal(nrow(global), 2)
  expect_lte(ncol(global), 22)
  expect_lte(ncol(seasonal), 88)
  expect_lte(ncol(catch24), 96)
  expect_true(all(is.finite(catch24)))
})
