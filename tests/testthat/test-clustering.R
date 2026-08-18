test_that("kmeans returns named assignments and prototypes", {
  x <- rbind(a = c(0, 0), b = c(.1, .1), c = c(5, 5), d = c(5.1, 5.1))
  fit <- fit_kmeans_clustering(x, 2, 1)
  expect_setequal(names(fit$cluster), rownames(x))
  expect_equal(nrow(fit$prototypes), 2)
})

test_that("hierarchical DTW returns an auditable tree", {
  skip_if_not_installed("dtwclust")
  matrix <- rbind(
    a = c(0, 1, 2, 1),
    b = c(0, 1.1, 2, 1),
    c = c(2, 1, 0, 1),
    d = c(2, 0.9, 0, 1)
  )

  fit <- fit_dtw_hierarchical_clustering(matrix, k = 2, window_size = 1)

  expect_s3_class(fit$model, "hclust")
  expect_equal(length(fit$cluster), 4)
  expect_s3_class(build_dendrogram_plot(fit), "ggplot")
})

test_that("series anonymization is optional and deterministic", {
  data <- data.frame(series_id = c("customer-b", "customer-a", "customer-b"), value = 1:3)

  expect_identical(anonymize_series_ids(data, FALSE), data)
  anonymous <- anonymize_series_ids(data, TRUE, "curve")

  expect_equal(anonymous$series_id, c("curve_002", "curve_001", "curve_002"))
  expect_false(any(grepl("customer", anonymous$series_id)))
})
