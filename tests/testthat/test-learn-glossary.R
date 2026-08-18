test_that("Learn exposes a complete master glossary", {
  skip_if_not_installed("shiny")
  skip_if_not_installed("bslib")
  source(test_path("..", "..", "app", "theory", "loader.R"), local = TRUE)

  markup <- as.character(theory_glossary_ui())
  required_terms <- c(
    "AIC", "ARI", "BIC", "catch22", "CLR", "CRAN", "DBA", "DTW", "EM",
    "GMM", "HDBSCAN", "L1", "NCC", "PAM", "PCA", "SBD", "SOM", "UTC"
  )

  expect_s3_class(theory_glossary_ui(), "shiny.tag")
  expect_true(all(vapply(required_terms, grepl, logical(1), x = markup, fixed = TRUE)))
  expect_match(markup, "Acronyms and technical shorthand", fixed = TRUE)
  expect_match(markup, "Meaning in this app", fixed = TRUE)
  expect_match(markup, "Principal Component Analysis", fixed = TRUE)
  expect_match(markup, "Centred log-ratio", fixed = TRUE)
})

test_that("the normal application loader sources the glossary before the browser", {
  source(test_path("..", "..", "app", "bootstrap", "load_app.R"), local = TRUE)
  learning_modules <- application_modules()$learning_centre

  expect_true(file.path("theory", "glossary.R") %in% learning_modules)
  expect_lt(
    match(file.path("theory", "glossary.R"), learning_modules),
    match(file.path("theory", "browser.R"), learning_modules)
  )
})

test_that("the written theory guide defines its acronyms", {
  guide <- paste(
    readLines(
      test_path("..", "..", "docs", "clustering_theory_guide.md"),
      warn = FALSE,
      encoding = "UTF-8"
    ),
    collapse = "\n"
  )

  expect_match(guide, "## Acronyms and shorthand", fixed = TRUE)
  expect_match(guide, "Dynamic Time Warping (DTW)", fixed = TRUE)
  expect_match(guide, "Principal Component Analysis (PCA)", fixed = TRUE)
  expect_match(guide, "Centred log-ratio", fixed = TRUE)
  expect_match(
    guide,
    "Hierarchical Density-Based Spatial Clustering of Applications with Noise",
    fixed = TRUE
  )
})
