test_that("the data inspection toolbar cannot force horizontal overflow", {
  stylesheet <- paste(
    readLines(
      test_path("..", "..", "app", "www", "styles.css"),
      warn = FALSE
    ),
    collapse = "\n"
  )

  expect_match(
    stylesheet,
    "grid-template-columns: repeat\\(2, minmax\\(0, 1fr\\)\\);"
  )
  expect_match(
    stylesheet,
    ".data-explorer-toolbar > * {\n  box-sizing: border-box;",
    fixed = TRUE
  )
  expect_match(
    stylesheet,
    ".data-explorer-toolbar .jitter-control label {\n  white-space: normal;",
    fixed = TRUE
  )
  expect_false(grepl(
    "minmax\\(210px, \\.8fr\\).*minmax\\(185px, \\.7fr\\)",
    stylesheet
  ))
})
