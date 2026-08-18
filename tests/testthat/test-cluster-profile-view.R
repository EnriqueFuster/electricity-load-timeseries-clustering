test_that("profile views expose daily, weekly, and annual hourly horizons", {
  timestamps <- seq(as.POSIXct("2021-01-01", tz = "UTC"),
    as.POSIXct("2021-12-31 23:00:00", tz = "UTC"),
    by = "hour"
  )
  clean <- rbind(
    data.frame(series_id = "meter_a", timestamp = timestamps, value = seq_along(timestamps)),
    data.frame(series_id = "meter_b", timestamp = timestamps, value = rev(seq_along(timestamps)))
  )
  weekly <- matrix(seq_len(336),
    nrow = 2, byrow = TRUE,
    dimnames = list(c("meter_a", "meter_b"), NULL)
  )
  result <- list(
    clean = clean,
    weekly_matrix = weekly,
    assignments = data.frame(series_id = c("meter_a", "meter_b"), cluster = c(1L, 1L)),
    config = list(preprocessing = list(normalization = "zscore"))
  )

  daily <- build_cluster_profile_view(result, "daily")
  weekly_view <- build_cluster_profile_view(result, "weekly")
  annual <- build_cluster_profile_view(result, "annual", c(.1, .9))

  expect_equal(max(daily$members$interval), 24L)
  expect_equal(max(weekly_view$members$interval), 168L)
  expect_equal(max(annual$members$interval), 8760L)
  expect_equal(nrow(daily$summaries), 24L)
  expect_true(all(c("lower", "median", "upper") %in% names(annual$summaries)))
  expect_equal(annual$probs, c(.1, .9))
  expect_true(all(annual$summaries$lower <= annual$summaries$median))
  expect_true(all(annual$summaries$median <= annual$summaries$upper))
  expect_true(annual$ribbon_width$positive_share > 0)
  expect_true(annual$ribbon_width$maximum >= annual$ribbon_width$median)
  expect_equal(weekly_view$ribbon_basis, "source observations")
  expect_equal(annual$ribbon_basis, "member profiles")
})

test_that("recurring cluster ribbons retain variation from source observations", {
  timestamps <- seq(as.POSIXct("2023-01-01", tz = "UTC"),
    as.POSIXct("2023-12-31 23:00:00", tz = "UTC"),
    by = "hour"
  )
  alternating_day <- (seq_along(timestamps) - 1L) %/% 24L %% 2L
  clean <- rbind(
    data.frame(series_id = "a", timestamp = timestamps, value = 1 + 2 * alternating_day),
    data.frame(series_id = "b", timestamp = timestamps, value = 2 + 2 * alternating_day)
  )
  result <- list(
    clean = clean,
    assignments = data.frame(series_id = c("a", "b"), cluster = 1L),
    config = list(preprocessing = list(normalization = "none"))
  )
  observations <- build_cluster_ribbon_observations(result, "daily", "none")
  expect_equal(nrow(observations), nrow(clean))
  expect_gt(diff(stats::quantile(observations$normalized_value, c(.25, .75))), 0)
})

test_that("recurring ribbons align leap years after removing 29 February", {
  timestamps <- seq(as.POSIXct("2020-01-01", tz = "UTC"),
    as.POSIXct("2020-12-31 23:00:00", tz = "UTC"), by = "hour"
  )
  clean <- data.frame(
    series_id = "leap_meter", timestamp = timestamps,
    value = 2 + sin(seq_along(timestamps) / 24)
  )
  result <- list(
    clean = clean,
    assignments = data.frame(series_id = "leap_meter", cluster = 1L),
    config = list(preprocessing = list(normalization = "zscore"))
  )

  observations <- build_cluster_ribbon_observations(result, "weekly", "zscore")

  expect_equal(nrow(observations), 8760L)
  expect_equal(range(observations$interval), c(1L, 168L))
  expect_true(all(is.finite(observations$normalized_value)))
})

