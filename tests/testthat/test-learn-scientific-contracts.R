test_that("seasonal catch22 preserves the cyclic winter order", {
  months <- rep(1:12, each = 2)
  blocks <- seasonal_catch22_blocks(months)

  expect_equal(months[blocks$winter], c(12L, 12L, 1L, 1L, 2L, 2L))
  expect_equal(months[blocks$spring], rep(3:5, each = 2))
})

test_that("assignment output names peer dissimilarity accurately", {
  clusters <- c(a = 1L, b = 1L, c = 2L)
  distances <- c(a = 0.2, b = 0.4, c = 0)
  assignments <- create_cluster_assignments(clusters, distances)

  expect_true("mean_within_cluster_dissimilarity" %in% names(assignments))
  expect_false("distance_to_prototype" %in% names(assignments))
})

test_that("Learn exposes implementation-specific scientific contracts", {
  theory_source <- read_app_source("theory")
  server_source <- read_app_source("server")
  model_source <- paste(
    readLines(test_path("..", "..", "R", "fit_gmm_clustering.R"), warn = FALSE),
    collapse = "\n"
  )
  source(test_path("..", "..", "app", "theory", "loader.R"), local = TRUE)
  catalog_text <- paste(
    unlist(get_theory_catalog(), recursive = TRUE, use.names = FALSE),
    collapse = " "
  )

  expect_false(grepl("Decision guide", theory_source, fixed = TRUE))
  expect_match(theory_source, "Recommendation policy", fixed = TRUE)
  expect_match(catalog_text, "not end-to-end pipeline stability", fixed = TRUE)
  expect_match(catalog_text, "fitted feature embedding", fixed = TRUE)
  expect_match(theory_source, "explicitly applies row-wise z-normalization", fixed = TRUE)
  expect_match(server_source, 'model_based = "GMM feature-space geometry"', fixed = TRUE)
  expect_match(
    model_source,
    "modelNames = c(\"EII\", \"VII\", \"EEI\", \"VEI\", \"EVI\", \"VVI\")",
    fixed = TRUE
  )
})
