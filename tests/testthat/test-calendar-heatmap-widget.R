test_that("calendar heatmaps use one native Plotly trace per cluster", {
  skip_if_not_installed("plotly")
  grid <- expand.grid(cluster = 1:2, day_of_year = 1:366, hour_of_day = 0:23)
  grid$relative_intensity <- 1
  grid$mean_consumption <- 2
  grid$observed <- TRUE

  widget <- build_calendar_heatmap_widget(grid)
  built <- plotly::plotly_build(widget)

  expect_equal(length(built$x$data), 2)
  expect_true(all(vapply(built$x$data, `[[`, character(1), "type") == "heatmap"))
})
