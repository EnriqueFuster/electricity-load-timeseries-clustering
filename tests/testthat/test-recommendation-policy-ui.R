test_that("recommendation controls distinguish filtering, ranking and review", {
  ui_source <- read_app_source("ui")
  help_source <- paste(
    readLines(
      test_path("..", "..", "app", "ui", "help_content.R"),
      warn = FALSE
    ),
    collapse = "\n"
  )

  expect_false(grepl("recommendation-flow", ui_source, fixed = TRUE))
  expect_match(ui_source, "pass/fail safeguards, not score weights", fixed = TRUE)
  expect_match(ui_source, "rescaled from 0 to 1", fixed = TRUE)
  expect_match(ui_source, "0.01 × k penalty", fixed = TRUE)
  expect_match(ui_source, "one complete fitted method configuration", fixed = TRUE)
  expect_match(ui_source, "does not change any fitted clusters", fixed = TRUE)
  expect_match(ui_source, "Every successful alternative remains", fixed = TRUE)
  expect_match(ui_source, "temporal inspection and practical judgement", fixed = TRUE)

  expect_match(help_source, "Eligibility filter for every algorithm", fixed = TRUE)
  expect_match(help_source, "Ranking preference used only after", fixed = TRUE)
  expect_match(help_source, "relative comparison index", fixed = TRUE)
  expect_match(help_source, "does not change any clusters already fitted", fixed = TRUE)
})

test_that("cluster search explains candidate generation and validation", {
  ui_source <- read_app_source("ui")

  expect_match(ui_source, 'class = "input-card cluster-search-card"', fixed = TRUE)
  expect_match(ui_source, "CANDIDATE PARTITIONS", fixed = TRUE)
  expect_match(ui_source, "VALIDATION AND REPRODUCIBILITY", fixed = TRUE)
  expect_match(ui_source, "HDBSCAN estimates its own", fixed = TRUE)
  expect_match(ui_source, "not ranking preferences", fixed = TRUE)
})
