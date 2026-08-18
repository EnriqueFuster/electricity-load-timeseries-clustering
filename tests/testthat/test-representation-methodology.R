test_that("seasonal daypart features preserve calendar conditioning", {
  timestamp <- seq(as.POSIXct("2024-01-01", tz = "UTC"), by = "hour", length.out = 24 * 8)
  data <- data.frame(
    series_id = rep(c("a", "b"), each = length(timestamp)),
    timestamp = rep(timestamp, 2), value = c(rep(1, length(timestamp)), rep(2, length(timestamp)))
  )

  profile <- build_seasonal_daypart_profile(data, "mean")
  matrix <- feature_table_to_matrix(profile[c("series_id", "feature_index", "value")])

  expect_equal(nrow(matrix), 2)
  expect_true(all(c("winter", "weekday", "weekend") %in% unique(c(
    profile$season,
    profile$day_type
  ))))
  expect_true(ncol(matrix) >= 12)
})

test_that("behavioral features retain interpretable meter attributes", {
  timestamp <- seq(as.POSIXct("2024-01-01", tz = "UTC"), by = "hour", length.out = 24 * 14)
  data <- data.frame(
    series_id = rep(c("flat", "peaky", "shifted"), each = length(timestamp)),
    timestamp = rep(timestamp, 3),
    value = c(rep(1, length(timestamp)), rep(c(rep(.2, 18), rep(2, 6)), 14), rep(c(
      rep(2, 6),
      rep(.2, 18)
    ), 14))
  )

  matrix <- build_behavioral_feature_matrix(data)

  expect_equal(nrow(matrix), 3)
  expect_true(all(is.finite(matrix)))
  expect_true(all(c("night_share", "evening_share", "load_factor") %in% colnames(matrix)))
})

test_that("PAM supports declared Euclidean and Manhattan recipes", {
  matrix <- rbind(a = c(0, 0), b = c(.1, .1), c = c(5, 5), d = c(5.1, 5.1))
  euclidean <- fit_clustering_recipe(matrix, "pam_euclidean", 2, 1, 2)
  manhattan <- fit_clustering_recipe(matrix, "pam_manhattan", 2, 1, 2)

  expect_equal(length(unique(euclidean$cluster)), 2)
  expect_equal(euclidean$algorithm, "pam")
  expect_equal(manhattan$distance, "manhattan")
})
