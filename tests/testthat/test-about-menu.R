test_that("the navbar exposes an accessible project About menu", {
  ui_source <- read_app_source("ui")
  css_source <- paste(
    readLines(test_path("..", "..", "app", "www", "styles.css"), warn = FALSE),
    collapse = "\n"
  )

  expect_match(ui_source, "build_about_menu <- function", fixed = TRUE)
  expect_match(ui_source, 'class = "about-menu"', fixed = TRUE)
  expect_match(ui_source, 'shiny::span("About")', fixed = TRUE)
  expect_match(ui_source, "This project has been developed by Enrique Fuster.", fixed = TRUE)
  expect_match(ui_source, 'href = "https://github.com/EnriqueFuster"', fixed = TRUE)
  expect_match(ui_source, 'rel = "noopener noreferrer"', fixed = TRUE)
  expect_match(ui_source, "bslib::nav_item(build_about_menu())", fixed = TRUE)
  expect_match(ui_source, "bslib::nav_spacer()", fixed = TRUE)
  expect_match(css_source, ".about-menu-panel {", fixed = TRUE)
  expect_match(css_source, "position: fixed;", fixed = TRUE)
  expect_match(css_source, "right: clamp(1rem, 2.5vw, 2.4rem);", fixed = TRUE)
  expect_match(css_source, "z-index: 1080;", fixed = TRUE)
  expect_match(css_source, "overflow: visible !important;", fixed = TRUE)
  expect_match(css_source, ".about-menu > summary:focus-visible", fixed = TRUE)
})