test_that("the profile plot defaults to a visible ribbon and can add member curves", {
  view <- list(
    members = data.frame(
      series_id = rep(c("a", "b"), each = 24), interval = rep(1:24, 2),
      normalized_value = rep(seq(0, 1, length.out = 24), 2), cluster = 1L
    ),
    summaries = data.frame(
      cluster = 1L, interval = 1:24, lower = seq(0, .8, length.out = 24),
      median = seq(.1, .9, length.out = 24), upper = seq(.2, 1, length.out = 24)
    ),
    observations = data.frame(
      series_id = rep(c("a", "b"), each = 24),
      interval = rep(1:24, 2),
      normalized_value = rep(seq(0, 1, length.out = 24), 2),
      cluster = 1L
    ),
    axis = list(label = "Hour", breaks = c(1, 12, 24), labels = c("00", "11", "23")),
    horizon = "daily", probs = c(.25, .75)
  )
  plot <- plot_cluster_profile_view(view)
  expect_s3_class(plot, "ggplot")
  expect_equal(length(plot$layers), 2L)

  plot_with_members <- plot_cluster_profile_view(view, show_members = TRUE)
  expect_equal(length(plot_with_members$layers), 3L)

  plot_with_jitter <- plot_cluster_profile_view(
    view,
    show_observations = TRUE
  )
  expect_true(any(vapply(
    plot_with_jitter$layers,
    function(layer) inherits(layer$position, "PositionJitter"),
    logical(1)
  )))

  widget <- plotly::ggplotly(plot)
  fills <- vapply(widget$x$data, function(trace) trace$fill %||% "", character(1))
  expect_true(any(fills %in% c("toself", "tonexty")))
  fill_colors <- vapply(widget$x$data, function(trace) trace$fillcolor %||% "", character(1))
  expect_true(any(grepl("0.34", fill_colors, fixed = TRUE)))
})

test_that("results use one explicit selected-model analysis workspace", {
  ui_source <- read_app_source("ui")

  expect_match(ui_source, '"Selected model analysis"', fixed = TRUE)
  expect_match(ui_source, '"Executive summary"', fixed = TRUE)
  expect_match(ui_source, '"Temporal patterns"', fixed = TRUE)
  expect_match(ui_source, "bslib::navset_tab(", fixed = TRUE)
  expect_match(ui_source, '"Profiles & ribbons"', fixed = TRUE)
  expect_match(ui_source, '"Annual calendar"', fixed = TRUE)
  expect_false(grepl('"Temporal interpretation workspace"', ui_source, fixed = TRUE))
  expect_false(grepl('"Inspect the hourly meaning of the selected clusters"', ui_source,
    fixed = TRUE
  ))
  expect_false(grepl('"profile_layers"', ui_source, fixed = TRUE))
  expect_match(ui_source, '"Synthetic profiles and uncertainty ribbons"', fixed = TRUE)
  expect_false(grepl('"Selected cluster profiles"', ui_source, fixed = TRUE))
  expect_false(grepl('"Diagnostics",', ui_source, fixed = TRUE))
})

test_that("custom ribbon limits change the hourly cluster envelope", {
  values <- matrix(c(0, 1, 2, 3, 4, 5),
    ncol = 2,
    dimnames = list(c("a", "b", "c"), NULL)
  )
  bands <- calculate_cluster_profile_bands(values, c(a = 1, b = 1, c = 1), c(.1, .5, .9))

  expect_equal(bands$lower, apply(values, 2, stats::quantile, probs = .1, names = FALSE))
  expect_equal(bands$upper, apply(values, 2, stats::quantile, probs = .9, names = FALSE))
})

test_that("ribbon-only profile view uses the same Plotly pattern as data inspection", {
  view <- list(
    members = data.frame(
      series_id = rep(c("a", "b"), each = 24), interval = rep(1:24, 2),
      normalized_value = c(seq(0, 1, length.out = 24), seq(.2, 1.2, length.out = 24)), cluster = 1L
    ),
    summaries = data.frame(
      cluster = 1L, interval = 1:24, lower = seq(0, .8, length.out = 24),
      median = seq(.1, .9, length.out = 24), upper = seq(.2, 1, length.out = 24)
    ),
    axis = list(label = "Hour", breaks = c(1, 12, 24), labels = c("00", "11", "23")),
    horizon = "daily", probs = c(.25, .75)
  )

  widget <- plotly::ggplotly(plot_cluster_profile_view(view))
  fills <- vapply(widget$x$data, function(trace) trace$fill %||% "", character(1))
  fill_colors <- vapply(widget$x$data, function(trace) trace$fillcolor %||% "", character(1))
  expect_equal(sum(fills == "toself"), 1L)
  expect_true(any(grepl("0.34", fill_colors, fixed = TRUE)))
})
