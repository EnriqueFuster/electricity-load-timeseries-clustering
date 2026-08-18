test_that("typical week maps Monday first and returns 168 slots", {
  timestamps <- seq(as.POSIXct("2024-01-01 00:00:00", tz = "UTC"), by = "hour", length.out = 336)
  x <- data.frame(series_id = "a", timestamp = timestamps, value = rep(1:168, 2), imputed = 0L)
  out <- build_typical_week(x, "mean")
  expect_equal(nrow(out), 168)
  expect_equal(out$value, 1:168)
})

test_that("weekday/weekend hourly representation reduces 168 hours to 48", {
  timestamps <- seq(as.POSIXct("2024-01-01 00:00:00", tz = "UTC"), by = "hour", length.out = 336)
  x <- data.frame(series_id = "a", timestamp = timestamps, value = rep(1:168, 2), imputed = 0L)

  profile <- build_day_type_hour_profile(x, "mean")
  matrix <- representation_to_matrix(profile[c("series_id", "feature_index", "value")])

  expect_equal(nrow(profile), 48)
  expect_equal(dim(matrix), c(1, 48))
  expect_equal(profile$feature_index, 1:48)
})
