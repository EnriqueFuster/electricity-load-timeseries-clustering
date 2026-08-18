test_that("the learning centre and contextual help build without a Shiny session", {
  skip_if_not_installed("shiny")
  skip_if_not_installed("bslib")
  skip_if_not_installed("bsicons")
  source(test_path("..", "..", "app", "ui", "help_content.R"), local = TRUE)
  source(test_path("..", "..", "app", "theory", "loader.R"), local = TRUE)

  expected_inputs <- c(
    "data_mode", "upload_format", "files", "timestamp_column", "value_column",
    "series_id_column", "delimiter", "timezone", "anonymize_ids", "id_prefix",
    "complete_year_missing", "max_missing", "min_coverage", "aggregation",
    "normalization", "pca_variance", "pca_max_components", "clr_zero_fraction",
    "experiment_representation", "experiment_algorithm",
    "experiment_distance", "k_mode", "k_range", "fixed_k",
    "repeats", "dtw_window", "seed", "min_cluster_share", "min_stability",
    "min_silhouette", "max_noise_share", "weight_silhouette", "weight_stability",
    "weight_balance", "hdbscan_min_points", "soft_dtw_gamma", "som_iterations",
    "deep_latent_dimensions", "deep_epochs", "run", "model_choice", "series",
    "series_view", "series_ribbon"
  )

  expect_true(all(expected_inputs %in% names(input_help)))
  expect_s3_class(build_theory_center(), "shiny.tag")
  expect_s3_class(help_label("Algorithm", "experiment_algorithm"), "shiny.tag")
  header_markup <- as.character(help_header("Chart", "Explanation"))
  expect_match(header_markup, "input-help-button", fixed = TRUE)
  expect_false(grepl("card-collapse-button", header_markup, fixed = TRUE))
})

test_that("the learning explorer documents every catalogue section in detail", {
  skip_if_not_installed("shiny")
  skip_if_not_installed("bslib")
  skip_if_not_installed("bsicons")
  source(test_path("..", "..", "app", "theory", "loader.R"), local = TRUE)

  catalog <- get_theory_catalog()
  expect_setequal(names(catalog), c(
    "foundations", "representations", "similarity", "algorithms", "validation"
  ))
  expect_length(catalog$foundations, 1L)
  expect_identical(catalog$foundations[[1]]$id, "welcome")
  expect_match(
    as.character(build_start_here_content()),
    "A benchmark is useful only when comparisons are controlled",
    fixed = TRUE
  )
  expect_gte(length(catalog$representations), 10)
  expect_gte(length(catalog$algorithms), 10)
  expect_true(all(vapply(unlist(catalog, recursive = FALSE), function(entry) {
    all(c(
      "id", "title", "family", "lead", "sections", "summary", "mechanics",
      "use_when", "limitations", "compatibility", "interpretation"
    ) %in% names(entry))
  }, logical(1))))
  expect_true(all(vapply(unlist(catalog, recursive = FALSE), function(entry) {
    nzchar(entry$lead) && length(entry$sections) >= 1L
  }, logical(1))))

  entries <- unlist(catalog, recursive = FALSE)
  profiles <- lapply(entries, get_theory_academic_profile)
  expect_true(all(vapply(profiles, function(profile) {
    all(c(
      "equation", "implementation", "assumptions", "study_check",
      "references"
    ) %in% names(profile)) &&
      nchar(profile$equation) > 20 &&
      nchar(profile$implementation) > 20 &&
      length(profile$references) >= 1
  }, logical(1))))
  expect_true(all(vapply(entries, function(entry) {
    inherits(
      render_theory_detail(entry),
      "shiny.tag"
    )
  }, logical(1))))
  implementation_text <- vapply(
    entries,
    function(entry) get_theory_academic_profile(entry)$implementation,
    character(1)
  )
  expect_false(any(grepl(
    "(build_|fit_|calculate_|select_|normalize_|run_|resolve_|summarize_|impute_|regularize_)",
    implementation_text
  )))
  expect_true(all(grepl(paste0(
    "::|No library function|No single official R function|No transformation ",
    "function|No package function"
  ), implementation_text)))

  learning_taxonomy <- get_learning_taxonomy()
  expect_identical(names(learning_taxonomy), c(
    "foundations", "temporal", "aggregation", "normalization", "transformation",
    "algorithms", "distance", "validation"
  ))
  expect_true(all(lengths(learning_taxonomy) > 0))
  expect_setequal(vapply(learning_taxonomy$normalization, `[[`, character(1), "id"), c(
    "zscore",
    "unit_sum", "none"
  ))
  expect_setequal(
    vapply(
      learning_taxonomy$distance,
      `[[`,
      character(1),
      "id"
    ),
    c(
      "euclidean",
      "manhattan",
      "dtw",
      "sbd",
      "soft_dtw",
      "derived"
    )
  )

  expect_true("recommendation" %in% vapply(
    learning_taxonomy$validation, `[[`, character(1), "id"
  ))
  expect_false("daily_dictionary" %in% vapply(
    unlist(learning_taxonomy, recursive = FALSE), `[[`, character(1), "id"
  ))
  theory_source <- read_app_source("theory")
  expect_false(grepl("Decision guide", theory_source, fixed = TRUE))
  expect_match(theory_source, "Validation & interpretation", fixed = TRUE)
  expect_match(theory_source, "theory_glossary_ui()", fixed = TRUE)
  expect_match(
    as.character(build_start_here_content()),
    "A benchmark is useful only when comparisons are controlled",
    fixed = TRUE
  )
})

