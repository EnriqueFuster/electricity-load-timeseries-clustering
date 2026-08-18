test_that("upload controls explain both layouts and enforce a common timezone contract", {
  input_source <- read_app_source("ui")
  help_source <- paste(
    readLines(test_path("..", "..", "app", "ui", "help_content.R"), warn = FALSE),
    collapse = "\n"
  )
  css_source <- paste(
    readLines(test_path("..", "..", "app", "www", "styles.css"), warn = FALSE),
    collapse = "\n"
  )

  expect_match(input_source, "upload_format_guide <- function", fixed = TRUE)
  expect_match(input_source, "Canonical long CSV · one file for all curves", fixed = TRUE)
  expect_match(input_source, "One CSV per series · one file for each curve", fixed = TRUE)
  expect_match(input_source, "shiny::code(\"series_id\")", fixed = TRUE)
  expect_match(input_source, "shiny::span(\"meter_001.csv\")", fixed = TRUE)
  expect_match(input_source, "shiny::selectizeInput(", fixed = TRUE)
  expect_match(input_source, "help_label(\"Common timezone\", \"timezone\")", fixed = TRUE)
  expect_match(input_source, "choices = c(\"UTC\", setdiff(OlsonNames(), \"UTC\"))", fixed = TRUE)
  expect_match(input_source, "The current analytical calendar is standardized", fixed = TRUE)
  expect_match(help_source, "All files must share this input timezone.", fixed = TRUE)
  expect_match(css_source, ".upload-format-guide {", fixed = TRUE)
  expect_match(css_source, ".timezone-contract-note {", fixed = TRUE)
})
