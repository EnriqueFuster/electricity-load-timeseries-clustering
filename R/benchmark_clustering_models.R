#' Benchmark compatible clustering recipes over their parameter grids
#' @param matrix Prepared series-by-feature matrix.
#' @param config Modeling configuration.
#' @param representation_name Name recorded in metrics and model keys.
#' @param representation_family Whole-series, feature-based or transformation-based.
#' @param verbose Print model-level progress.
#' @return Metrics, fitted models and skipped combinations.
benchmark_clustering_models <- function(matrix, config, representation_name = "typical_week",
                                        representation_family = "whole-series", verbose = TRUE,
                                        model_key_suffix = NULL) {
  catalog <- get_clustering_recipe_catalog()
  requested <- config$recipes %||% config$algorithms %||% "kmeans_euclidean"
  aliases <- c(kmeans = "kmeans_euclidean")
  requested <- ifelse(requested %in% names(aliases), aliases[requested], requested)
  recipes <- catalog[catalog$recipe %in% requested, , drop = FALSE]
  if (!nrow(recipes)) stop("No supported clustering method was requested.")

  compatible <- vapply(seq_len(nrow(recipes)), function(index) {
    is_recipe_compatible(recipes[index, ], representation_name, representation_family)
  }, logical(1))
  skipped <- recipes[!compatible, , drop = FALSE]
  recipes <- recipes[compatible, , drop = FALSE]

  maximum_k <- min(config$k_max, nrow(matrix) - 1L)
  if (config$k_min > maximum_k) stop("k_min must be smaller than the number of accepted series.")
  candidate_k <- seq.int(config$k_min, maximum_k)
  advanced <- config$advanced %||% list()

  experiments <- do.call(rbind, lapply(seq_len(nrow(recipes)), function(index) {
    recipe <- recipes[index, ]
    values <- if (recipe$uses_k) candidate_k else advanced$hdbscan_min_points %||% 5L
    data.frame(recipe,
      parameter_name = if (recipe$uses_k) "k" else "min_points",
      parameter_value = values, stringsAsFactors = FALSE
    )
  }))
  if (is.null(experiments) || !nrow(experiments)) {
    stop("No compatible experiment remains after validation.")
  }

  models <- list()
  metrics <- vector("list", nrow(experiments))
  cache <- list()
  progress_bar <- if (isTRUE(verbose) && interactive()) {
    utils::txtProgressBar(0,
      nrow(experiments),
      style = 3
    )
  } else {
    NULL
  }
  if (isTRUE(verbose) && !interactive()) {
    message(
      "Model benchmark [", representation_name, "]: ", nrow(experiments),
      " compatible candidate fits"
    )
  }

  for (index in seq_len(nrow(experiments))) {
    specification <- experiments[index, ]
    recipe <- specification$recipe
    parameter <- specification$parameter_value
    if (isTRUE(verbose) && !interactive()) {
      message(
        "  - ", specification$algorithm, " + ", specification$distance,
        ", ", specification$parameter_name, " = ", parameter
      )
    }
    started <- proc.time()[[3]]
    suffix <- if (specification$parameter_name == "k") {
      paste0(
        "k",
        parameter
      )
    } else {
      paste0("minpts", parameter)
    }
    model_key <- paste(c(representation_name, recipe, suffix, model_key_suffix), collapse = "__")

    tryCatch(
      {
        cacheable_distance <- specification$distance %in% c(
          "euclidean", "manhattan", "dtw_basic",
          "sbd"
        )
        distance <- NULL
        if (cacheable_distance) {
          if (is.null(cache[[specification$distance]])) {
            cache[[specification$distance]] <- calculate_distance_matrix(
              matrix, specification$distance, config$dtw_window_size
            )
          }
          distance <- cache[[specification$distance]]
        }
        fit <- fit_clustering_recipe(
          matrix, recipe, parameter, config$seed,
          config$dtw_window_size, distance, advanced
        )
        validation_distance <- fit$distance_matrix %||% distance %||% if (!is.null(fit$embedding)) {
          stats::dist(fit$embedding)
        } else if (specification$algorithm == "gmm") {
          stats::dist(fit$embedding)
        } else if (specification$distance == "soft_dtw") {
          series <- lapply(seq_len(nrow(matrix)), function(row) as.numeric(matrix[row, ]))
          proxy::dist(series, method = "sdtw", gamma = advanced$soft_dtw_gamma %||% 0.05)
        } else {
          calculate_distance_matrix(matrix, "euclidean", config$dtw_window_size)
        }

        non_noise <- fit$cluster != 0L
        evaluation_clusters <- fit$cluster[non_noise]
        evaluation_matrix <- as.matrix(validation_distance)[
          non_noise,
          non_noise,
          drop = FALSE
        ]
        evaluation_distance <- stats::as.dist(evaluation_matrix)
        cluster_sizes <- table(evaluation_clusters)
        actual_k <- length(cluster_sizes)
        if (actual_k < 2L) stop("Fewer than two evaluable clusters were found.")
        stability <- calculate_cluster_stability(matrix, recipe, parameter,
          config$seed + seq_len(config$repeats) - 1L, config$dtw_window_size,
          advanced = advanced
        )

        metrics[[index]] <- data.frame(
          model_key, recipe,
          algorithm = specification$algorithm, distance = specification$distance,
          representation = representation_name, representation_family,
          feature_count = ncol(matrix),
          normalization = config$normalization %||% "unspecified",
          effective_normalization = fit$effective_normalization %||%
            config$normalization %||% "unspecified",
          fit_geometry = fit$fit_geometry %||% specification$distance,
          validation_geometry = fit$validation_geometry %||% specification$distance,
          method_tier = specification$method_tier, parameter_name = specification$parameter_name,
          parameter_value = parameter, k = actual_k,
          silhouette = calculate_silhouette(evaluation_clusters, evaluation_distance),
          stability, dunn = calculate_dunn_index(evaluation_clusters, evaluation_distance),
          cluster_balance = min(cluster_sizes) / max(cluster_sizes),
          smallest_cluster_share = min(cluster_sizes) / nrow(matrix),
          noise_share = mean(!non_noise), runtime_seconds = proc.time()[[3]] - started,
          status = "ok", reason = ""
        )
        models[[model_key]] <- fit
      },
      error = function(error) {
        metrics[[index]] <<- data.frame(
          model_key, recipe,
          algorithm = specification$algorithm, distance = specification$distance,
          representation = representation_name, representation_family,
          feature_count = ncol(matrix),
          normalization = config$normalization %||% "unspecified",
          effective_normalization = if (specification$algorithm == "kshape") {
            "zscore"
          } else {
            config$normalization %||% "unspecified"
          },
          fit_geometry = specification$distance,
          validation_geometry = specification$distance,
          method_tier = specification$method_tier, parameter_name = specification$parameter_name,
          parameter_value = parameter, k = if (specification$uses_k) parameter else NA_integer_,
          silhouette = NA, stability = NA, dunn = NA, cluster_balance = NA,
          smallest_cluster_share = NA, noise_share = NA,
          runtime_seconds = proc.time()[[3]] - started, status = "error",
          reason = conditionMessage(error)
        )
      }
    )
    if (!is.null(progress_bar)) utils::setTxtProgressBar(progress_bar, index)
  }
  if (!is.null(progress_bar)) close(progress_bar)
  list(metrics = do.call(rbind, metrics), models = models, skipped = skipped)
}
