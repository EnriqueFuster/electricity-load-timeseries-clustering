benchmark_trigger <- shiny::reactiveVal(NULL)
shiny::observeEvent(input$run,
  {
    current <- benchmark_trigger()
    benchmark_trigger(if (is.numeric(current)) current + 1L else 1L)
  },
  ignoreInit = TRUE
)
session$onFlushed(function() benchmark_trigger("precomputed"), once = TRUE)

benchmark_run <- shiny::eventReactive(benchmark_trigger(), ignoreNULL = TRUE, {
  if (identical(benchmark_trigger(), "precomputed")) {
    artifact <- file.path(config$root, "results", "demo", "shiny_benchmark.rds")
    shiny::validate(shiny::need(
      file.exists(artifact),
      "The precomputed demo benchmark is missing. Run main.R once to rebuild it."
    ))
    return(readRDS(artifact))
  }
  message("Shiny benchmark: starting requested experiment queue")
  shiny::validate(
    shiny::need(nrow(experiments()) > 0, "Add at least one experiment to the benchmark.")
  )

  shiny::withProgress(message = "Running clustering benchmark", value = 0, {
    shiny::incProgress(0.08, detail = "Resolving configuration")
    run_config <- read_project_config(file.path(config$root, "config", "demo.yml"))
    run_config$quality$max_missing_pct <- input$max_missing
    run_config$quality$require_complete_natural_year <- TRUE
    run_config$quality$complete_year_max_missing_pct <- input$complete_year_missing
    run_config$quality$min_coverage_days <- input$min_coverage
    queued <- experiments()
    first_value <- function(column, fallback) {
      values <- column[!is.na(column)]
      if (length(values)) values[[1]] else fallback
    }
    run_config$preprocessing$aggregation <- first_value(
      queued$aggregation[queued$aggregation != "not_applicable"],
      "median"
    )
    run_config$preprocessing$normalization <- first_value(queued$normalization, "zscore")
    run_config$preprocessing$pca_explained_variance <- first_value(queued$pca_variance, 95) / 100
    run_config$preprocessing$pca_max_components <- as.integer(
      first_value(queued$pca_max_components, 30L)
    )
    run_config$preprocessing$clr_zero_replacement_fraction <- first_value(
      queued$clr_zero_fraction,
      0.5
    )
    run_config$modeling$experiments <- lapply(seq_len(nrow(experiments())), function(index) {
      as.list(experiments()[index, ])
    })
    run_config$privacy$anonymize_series_ids <- isTRUE(input$anonymize_ids)
    run_config$privacy$id_prefix <- input$id_prefix
    run_config$modeling$k_mode <- input$k_mode
    run_config$modeling$repeats <- input$repeats
    run_config$modeling$seed <- as.integer(input$seed)
    run_config$modeling$dtw_window_size <- as.integer(first_value(queued$dtw_window, 12L))
    run_config$modeling$min_cluster_share <- input$min_cluster_share / 100
    run_config$modeling$min_stability <- input$min_stability
    run_config$modeling$min_silhouette <- input$min_silhouette
    run_config$modeling$max_noise_share <- first_value(queued$max_noise_share, 20) / 100
    recommendation_weights <- c(
      silhouette = input$weight_silhouette,
      stability = input$weight_stability,
      balance = input$weight_balance
    )
    shiny::validate(shiny::need(
      sum(recommendation_weights) > 0,
      "At least one recommendation weight must be positive."
    ))
    run_config$modeling$selection_weights <- as.list(recommendation_weights)
    run_config$modeling$advanced <- list(
      hdbscan_min_points = as.integer(first_value(queued$hdbscan_min_points, 3L)),
      soft_dtw_gamma = first_value(queued$soft_dtw_gamma, 0.05),
      som_iterations = as.integer(first_value(queued$som_iterations, 100L)),
      deep_latent_dimensions = as.integer(first_value(queued$deep_latent_dimensions, 4L)),
      deep_epochs = as.integer(first_value(queued$deep_epochs, 80L))
    )

    if (identical(input$k_mode, "manual")) {
      run_config$modeling$fixed_k <- input$fixed_k
      run_config$modeling$k_min <- input$fixed_k
      run_config$modeling$k_max <- input$fixed_k
    } else {
      run_config$modeling$k_min <- input$k_range[1]
      run_config$modeling$k_max <- input$k_range[2]
    }

    shiny::incProgress(0.12, detail = "Reading input curves")
    if (identical(input$data_mode, "demo")) {
      data <- read_load_curve_long(file.path(config$root, "data", "demo", "load_curves.csv"), "UTC")
      source_label <- "Bundled anonymized GoiEner sample"
    } else {
      shiny::req(input$files)
      shiny::validate(shiny::need(nrow(input$files) > 0, "Upload at least one CSV file."))
      run_config$input$timestamp_column <- input$timestamp_column
      run_config$input$value_column <- input$value_column
      run_config$input$delimiter <- input$delimiter
      run_config$input$timezone <- input$timezone

      if (identical(input$upload_format, "long")) {
        shiny::validate(shiny::need(nrow(input$files) == 1, "Long format accepts exactly one CSV."))
        uploaded <- utils::read.csv(input$files$datapath[1],
          sep = input$delimiter,
          stringsAsFactors = FALSE,
          check.names = FALSE
        )
        required <- c(input$series_id_column, input$timestamp_column, input$value_column)
        shiny::validate(shiny::need(
          all(required %in% names(uploaded)),
          paste(
            "Missing columns:",
            paste(
              setdiff(
                required,
                names(uploaded)
              ),
              collapse = ", "
            )
          )
        ))
        names(uploaded)[match(required, names(uploaded))] <- c("series_id", "timestamp", "value")
        temporary <- tempfile(fileext = ".csv")
        utils::write.csv(uploaded, temporary, row.names = FALSE)
        data <- read_load_curve_long(temporary, input$timezone)
      } else {
        run_config$input$series_id_column <- NULL
        pieces <- lapply(seq_len(nrow(input$files)), function(i) {
          piece <- read_load_curve_file(input$files$datapath[i], run_config$input)
          piece$series_id <- tools::file_path_sans_ext(input$files$name[i])
          piece
        })
        data <- do.call(rbind, pieces)
      }
      source_label <- paste(nrow(input$files), "uploaded file(s)")
    }

    shiny::validate(
      shiny::need(
        nrow(data) <= config$web_limits$rows,
        "Web row limit exceeded; use main.R or the CLI."
      ),
      shiny::need(
        length(unique(data$series_id)) <= config$web_limits$series,
        "Web series limit exceeded; use main.R or the CLI."
      )
    )

    shiny::incProgress(0.18, detail = "Preprocessing and fitting candidate models")
    result <- run_clustering_pipeline(data, run_config, verbose = FALSE)
    message("Shiny benchmark: pipeline complete")
    shiny::incProgress(0.58, detail = "Preparing the recommended model")

    list(
      data = data,
      config = run_config,
      result = result,
      source_label = source_label,
      run_time = Sys.time()
    )
  })
})

