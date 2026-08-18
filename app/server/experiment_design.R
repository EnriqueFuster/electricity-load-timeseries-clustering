shiny::observeEvent(input$temporal_basis,
  {
    choices <- representation_options[[input$temporal_basis %||% "weekly"]]
    selected <- if (input$representation_method %in% choices) {
      input$representation_method
    } else {
      unname(choices[1])
    }
    shiny::updateSelectInput(session, "representation_method",
      choices = choices,
      selected = selected
    )
  },
  ignoreInit = FALSE
)

shiny::observeEvent(input$representation_method,
  {
    shiny::updateSelectInput(session,
      "experiment_representation",
      choices = input$representation_method,
      selected = input$representation_method
    )

    fixed_normalization <- c(
      pca_annual_unit_sum = "unit_sum", pca_annual_clr = "unit_sum",
      pca_annual_zscore = "zscore", catch22_global = "none",
      catch22_seasonal = "none", catch24_seasonal = "none",
      behavioral_features = "none"
    )
    required <- unname(fixed_normalization[input$representation_method])
    if (!is.na(required)) {
      labels <- c(
        zscore = "Load shape · z-score · required by this method",
        unit_sum = "Hourly shares · unit sum · required by this method",
        none = "Scaling defined by the selected representation"
      )
      shiny::updateSelectInput(session,
        "normalization",
        choices = stats::setNames(
          required,
          labels[[required]]
        ),
        selected = required
      )
    } else {
      shiny::updateSelectInput(session,
        "normalization",
        choices = c(
          "Shape · z-score per series" = "zscore",
          "Shape shares · unit sum" = "unit_sum",
          "Magnitude + shape · no normalization" = "none"
        ),
        selected = input$normalization %||% "zscore"
      )
    }
  },
  ignoreInit = FALSE
)

output$optional_dependency_status <- shiny::renderUI({
  if (catch22_available) {
    return(NULL)
  }
  shiny::div(
    class = "dependency-notice", bsicons::bs_icon("info-circle"),
    shiny::div(
      shiny::strong("catch22 is currently unavailable"),
      shiny::span(paste0(
        "The app will run without those experiments. Execute renv::restore() in the ",
        "project, then restart Shiny to enable them."
      ))
    )
  )
})

compatible_catalog <- shiny::reactive({
  representation <- input$experiment_representation %||% "typical_week"
  family <- unname(representation_family[[representation]])
  keep <- vapply(seq_len(nrow(catalog)), function(index) {
    is_recipe_compatible(catalog[index, ], representation, family)
  }, logical(1))
  catalog[keep, , drop = FALSE]
})

shiny::observe({
  available <- compatible_catalog()
  algorithms <- unique(available$algorithm)
  choices <- stats::setNames(algorithms, algorithm_labels[algorithms])
  selected <- if (input$experiment_algorithm %in% algorithms) {
    input$experiment_algorithm
  } else {
    algorithms[1]
  }
  shiny::updateSelectInput(session, "experiment_algorithm", choices = choices, selected = selected)
})

shiny::observe({
  available <- compatible_catalog()
  available <- available[available$algorithm == input$experiment_algorithm, , drop = FALSE]
  choices <- stats::setNames(available$distance, distance_labels[available$distance])
  selected <- if (input$experiment_distance %in% available$distance) {
    input$experiment_distance
  } else {
    available$distance[1]
  }
  shiny::updateSelectInput(session, "experiment_distance", choices = choices, selected = selected)
})

