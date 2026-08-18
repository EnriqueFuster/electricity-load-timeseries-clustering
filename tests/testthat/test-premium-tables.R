test_that("premium tables use readable labels and bounded decimals", {
  data <- data.frame(
    series_id = c("a", "b"),
    score = c(1 / 3, pi),
    selected = c(TRUE, FALSE),
    stringsAsFactors = FALSE
  )

  table <- build_premium_datatable(
    data,
    labels = c(series_id = "Profile", score = "Model score", selected = "Selected"),
    digits = 3L
  )

  expect_s3_class(table, "datatables")
  expect_named(table$x$data, c("Profile", "Model score", "Selected"))
  expect_equal(table$x$data[["Model score"]], c(.333, 3.142))
  expect_equal(table$x$data[["Selected"]], c("Yes", "No"))
  expect_identical(table$x$options$pageLength, -1L)
  expect_identical(table$x$options$dom, "t<'premium-table-footer'i<'premium-table-controls'lp>>")
  expect_equal(table$x$options$lengthMenu[[1]], c(10L, 25L, 50L, 100L, -1L))
  expect_equal(table$x$options$lengthMenu[[2]], c("10", "25", "50", "100", "All"))
  expect_true(length(table$x$options$rowCallback) > 0 || length(table$x$options$columnDefs) > 0)
})

test_that("model comparison supports combined candidate filters", {
  ui_source <- read_app_source("ui")
  server_source <- read_app_source("server")

  filters <- c(
    "comparison_representation",
    "comparison_algorithm",
    "comparison_distance",
    "comparison_k",
    "comparison_status",
    "comparison_scope"
  )
  expect_true(all(vapply(filters, grepl, logical(1), x = ui_source, fixed = TRUE)))
  expect_true(all(vapply(filters, grepl, logical(1), x = server_source, fixed = TRUE)))
  expect_match(server_source, "comparison_metrics <- shiny::reactive", fixed = TRUE)
  expect_match(server_source, "result$metrics <- comparison_metrics()", fixed = TRUE)
  expect_match(ui_source, "model_metric_guide", fixed = TRUE)

  expect_equal(
    lengths(regmatches(
      ui_source,
      gregexpr('dropdownParent = "body"', ui_source, fixed = TRUE)
    )),
    6L
  )
  expect_equal(
    lengths(regmatches(
      ui_source,
      gregexpr("model-filter-dropdown", ui_source, fixed = TRUE)
    )),
    5L
  )

  css_source <- paste(
    readLines(test_path("..", "..", "app", "www", "styles.css"), warn = FALSE),
    collapse = "\n"
  )
  expect_match(
    css_source,
    ".model-selection-filter-panel[open] { z-index: 25; }",
    fixed = TRUE
  )
  expect_match(css_source, ".model-filter-dropdown {", fixed = TRUE)
  expect_match(css_source, "z-index: 3000 !important;", fixed = TRUE)
  expect_match(css_source, "overflow-y: auto;", fixed = TRUE)
})

test_that("every Shiny table exposes a stable collapsible variable selector", {
  ui_source <- read_app_source("ui")
  server_source <- read_app_source("server")

  selectors <- c("quality_table_columns", "metrics_table_columns", "assignments_table_columns")
  expect_true(all(vapply(selectors, grepl, logical(1), x = ui_source, fixed = TRUE)))
  expect_true(all(vapply(selectors, grepl, logical(1), x = server_source, fixed = TRUE)))
  expect_match(ui_source, "table_variable_selector <- function", fixed = TRUE)
  expect_match(ui_source, "shiny::tags$details", fixed = TRUE)
  expect_match(ui_source, 'class = "table-variable-panel"', fixed = TRUE)
  expect_match(ui_source, 'dropdownParent = "body"', fixed = TRUE)
  expect_match(ui_source, "hideSelected = TRUE", fixed = TRUE)
  expect_match(ui_source, 'dropdownClass = "selectize-dropdown table-variable-dropdown"',
    fixed = TRUE
  )
  expect_match(server_source, "register_column_selector <- function", fixed = TRUE)
  expect_match(server_source, "shiny::observeEvent(data_reactive()", fixed = TRUE)
  expect_match(server_source, "shiny::isolate(input[[input_id]])", fixed = TRUE)
  expect_match(server_source, "is.null(current) || !length(current)", fixed = TRUE)
  expect_match(server_source, "selected = selected, server = FALSE", fixed = TRUE)
  expect_match(server_source, "register_column_visibility <- function", fixed = TRUE)
  expect_match(server_source, "DT::dataTableProxy(output_id, session = session)", fixed = TRUE)
  expect_match(server_source, "DT::showCols(proxy, visible_indices, reset = TRUE)", fixed = TRUE)
  expect_false(grepl("selected_table_data", server_source, fixed = TRUE))

  selector_definition <- sub(".*table_variable_selector <- function", "", ui_source)
  selector_definition <- sub("build_data_inspection_workspace.*", "", selector_definition)
  expect_false(grepl("open =", selector_definition, fixed = TRUE))

  css_source <- paste(readLines(test_path("..", "..", "app", "www", "styles.css"), warn = FALSE),
    collapse = "\n"
  )
  expect_match(css_source, ".table-variable-panel[open] { z-index: 30; }", fixed = TRUE)
  expect_match(css_source, ".table-variable-selector .selectize-dropdown { z-index: 2000; }",
    fixed = TRUE
  )
  expect_match(css_source, ".table-variable-dropdown {", fixed = TRUE)
  expect_match(css_source, paste0(
    ".dataTables_wrapper .dataTables_length label { display: flex; align-items: ",
    "center; gap: .45rem; height: 36px;"
  ), fixed = TRUE)
  expect_match(css_source, paste0(
    ".dataTables_wrapper .dataTables_paginate { display: flex; align-items: ",
    "flex-start; float: none; height: 36px !important;"
  ), fixed = TRUE)
  expect_match(css_source, "height: 36px !important;", fixed = TRUE)
})