shiny::observeEvent(benchmark_run(), {
  result <- benchmark_run()$result
  successful <- result$metrics[result$metrics$status == "ok", ]
  labels <- paste(successful$representation,
    paste(successful$algorithm,
      successful$distance,
      sep = " + "
    ),
    paste0(
      "k=",
      successful$k
    ),
    sep = "  ·  "
  )
  labels[successful$model_key == result$recommended$model_key] <- paste0(
    "Recommended  ·  ",
    labels[successful$model_key == result$recommended$model_key]
  )
  choices <- stats::setNames(successful$model_key, labels)
  shiny::updateSelectizeInput(session,
    "model_choice",
    choices = choices,
    selected = result$recommended$model_key,
    server = TRUE
  )

  series_ids <- sort(unique(result$clean$series_id))
  shiny::updateSelectInput(session, "series", choices = series_ids, selected = series_ids[1])
})

active_result <- shiny::reactive({
  result <- benchmark_run()$result
  key <- input$model_choice
  if (is.null(key) || !key %in% result$metrics$model_key) key <- result$recommended$model_key
  select_pipeline_model(result, key)
})

benchmark_recommendation <- shiny::reactive({
  result <- benchmark_run()$result
  result$metrics[result$metrics$model_key == result$benchmark_recommendation_key, , drop = FALSE]
})

profile_band_probs <- shiny::reactive({
  (input$profile_band %||% c(25, 75)) / 100
})

active_analysis <- shiny::reactive({
  result <- active_result()
  list(
    result = result,
    plots = build_pipeline_plots(result, profile_band_probs()),
    conclusions = summarize_pipeline_results(result)
  )
})

algorithm_analysis <- shiny::reactive(build_algorithm_diagnostic_plots(active_result()))

benchmark_metrics <- shiny::reactive({
  benchmark_run()$result$metrics
})

shiny::observeEvent(benchmark_metrics(), {
  metrics <- benchmark_metrics()
  update_filter <- function(input_id, values, labels = NULL) {
    values <- sort(unique(as.character(values[!is.na(values)])))
    choices <- if (is.null(labels)) {
      values
    } else {
      display <- ifelse(values %in% names(labels), labels[values], values)
      stats::setNames(values, display)
    }
    current <- shiny::isolate(input[[input_id]])
    shiny::updateSelectizeInput(
      session,
      input_id,
      choices = choices,
      selected = intersect(current %||% character(), values),
      server = FALSE
    )
  }

  update_filter(
    "comparison_representation",
    metrics$representation,
    representation_labels
  )
  update_filter(
    "comparison_algorithm",
    metrics$algorithm,
    algorithm_labels
  )
  update_filter(
    "comparison_distance",
    metrics$distance,
    distance_labels
  )
  update_filter("comparison_k", metrics$k)
})

comparison_metrics <- shiny::reactive({
  metrics <- benchmark_metrics()
  apply_filter <- function(data, column, selected) {
    if (is.null(selected) || !length(selected)) {
      return(data)
    }
    data[as.character(data[[column]]) %in% as.character(selected), , drop = FALSE]
  }

  metrics <- apply_filter(
    metrics,
    "representation",
    input$comparison_representation
  )
  metrics <- apply_filter(metrics, "algorithm", input$comparison_algorithm)
  metrics <- apply_filter(metrics, "distance", input$comparison_distance)
  metrics <- apply_filter(metrics, "k", input$comparison_k)
  metrics <- apply_filter(metrics, "status", input$comparison_status)

  scope <- input$comparison_scope %||% "all"
  recommended_key <- benchmark_run()$result$benchmark_recommendation_key
  active_key <- active_result()$recommended$model_key
  if (identical(scope, "highlighted")) {
    metrics <- metrics[metrics$model_key %in% c(recommended_key, active_key), , drop = FALSE]
  } else if (identical(scope, "recommended")) {
    metrics <- metrics[metrics$model_key == recommended_key, , drop = FALSE]
  } else if (identical(scope, "active")) {
    metrics <- metrics[metrics$model_key == active_key, , drop = FALSE]
  }

  metrics
})

benchmark_plots <- shiny::reactive({
  result <- active_result()
  result$metrics <- comparison_metrics()
  build_pipeline_plots(result, profile_band_probs())
})