test_that("theory catalogue choices render as accessible cards rather than radio dots", {
  css <- paste(readLines(test_path("..", "..", "app", "www", "styles.css"), warn = FALSE),
    collapse = "\n"
  )

  expect_match(css, ".theory-option-scroll .radio input", fixed = TRUE)
  expect_match(css, "opacity: 0", fixed = TRUE)
  expect_match(css, "scrollbar-color: #9a8377 #ebe5df", fixed = TRUE)
  expect_match(css, "label:has(input:focus-visible)", fixed = TRUE)
  expect_match(css, "flex: 1 1 auto", fixed = TRUE)
  expect_match(css, "max-height: none", fixed = TRUE)
  expect_match(css, ".theory-reference span { color: #625b60; opacity: 1; }", fixed = TRUE)
})

test_that("Learn presents public teaching content without internal repository references", {
  theory_source <- read_app_source("theory")

  expect_false(grepl("Repository synthesis", theory_source, fixed = TRUE))
  expect_false(grepl("docs/clustering_theory_guide.md", theory_source, fixed = TRUE))
  expect_false(grepl("Statistical assumptions and failure modes", theory_source, fixed = TRUE))
  expect_false(grepl("Study checklist", theory_source, fixed = TRUE))
  expect_match(theory_source, "R implementation and further reading", fixed = TRUE)
  expect_match(theory_source, '"theory-parameters"', fixed = TRUE)
})

test_that("application CSS is embedded independently of the launch directory", {
  ui_source <- read_app_source("ui", collapse = FALSE)
  expect_true(any(grepl("includeCSS", ui_source, fixed = TRUE)))
  stylesheet_reference <- 'file.path(config$root, "app", "www", "styles.css")'
  expect_true(any(grepl(stylesheet_reference, ui_source, fixed = TRUE)))
  expect_false(any(grepl('href = "styles.css"', ui_source, fixed = TRUE)))
})

test_that("the main interface uses full-width top navigation", {
  ui_source <- read_app_source("ui", collapse = FALSE)
  input_source <- read_app_source("ui", collapse = FALSE)
  server_source <- read_app_source("server", collapse = FALSE)

  expect_false(any(grepl("compact-hero", ui_source, fixed = TRUE)))
  expect_false(any(grepl("bslib::layout_sidebar", ui_source, fixed = TRUE)))
  expect_false(any(grepl("bslib::page_sidebar", ui_source, fixed = TRUE)))
  expect_true(any(grepl("bslib::page_navbar", ui_source, fixed = TRUE)))
  expect_true(any(grepl('"Prepare data"', ui_source, fixed = TRUE)))
  expect_true(any(grepl('"Design experiments"', ui_source, fixed = TRUE)))
  expect_true(any(grepl('"Analyse results"', ui_source, fixed = TRUE)))
  expect_true(any(grepl('"Learn methods"', ui_source, fixed = TRUE)))
  expect_true(any(grepl("configuration-page", ui_source, fixed = TRUE)))
  expect_true(any(grepl("summary-metric-grid", ui_source, fixed = TRUE)))
  expect_true(any(grepl("fillable = FALSE", ui_source, fixed = TRUE)))
  expect_true(any(grepl("data-explorer-toolbar", ui_source, fixed = TRUE)))
  expect_true(any(grepl("model-design-surface", input_source, fixed = TRUE)))
  expect_true(any(grepl("session$onFlushed", server_source, fixed = TRUE)))
  expect_true(any(grepl("benchmark_trigger", server_source, fixed = TRUE)))
})