output$experiment_explanation <- shiny::renderUI({
  shiny::req(
    input$temporal_basis,
    input$experiment_representation,
    input$normalization,
    input$experiment_algorithm,
    input$experiment_distance
  )
  aggregation_text <- if (identical(input$temporal_basis, "weekly")) {
    aggregation_explanations[[input$aggregation %||% "median"]]
  } else {
    paste0(
      "Not applied. This temporal representation does not collapse repeated ",
      "observations into a typical 168-hour week."
    )
  }
  shiny::div(
    class = "experiment-explanation",
    shiny::div(
      class = "explanation-heading",
      shiny::strong("How this experiment compares profiles"),
      shiny::span("The selected experiment will execute these stages in order.")
    ),
    shiny::div(
      shiny::span(
        class = "explanation-index",
        "01"
      ),
      shiny::strong("Temporal representation"),
      shiny::span(temporal_explanations[[input$temporal_basis]])
    ),
    shiny::div(
      shiny::span(
        class = "explanation-index",
        "02"
      ),
      shiny::strong("Aggregation"),
      shiny::span(aggregation_text)
    ),
    shiny::div(
      shiny::span(
        class = "explanation-index",
        "03"
      ),
      shiny::strong("Normalization"),
      shiny::span(normalization_explanations[[input$normalization]])
    ),
    shiny::div(
      shiny::span(
        class = "explanation-index",
        "04"
      ),
      shiny::strong("Transformation / reduction"),
      shiny::span(representation_explanations[[input$experiment_representation]])
    ),
    shiny::div(
      shiny::span(
        class = "explanation-index",
        "05"
      ),
      shiny::strong("Clustering algorithm"),
      shiny::span(algorithm_explanations[[input$experiment_algorithm]])
    ),
    shiny::div(
      shiny::span(
        class = "explanation-index",
        "06"
      ),
      shiny::strong("Distance / similarity"),
      shiny::span(distance_explanations[[input$experiment_distance]])
    ),
    shiny::span(
      class = "learn-pointer",
      "Open Learn methods for assumptions, strengths, limitations and metric interpretation."
    )
  )
})

shiny::observeEvent(input$add_experiment, {
  if (!catch22_available && input$experiment_representation %in% catch22_representations) {
    shiny::showNotification(
      "Install project dependencies with renv::restore(), restart the app, and then add catch22.",
      type = "warning", duration = 8
    )
    return()
  }
  available <- compatible_catalog()
  match <- available$algorithm == input$experiment_algorithm &
    available$distance == input$experiment_distance
  shiny::validate(shiny::need(any(match), "That combination is not compatible."))
  addition <- data.frame(
    representation = input$experiment_representation,
    recipe = available$recipe[which(match)[1]],
    aggregation = if (identical(
      input$temporal_basis,
      "weekly"
    )) {
      input$aggregation
    } else {
      "not_applicable"
    },
    normalization = input$normalization,
    pca_variance = if (grepl(
      "^pca_",
      input$experiment_representation
    )) {
      input$pca_variance
    } else {
      NA_real_
    },
    pca_max_components = if (grepl(
      "^pca_",
      input$experiment_representation
    )) {
      as.integer(input$pca_max_components)
    } else {
      NA_integer_
    },
    clr_zero_fraction = if (identical(
      input$experiment_representation,
      "pca_annual_clr"
    )) {
      input$clr_zero_fraction
    } else {
      NA_real_
    },
    dtw_window = if (grepl(
      "dtw",
      input$experiment_distance
    )) {
      as.integer(input$dtw_window)
    } else {
      NA_integer_
    },
    hdbscan_min_points = if (identical(
      input$experiment_algorithm,
      "hdbscan"
    )) {
      as.integer(input$hdbscan_min_points)
    } else {
      NA_integer_
    },
    max_noise_share = if (identical(
      input$experiment_algorithm,
      "hdbscan"
    )) {
      input$max_noise_share
    } else {
      NA_real_
    },
    soft_dtw_gamma = if (identical(
      input$experiment_algorithm,
      "soft_dtw"
    )) {
      input$soft_dtw_gamma
    } else {
      NA_real_
    },
    som_iterations = if (identical(
      input$experiment_algorithm,
      "som"
    )) {
      as.integer(input$som_iterations)
    } else {
      NA_integer_
    },
    deep_latent_dimensions = if (identical(
      input$experiment_algorithm,
      "deep_autoencoder"
    )) {
      as.integer(input$deep_latent_dimensions)
    } else {
      NA_integer_
    },
    deep_epochs = if (identical(
      input$experiment_algorithm,
      "deep_autoencoder"
    )) {
      as.integer(input$deep_epochs)
    } else {
      NA_integer_
    },
    stringsAsFactors = FALSE
  )
  current <- experiments()
  same_representation <- current$representation == addition$representation
  representation_parameters <- c(
    "aggregation", "normalization", "pca_variance",
    "pca_max_components", "clr_zero_fraction"
  )
  conflicts <- same_representation & vapply(seq_len(nrow(current)), function(row) {
    !all(vapply(representation_parameters, function(name) {
      isTRUE(all.equal(current[[name]][row], addition[[name]][1], check.attributes = FALSE))
    }, logical(1)))
  }, logical(1))
  if (any(conflicts)) {
    shiny::showNotification(
      paste0(
        "Experiments sharing a representation must share its aggregation, ",
        "normalization and transformation settings. Remove the conflicting item or ",
        "run it separately."
      ),
      type = "warning", duration = 9
    )
    return()
  }
  experiments(unique(rbind(current, addition)))
})

