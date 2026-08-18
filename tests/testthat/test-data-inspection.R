test_that("profile distribution statistics are calculated per evaluated curve", {
  data <- data.frame(
    series_id = rep(c("a", "b"), each = 4),
    timestamp = rep(seq(as.POSIXct("2024-01-01", tz = "UTC"), by = "hour", length.out = 4), 2),
    value = c(1, 2, 3, 4, 10, 20, NA, 40)
  )

  summary <- summarize_profile_distribution(data)
  a <- summary[summary$series_id == "a", ]
  b <- summary[summary$series_id == "b", ]

  expect_equal(
    a[c("minimum", "mean", "median", "maximum")],
    data.frame(minimum = 1, mean = 2.5, median = 2.5, maximum = 4)
  )
  expect_equal(b$minimum, 10)
  expect_equal(b$maximum, 40)
  expect_true(b$q1 <= b$median && b$median <= b$q3)
})

test_that("the unified curve explorer builds all four inspection views", {
  timestamps <- seq(as.POSIXct("2024-01-01", tz = "UTC"), by = "hour", length.out = 14 * 24)
  clean <- data.frame(
    series_id = "meter", timestamp = timestamps,
    value = 2 + sin(seq_along(timestamps) * 2 * pi / 24)
  )
  result <- list(
    clean = clean,
    typical_week = build_typical_week(clean, "median"),
    config = list(preprocessing = list(aggregation = "median"))
  )

  plots <- suppressWarnings(lapply(c("annual", "weekly", "daily", "heatmap"), function(view) {
    build_series_inspection_plot(result, "meter", view, ribbon_probs = c(.1, .9))
  }))

  expect_true(all(vapply(plots, inherits, logical(1), what = "ggplot")))
  expect_match(plots[[1]]$labels$title, "annual", ignore.case = TRUE)
  expect_match(plots[[4]]$labels$title, "heatmap", ignore.case = TRUE)

  built <- lapply(plots[1:3], ggplot2::ggplot_build)
  line_rows <- vapply(built, function(plot) nrow(plot$data[[length(plot$data)]]), integer(1))
  line_groups <- lapply(built, function(plot) unique(plot$data[[length(plot$data)]]$group))
  expect_equal(line_rows, c(length(timestamps), 168L, 24L))
  expect_true(all(vapply(line_groups, length, integer(1)) == 1L))

  widget <- suppressWarnings(plotly::ggplotly(plots[[3]]))
  line_lengths <- vapply(widget$x$data, function(trace) {
    if (grepl("lines", trace$mode %||% "", fixed = TRUE)) length(trace$x) else 0L
  }, integer(1))
  expect_gte(max(line_lengths), 24L)

  weekly_widget <- suppressWarnings(plotly::ggplotly(plots[[2]]))
  fills <- vapply(weekly_widget$x$data, function(trace) trace$fill %||% "", character(1))
  expect_true(any(fills %in% c("toself", "tonexty")))
  expect_match(plots[[2]]$labels$subtitle, "P10-P90", fixed = TRUE)

  jitter_plot <- build_series_inspection_plot(
    result,
    "meter",
    "weekly",
    ribbon_probs = c(.1, .9),
    show_observations = TRUE
  )
  expect_true(any(vapply(
    jitter_plot$layers,
    function(layer) inherits(layer$position, "PositionJitter"),
    logical(1)
  )))
})

test_that("recurring ribbons calculate pointwise quantiles rather than zero fills", {
  data <- data.frame(interval = rep(1:2, each = 4), value = c(1, 2, 3, 4, 10, 20, 30, 40))
  summary <- summarize_recurring_profile(data, "interval", c(.25, .75))

  expect_equal(summary$median, c(2.5, 25))
  expect_equal(summary$lower, c(1.75, 17.5))
  expect_equal(summary$upper, c(3.25, 32.5))
  expect_true(all(summary$lower > 0))
})