test_that("analytical tabs use unified task-oriented workspaces", {
  ui_source <- read_app_source("ui")
  server_source <- read_app_source("server")

  expect_match(ui_source, 'title = "Data inspection workspace"', fixed = TRUE)
  expect_match(ui_source, '"series_view"', fixed = TRUE)
  expect_match(ui_source, 'selected = "weekly"', fixed = TRUE)
  expect_match(ui_source, '"series_ribbon"', fixed = TRUE)
  expect_match(ui_source, '"Annual heatmap · day × hour"', fixed = TRUE)
  expect_false(grepl('analysis_plot_output("quality_plot"', ui_source, fixed = TRUE))
  expect_false(grepl('analysis_plot_output("raw_plot"', ui_source, fixed = TRUE))
  expect_false(grepl('analysis_plot_output("week_plot"', ui_source, fixed = TRUE))
  expect_match(ui_source, 'class = "benchmark-card-title"', fixed = TRUE)
  expect_match(ui_source, 'shiny::strong("Method comparison")', fixed = TRUE)
  expect_false(grepl("benchmark_scope", ui_source, fixed = TRUE))
  expect_false(grepl("active_experiment_spec", ui_source, fixed = TRUE))
  expect_false(grepl("shiny::small", server_source, fixed = TRUE))
  expect_match(ui_source, 'title = "Selected clustering result"', fixed = TRUE)
  expect_match(ui_source, '"Executive summary"', fixed = TRUE)
  expect_match(ui_source, '"Temporal patterns"', fixed = TRUE)
  expect_false(grepl('class = "workspace-introduction selected-analysis-intro"', ui_source,
    fixed = TRUE
  ))
  expect_match(server_source, 'class = "model-analysis-context"', fixed = TRUE)
  expect_match(server_source, "summarize_profile_distribution", fixed = TRUE)
  expect_match(server_source, "build_series_inspection_plot", fixed = TRUE)
  expect_match(server_source, "build_premium_datatable", fixed = TRUE)
})

test_that("Learn documents the concrete engineered features", {
  theory_source <- read_app_source("theory")

  expect_match(theory_source, "render_representation_feature_details", fixed = TRUE)
  expect_match(theory_source, "4 seasons × 2 day types × 6 blocks = 48 columns", fixed = TRUE)
  expect_match(theory_source, "mean_hourly_kwh", fixed = TRUE)
  expect_match(theory_source, "peak_hour_sin / peak_hour_cos", fixed = TRUE)
  expect_match(theory_source, "non-finite values are replaced with the median", fixed = TRUE)
})

test_that("Learn parameter labels always begin with a capital letter", {
  source(test_path("..", "..", "app", "theory", "loader.R"), local = TRUE)
  entries <- unlist(get_theory_catalog(), recursive = FALSE)
  parameter_text <- vapply(entries, `[[`, character(1), "parameters")

  expect_true(all(grepl("^[A-Z]", parameter_text)))
})

test_that("result charts use Plotly as the fixed interactive renderer", {
  ui_source <- read_app_source("ui")
  server_source <- read_app_source("server")

  expect_match(ui_source, "analysis_plot_output", fixed = TRUE)
  expect_match(ui_source, 'paste0(id, "_container")', fixed = TRUE)
  expect_false(grepl("shiny::conditionalPanel", substr(ui_source, 1, 700), fixed = TRUE))
  expect_match(ui_source, '"visualization_mode"', fixed = TRUE)
  expect_match(ui_source, '"interactive"', fixed = TRUE)
  expect_false(grepl("Chart rendering", ui_source, fixed = TRUE))
  expect_match(server_source, "output$prototype_plot_static", fixed = TRUE)
  expect_match(server_source, "output$cluster_heatmap_plot_static", fixed = TRUE)
  expect_match(server_source, "register_chart_container", fixed = TRUE)
  expect_false(grepl("suspendWhenHidden = FALSE", server_source, fixed = TRUE))
  expect_match(ui_source, "Plotly.Plots.resize", fixed = TRUE)
  expect_match(ui_source, "shiny:value", fixed = TRUE)
})

test_that("Plotly overlay SVG layers remain transparent", {
  css <- paste(readLines(test_path("..", "..", "app", "www", "styles.css"), warn = FALSE),
    collapse = "\n"
  )
  expect_false(grepl(".plotly .main-svg { background: #fff !important; }", css, fixed = TRUE))
  expect_match(css, ".plotly .main-svg { background: transparent; }", fixed = TRUE)
})

