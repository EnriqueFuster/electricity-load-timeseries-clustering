test_that("cluster profile bands align with all hours", {
  matrix <- rbind(a = 1:4, b = 2:5, c = 10:13, d = 11:14)
  bands <- calculate_cluster_profile_bands(matrix, c(a = 1, b = 1, c = 2, d = 2))
  expect_equal(nrow(bands), 8)
  expect_setequal(unique(bands$cluster), c(1, 2))
  expect_true(all(bands$lower <= bands$median & bands$median <= bands$upper))
})

test_that("pipeline conclusions report the selected model", {
  result <- list(
    quality = data.frame(quality_status = c("pass", "exclude")),
    recommended = data.frame(
      algorithm = "kmeans", k = 2, silhouette = 0.4,
      stability = 0.9, cluster_balance = 0.8
    ),
    assignments = data.frame(
      series_id = c("a", "b"), cluster = c(1, 2),
      atypicality_percentile = c(0.2, 1)
    )
  )
  text <- summarize_pipeline_results(result)
  expect_true(any(grepl("kmeans + euclidean on typical_week with k = 2", text, fixed = TRUE)))
  expect_true(any(grepl("1 series accepted", text, fixed = TRUE)))
})

test_that("cluster member curves retain profile and cluster context", {
  week <- data.frame(
    series_id = rep(c("a", "b"), each = 2),
    hour_of_week = rep(1:2, 2),
    value = 1:4
  )
  normalized <- rbind(a = c(-1, 1), b = c(-1, 1))
  assignments <- data.frame(series_id = c("a", "b"), cluster = c(1, 2))

  members <- build_cluster_member_curves(week, normalized, assignments)

  expect_equal(nrow(members), 4)
  expect_named(members, c("series_id", "hour_of_week", "value", "normalized_value", "cluster"))
})

test_that("calendar heatmap preserves hour and cluster context", {
  clean <- data.frame(
    series_id = rep(c("a", "b"), each = 24),
    timestamp = rep(seq(as.POSIXct("2024-01-01", tz = "UTC"), by = "hour", length.out = 24), 2),
    value = c(rep(1, 24), rep(2, 24))
  )
  assignments <- data.frame(series_id = c("a", "b"), cluster = c(1, 2))

  heatmap <- calculate_cluster_calendar_heatmap(clean, assignments)

  expect_equal(nrow(heatmap), 2 * 366 * 24)
  expect_setequal(unique(heatmap$hour_of_day), 0:23)
  expect_equal(sum(heatmap$observed), 48)
  expect_equal(unique(heatmap$relative_intensity[heatmap$observed]), 1)
  expect_true(all(is.na(heatmap$relative_intensity[!heatmap$observed])))
})

test_that("a fitted benchmark candidate can become the active model", {
  matrix <- rbind(a = c(0, 0), b = c(.1, .1), c = c(5, 5), d = c(9, 9))
  fit_2 <- fit_kmeans_clustering(matrix, 2, 1)
  fit_3 <- fit_kmeans_clustering(matrix, 3, 1)
  metrics <- data.frame(
    model_key = c("typical_week__kmeans__k2", "typical_week__kmeans__k3"),
    algorithm = "kmeans",
    representation = "typical_week",
    normalization = "none",
    k = c(2, 3),
    silhouette = c(.3, .4), stability = c(.8, .7), dunn = c(.5, .6),
    cluster_balance = c(1, .5), runtime_seconds = 0, status = "ok", reason = ""
  )
  week <- data.frame(
    series_id = rep(rownames(matrix), each = 2),
    hour_of_week = rep(1:2, 4),
    value = as.vector(t(matrix))
  )
  clean <- data.frame(
    series_id = rep(rownames(matrix), each = 2),
    timestamp = rep(as.POSIXct(c("2024-01-01 00:00", "2024-01-01 01:00"), tz = "UTC"), 4),
    value = as.vector(t(matrix))
  )
  result <- list(
    metrics = metrics,
    recommended = metrics[1, ],
    benchmark_models = list(
      typical_week__kmeans__k2 = fit_2,
      typical_week__kmeans__k3 = fit_3
    ),
    representation_matrices = list(typical_week = matrix),
    weekly_matrix = matrix,
    typical_week = week,
    clean = clean
  )

  selected <- select_pipeline_model(result, "typical_week__kmeans__k3")

  expect_equal(selected$recommended$k, 3)
  expect_equal(length(unique(selected$assignments$cluster)), 3)
  expect_match(selected$recommended$selection_reason, "Selected by the user")
})
