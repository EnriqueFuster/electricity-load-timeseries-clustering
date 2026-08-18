test_that("learning views share one typographic system", {
  stylesheet <- paste(
    readLines(
      test_path("..", "..", "app", "www", "styles.css"),
      warn = FALSE
    ),
    collapse = "\n"
  )

  expect_match(stylesheet, "--learn-kicker-color: var(--accent);", fixed = TRUE)
  expect_match(stylesheet, "--learn-copy-leading: 1.65;", fixed = TRUE)
  expect_match(
    stylesheet,
    "color: var(--learn-kicker-color);\n  font-size: var(--learn-kicker-size);",
    fixed = TRUE
  )
  expect_match(
    stylesheet,
    "color: var(--learn-copy-color);\n  font-size: var(--learn-copy-size);",
    fixed = TRUE
  )
})