test_that("privacy controls are presented as one responsive setting", {
  ui_source <- read_app_source("ui")
  css <- paste(readLines(test_path("..", "..", "app", "www", "styles.css"), warn = FALSE),
    collapse = "\n"
  )

  expect_match(ui_source, 'class = "privacy-settings"', fixed = TRUE)
  expect_match(ui_source, 'class = "privacy-toggle"', fixed = TRUE)
  expect_match(ui_source, 'class = "privacy-prefix"', fixed = TRUE)
  expect_match(css, '.privacy-toggle input[type="checkbox"]:checked', fixed = TRUE)
  expect_match(css, ".privacy-settings { align-items: stretch; flex-direction: column",
    fixed = TRUE
  )
})

test_that("inputs use a guided data and model-design workspace", {
  workspace_source <- read_app_source("ui")
  app_source <- paste(readLines(test_path("..", "..", "app", "app.R"), warn = FALSE),
    collapse = "\n"
  )
  loader_source <- paste(readLines(
    test_path("..", "..", "app", "bootstrap", "load_app.R"),
    warn = FALSE
  ),
  collapse = "\n"
  )
  css <- paste(readLines(test_path("..", "..", "app", "www", "styles.css"), warn = FALSE),
    collapse = "\n"
  )

  expect_match(app_source, "load_application(project_root)", fixed = TRUE)
  expect_match(loader_source, 'file.path("ui", "input_workspace.R")', fixed = TRUE)
  expect_match(workspace_source, "build_data_foundation_panel()", fixed = TRUE)
  expect_match(workspace_source, "build_model_design_workspace", fixed = TRUE)
  expect_match(workspace_source, '"Temporal representation"', fixed = TRUE)
  expect_match(workspace_source, '"Hourly aggregation statistic"', fixed = TRUE)
  expect_match(workspace_source, '"Normalization / comparison objective"', fixed = TRUE)
  expect_match(workspace_source, '"Transformation / reduction"', fixed = TRUE)
  expect_match(workspace_source, '"Clustering algorithm"', fixed = TRUE)
  expect_match(workspace_source, 'class = "recipe-builder"', fixed = TRUE)
  expect_match(workspace_source, 'class = "run-workflow"', fixed = TRUE)
  expect_match(css, ".benchmark-builder-layout", fixed = TRUE)
  expect_match(css, ".advanced-inputs", fixed = TRUE)
})

test_that("primary navigation follows the four-stage user workflow", {
  ui_source <- read_app_source("ui")

  expect_match(ui_source, 'selected = "Data"', fixed = TRUE)
  expect_match(ui_source, 'id = "data_workspace"', fixed = TRUE)
  expect_match(ui_source, 'bslib::nav_panel("Data preparation", controls)', fixed = TRUE)
  expect_match(ui_source,
    'bslib::nav_panel("Profile inspection", build_data_inspection_workspace())',
    fixed = TRUE
  )
  expect_match(ui_source, '"Design experiments"', fixed = TRUE)
  expect_match(ui_source, 'value = "Experiments"', fixed = TRUE)
  expect_match(ui_source, 'id = "results_workspace"', fixed = TRUE)
  expect_match(ui_source, 'class = "results-model-dock"', fixed = TRUE)
  expect_match(ui_source, "bslib::nav_spacer()", fixed = TRUE)
  expect_match(ui_source, "bslib::nav_item(build_results_model_dock())", fixed = TRUE)
  results_position <- regexpr('"Analyse results"', ui_source, fixed = TRUE)[1]
  learn_position <- regexpr('"Learn methods"', ui_source, fixed = TRUE)[1]
  expect_lt(results_position, learn_position)
})

test_that("primary workspaces share one anchored section-header system", {
  ui_source <- read_app_source("ui")
  input_source <- read_app_source("ui")
  theory_source <- read_app_source("theory")
  help_source <- paste(readLines(
    test_path("..", "..", "app", "ui", "help_content.R"),
    warn = FALSE
  ),
  collapse = "\n"
  )
  css <- paste(readLines(test_path("..", "..", "app", "www", "styles.css"), warn = FALSE),
    collapse = "\n"
  )

  expect_match(help_source, "app_section_header <- function", fixed = TRUE)
  expect_identical(
    length(gregexpr("app_section_header(",
      paste(
        ui_source,
        theory_source
      ),
      fixed = TRUE
    )[[1]]),
    4L
  )
  expect_match(css, ".app-section-header", fixed = TRUE)
  expect_match(css, "margin-top: 0 !important", fixed = TRUE)
  expect_false(grepl('class = "analysis-section-heading"', ui_source, fixed = TRUE))
  expect_false(grepl('class = "control-intro"', input_source, fixed = TRUE))
  expect_false(grepl('class = "theory-intro"', theory_source, fixed = TRUE))
  expect_false(grepl('class = "workflow-heading"', input_source, fixed = TRUE))
  expect_match(css, ".theory-center { display: grid; gap: 0; }", fixed = TRUE)
  expect_match(css, ".results-model-dock", fixed = TRUE)
  expect_match(css, "position: relative", fixed = TRUE)
  expect_match(css, "top: calc(100% + 9px)", fixed = TRUE)
  expect_match(css, "> .bslib-nav-spacer { flex: 1 1 auto; }", fixed = TRUE)
  expect_match(css, "> .nav-item:has(.results-model-dock) { margin-left: auto; }", fixed = TRUE)
  expect_match(css, "min-height: 62px", fixed = TRUE)
  expect_match(css, ".theory-center > .card > .card-header", fixed = TRUE)
  expect_false(grepl('class = "results-model-context"', ui_source, fixed = TRUE))
  expect_false(grepl('workflow_heading("01"', input_source, fixed = TRUE))
  expect_false(grepl('workflow_heading("02"', input_source, fixed = TRUE))
})