shiny::observeEvent(input$remove_experiment_item, {
  grid <- experiments()
  remove <- input$remove_experiment_item
  if (!is.null(remove) && nzchar(remove)) experiments(grid[-as.integer(remove), , drop = FALSE])
})

shiny::observeEvent(input$clear_experiments, {
  experiments(initial_experiments[0, , drop = FALSE])
})

shiny::observeEvent(input$reset_experiments, {
  experiments(initial_experiments)
})

output$experiment_queue <- shiny::renderUI({
  grid <- experiments()
  shiny::div(
    class = "experiment-queue",
    shiny::div(
      class = "queue-heading",
      shiny::strong(paste(
        nrow(grid),
        "experiments queued"
      )),
      shiny::span("Only these combinations will run.")
    ),
    lapply(seq_len(nrow(grid)), function(index) {
      recipe <- catalog[catalog$recipe == grid$recipe[index], ]
      parameter_values <- c(
        if (!is.na(grid$pca_variance[index])) {
          paste0(
            "PCA ",
            grid$pca_variance[index],
            "% · max ",
            grid$pca_max_components[index]
          )
        },
        if (!is.na(grid$clr_zero_fraction[index])) {
          paste0(
            "CLR zero fraction ",
            grid$clr_zero_fraction[index]
          )
        },
        if (!is.na(grid$dtw_window[index])) paste0("DTW window ", grid$dtw_window[index], " h"),
        if (!is.na(grid$hdbscan_min_points[index])) {
          paste0(
            "min points ",
            grid$hdbscan_min_points[index],
            " · max noise ",
            grid$max_noise_share[index],
            "%"
          )
        },
        if (!is.na(grid$soft_dtw_gamma[index])) paste0("gamma ", grid$soft_dtw_gamma[index]),
        if (!is.na(grid$som_iterations[index])) {
          paste0(
            grid$som_iterations[index],
            " SOM iterations"
          )
        },
        if (!is.na(grid$deep_latent_dimensions[index])) {
          paste0(
            "latent ",
            grid$deep_latent_dimensions[index],
            " · ",
            grid$deep_epochs[index],
            " epochs"
          )
        }
      )
      shiny::div(
        class = "queue-item",
        shiny::span(class = "queue-index", sprintf("%02d", index)),
        shiny::div(
          shiny::strong(grid$representation[index]),
          shiny::span(paste(grid$aggregation[index],
            grid$normalization[index],
            algorithm_labels[[recipe$algorithm]],
            distance_labels[[recipe$distance]],
            sep = " · "
          )),
          if (length(parameter_values)) {
            shiny::tags$small(
              class = "queue-parameters",
              paste(parameter_values,
                collapse = " · "
              )
            )
          }
        ),
        shiny::tags$button(
          type = "button", class = "queue-remove-button",
          title = "Remove this experiment", `aria-label` = paste("Remove experiment", index),
          onclick = sprintf(
            "Shiny.setInputValue('remove_experiment_item', '%d', {priority: 'event'})",
            index
          ),
          bsicons::bs_icon("x-lg")
        )
      )
    })
  )
})

# Wait until the browser has sent every initial input before the first demo
# run. Triggering from input$run at session creation used to cache an error
# with NULL controls, leaving every downstream plot empty until a manual run.
