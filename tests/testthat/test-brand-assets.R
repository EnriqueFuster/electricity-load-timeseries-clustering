test_that("the application uses optimized brand assets", {
  public_directory <- test_path("..", "..", "app", "www")
  ui_source <- read_app_source("ui")

  assets <- c(
    "electricity-load-clustering-mark.webp",
    "electricity-load-clustering-favicon.ico",
    "electricity-load-clustering-touch-icon.png"
  )
  paths <- file.path(public_directory, assets)

  expect_true(all(file.exists(paths)))
  expect_lt(file.info(paths[1])$size, 50 * 1024)
  expect_lt(file.info(paths[2])$size, 10 * 1024)
  expect_lt(file.info(paths[3])$size, 50 * 1024)
  expect_match(ui_source, '"Electricity Load Clustering"', fixed = TRUE)
  expect_match(
    ui_source,
    '"Benchmarking clustering methods for hourly load profiles"',
    fixed = TRUE
  )
  expect_match(
    ui_source,
    paste0(
      'src = "load-clustering-assets/',
      'electricity-load-clustering-mark.webp"'
    ),
    fixed = TRUE
  )
  expect_match(
    ui_source,
    paste0(
      'href = "load-clustering-assets/',
      'electricity-load-clustering-favicon.ico"'
    ),
    fixed = TRUE
  )
  expect_false(grepl('"EL"', ui_source, fixed = TRUE))
  expect_false(grepl('"APP"', ui_source, fixed = TRUE))
})

test_that("brand assets have a launch-directory-independent resource path", {
  loader <- paste(
    readLines(
      test_path("..", "..", "app", "bootstrap", "load_app.R"),
      warn = FALSE
    ),
    collapse = "\n"
  )

  expect_match(loader, "register_application_resources <- function(root)", fixed = TRUE)
  expect_match(loader, 'prefix <- "load-clustering-assets"', fixed = TRUE)
  expect_match(loader, "shiny::addResourcePath(prefix, directory)", fixed = TRUE)
  expect_match(loader, "register_application_resources(root)", fixed = TRUE)
})