test_that("the experiment explanation covers every analytical stage", {
  server_source <- read_app_source("server")
  stages <- c(
    "Temporal representation", "Aggregation", "Normalization",
    "Transformation / reduction", "Clustering algorithm", "Distance / similarity"
  )

  expect_true(all(vapply(stages, grepl, logical(1), x = server_source, fixed = TRUE)))
  expect_match(server_source, "fixed_normalization", fixed = TRUE)
  expect_match(server_source, "normalization_explanations", fixed = TRUE)
})

test_that("method parameters and queue actions are contextual", {
  workspace_source <- read_app_source("ui")
  server_source <- read_app_source("server")
  pipeline_source <- paste(
    readLines(
      test_path(
        "..",
        "..",
        "R",
        "run_clustering_pipeline.R"
      ),
      warn = FALSE
    ),
    collapse = "\n"
  )

  expect_match(workspace_source, 'shiny::h5("Transformation parameters")', fixed = TRUE)
  expect_match(workspace_source, 'shiny::h5("Distance parameters")', fixed = TRUE)
  expect_match(workspace_source, 'shiny::h5("Clustering method parameters")', fixed = TRUE)
  expect_lt(
    regexpr("build_advanced_inputs()", workspace_source, fixed = TRUE)[1],
    regexpr('shiny::actionButton("add_experiment"', workspace_source, fixed = TRUE)[1]
  )
  expect_match(workspace_source, 'shiny::actionButton("clear_experiments"', fixed = TRUE)
  expect_false(grepl('shiny::selectInput("experiment_remove"', workspace_source, fixed = TRUE))
  expect_match(server_source, "remove_experiment_item", fixed = TRUE)
  expect_match(server_source, "queue-remove-button", fixed = TRUE)
  expect_match(server_source, 'class = "queue-parameters"', fixed = TRUE)
  expect_false(grepl("shiny::small", server_source, fixed = TRUE))
  expect_match(server_source, "pca_variance =", fixed = TRUE)
  expect_match(server_source, "soft_dtw_gamma =", fixed = TRUE)
  expect_match(pipeline_source, "model_key_suffix", fixed = TRUE)
})

test_that("profile ribbons are configurable and inputs use the full page width", {
  ui_source <- read_app_source("ui")
  server_source <- read_app_source("server")
  css_source <- paste(readLines(test_path("..", "..", "app", "www", "styles.css"), warn = FALSE),
    collapse = "\n"
  )

  expect_match(ui_source, '"profile_band"', fixed = TRUE)
  expect_match(ui_source, "value = c(25, 75)", fixed = TRUE)
  expect_match(server_source, "profile_band_probs", fixed = TRUE)
  expect_match(css_source, ".input-workspace { width: 100%; max-width: none; margin: 0; }",
    fixed = TRUE
  )
})

test_that("the app opens a precomputed benchmark without fitting", {
  server_source <- read_app_source("server")
  artifact <- test_path("..", "..", "results", "demo", "shiny_benchmark.rds")

  expect_true(file.exists(artifact))
  expect_match(server_source, 'benchmark_trigger("precomputed")', fixed = TRUE)
  expect_match(server_source, "readRDS(artifact)", fixed = TRUE)
  expect_match(server_source, "representation_options <- list(", fixed = TRUE)

  benchmark <- readRDS(artifact)$result
  hierarchical <- benchmark$metrics[
    benchmark$metrics$status == "ok" & benchmark$metrics$algorithm == "hierarchical",
    ,
    drop = FALSE
  ]
  expect_equal(sort(as.integer(hierarchical$k)), 2:5)
  expect_true(all(hierarchical$model_key %in% names(benchmark$benchmark_models)))
})
