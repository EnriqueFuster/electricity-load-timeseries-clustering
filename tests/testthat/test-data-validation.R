test_that("schema validation rejects malformed input", {
  expect_error(validate_load_curve_schema(data.frame(x = 1)), "Missing canonical")
})

test_that("quality summary detects duplicates and negatives", {
  x <- data.frame(
    series_id = "a", timestamp = as.POSIXct(c("2024-01-01", "2024-01-01"), tz = "UTC"),
    value = c(1, -1), imputed = 0L
  )
  cfg <- list(
    max_missing_pct = 10, warning_missing_pct = 2, min_coverage_days = 0,
    negative_values = "exclude"
  )
  q <- summarize_data_quality(x, cfg)
  expect_equal(q$duplicated_timestamps, 1)
  expect_equal(q$quality_status, "exclude")
})
