#' Run the end-to-end clustering pipeline
#' @param data Canonical long load curves.
#' @param config Resolved configuration.
#' @param verbose Print the current pipeline phase to the console.
#' @param progress_callback Optional function(stage, total, detail) used by UIs.
#' @return Pipeline artifacts in memory.
run_clustering_pipeline <- function(data, config, verbose = TRUE, progress_callback = NULL) {
  report_progress <- function(stage, detail) {
    if (isTRUE(verbose)) message(sprintf("[%d/8] %s", stage, detail))
    if (is.function(progress_callback)) progress_callback(stage, 8L, detail)
  }

  # 1. PRIVACY -----------------------------------------------------------
  report_progress(1L, "Applying the identifier privacy policy")
  data <- anonymize_series_ids(
    data,
    enabled = config$privacy$anonymize_series_ids %||% FALSE,
    prefix = config$privacy$id_prefix %||% "profile"
  )

  # 2. DATA QUALITY ------------------------------------------------------
  report_progress(2L, "Checking coverage, gaps and invalid observations")
  quality <- summarize_data_quality(data, config$quality)
  accepted <- quality$series_id[quality$quality_status != "exclude"]
  if (length(accepted) < config$modeling$k_min + 1L) stop("Too few accepted series for clustering.")

  # 3. HOURLY REGULARIZATION AND IMPUTATION -----------------------------
  report_progress(3L, sprintf("Regularizing and imputing %d accepted series", length(accepted)))
  accepted_data <- data[data$series_id %in% accepted, ]
  if (isTRUE(config$quality$require_complete_natural_year %||% FALSE)) {
    selected_years <- stats::setNames(quality$selected_year, quality$series_id)
    observation_year <- as.integer(format(accepted_data$timestamp, "%Y", tz = "UTC"))
    accepted_data <- accepted_data[
      observation_year == selected_years[accepted_data$series_id], ,
      drop = FALSE
    ]
  }
  series_groups <- split(accepted_data, accepted_data$series_id)
  clean <- do.call(rbind, lapply(series_groups, function(x) {
    impute_load_curve(regularize_hourly_series(x))
  }))
  clean <- clean[!is.na(clean$value), ]

  # 4. REPRESENTATION AND DIMENSIONALITY --------------------------------
  report_progress(4L, "Building the representations requested by the benchmark")
  typical_week <- build_typical_week(clean, config$preprocessing$aggregation)
  experiment_grid <- resolve_experiment_grid(config$modeling)
  requested_representations <- unique(experiment_grid$representation)
  representations <- build_requested_representations(
    clean, typical_week, requested_representations, config$preprocessing, verbose
  )
  representation_matrices <- representations$matrices
  representation_metadata <- representations$metadata
  representation_matrix <- representations$weekly_raw
  day_type_hour <- if ("day_type_hour" %in% requested_representations) {
    build_day_type_hour_profile(clean, config$preprocessing$aggregation)
  } else {
    NULL
  }
  seasonal_daypart <- if ("seasonal_daypart" %in% requested_representations) {
    build_seasonal_daypart_profile(clean, config$preprocessing$aggregation)
  } else {
    NULL
  }

  # 5. MODEL BENCHMARK ---------------------------------------------------
  report_progress(5L, "Benchmarking every algorithm and candidate k")
  modeling_config <- config$modeling
  modeling_config$normalization <- config$preprocessing$normalization
  benchmark_runs <- unlist(lapply(names(representation_matrices), function(representation_name) {
    metadata <- representation_metadata[
      representation_metadata$representation == representation_name,
    ]
    rows <- experiment_grid[experiment_grid$representation == representation_name, , drop = FALSE]
    lapply(seq_len(nrow(rows)), function(row_index) {
      experiment <- rows[row_index, , drop = FALSE]
      run_config <- modeling_config
      run_config$recipes <- experiment$recipe
      run_config$normalization <- metadata$normalization
      if ("dtw_window" %in% names(experiment) && !is.na(experiment$dtw_window[1])) {
        run_config$dtw_window_size <- experiment$dtw_window[1]
      }
      advanced_names <- c(
        "hdbscan_min_points", "soft_dtw_gamma", "som_iterations",
        "deep_latent_dimensions", "deep_epochs"
      )
      for (name in intersect(advanced_names, names(experiment))) {
        value <- experiment[[name]][1]
        if (!is.na(value)) run_config$advanced[[name]] <- value
      }
      run <- benchmark_clustering_models(
        representation_matrices[[representation_name]], run_config,
        representation_name = representation_name,
        representation_family = metadata$representation_family,
        verbose = verbose,
        model_key_suffix = paste0("e", match(rownames(experiment), rownames(experiment_grid)))
      )
      run$representation_name <- representation_name
      run
    })
  }), recursive = FALSE)
  benchmark_metrics <- do.call(rbind, lapply(benchmark_runs, `[[`, "metrics"))
  metadata_rows <- representation_metadata[
    match(benchmark_metrics$representation, representation_metadata$representation), ,
    drop = FALSE
  ]
  benchmark_metrics$base_representation <- metadata_rows$base_representation
  benchmark_metrics$transformation <- metadata_rows$transformation
  benchmark_metrics$dimensionality_reduction <- metadata_rows$dimensionality_reduction
  benchmark <- list(
    metrics = benchmark_metrics,
    models = do.call(c, unname(lapply(benchmark_runs, `[[`, "models"))),
    skipped = do.call(rbind, lapply(seq_along(benchmark_runs), function(index) {
      skipped <- benchmark_runs[[index]]$skipped
      if (!nrow(skipped)) {
        return(NULL)
      }
      skipped$representation <- benchmark_runs[[index]]$representation_name
      skipped
    }))
  )

  # 6. MODEL SELECTION ---------------------------------------------------
  report_progress(6L, "Ranking valid candidates with transparent criteria")
  recommended <- select_recommended_model(
    benchmark$metrics,
    min_cluster_share = config$modeling$min_cluster_share,
    min_stability = config$modeling$min_stability %||% 0,
    min_silhouette = config$modeling$min_silhouette %||% -1,
    max_noise_share = config$modeling$max_noise_share %||% 0.2,
    weights = unlist(config$modeling$selection_weights %||% list(
      silhouette = .55, stability = .30, balance = .15
    ))
  )
  # 7. CLUSTER INTERPRETATION -------------------------------------------
  report_progress(7L, "Calculating prototypes, distances and atypicality")
  weekly_matrix <- normalize_load_curve(representation_matrix, config$preprocessing$normalization)

  # 8. RESULT ASSEMBLY ---------------------------------------------------
  report_progress(8L, "Assembling auditable pipeline artifacts")
  result <- list(
    quality = quality,
    clean = clean,
    typical_week = typical_week,
    day_type_hour = day_type_hour,
    seasonal_daypart = seasonal_daypart,
    representation_metadata = representation_metadata,
    representation_matrix = representation_matrix,
    representation_matrices = representation_matrices,
    weekly_matrix = weekly_matrix,
    metrics = benchmark$metrics,
    benchmark_models = benchmark$models,
    benchmark_skipped = benchmark$skipped,
    config = config,
    recommended = recommended,
    benchmark_recommendation_key = as.character(recommended$model_key)
  )
  select_pipeline_model(result, recommended$model_key)
}
