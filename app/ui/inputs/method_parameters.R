build_advanced_inputs <- function() {
  shiny::conditionalPanel(
    paste0(
      "(input.experiment_representation && ",
      "input.experiment_representation.indexOf('pca_') === 0) || ",
      "['hdbscan','soft_dtw','som','deep_autoencoder']",
      ".includes(input.experiment_algorithm) || ",
      "(input.experiment_distance && ",
      "input.experiment_distance.indexOf('dtw') !== -1)"
    ),
    class = "method-parameters-wrap",
    shiny::tags$details(
      class = "advanced-inputs",
      open = NA,
      shiny::tags$summary(
        bsicons::bs_icon("gear"),
        shiny::span("Method-specific parameters"),
        shiny::tags$small(paste0(
          "Parameters required by the selected transformation, distance or ",
          "clustering method"
        ))
      ),
      shiny::div(
        class = "advanced-input-grid",
        shiny::conditionalPanel(
          paste0(
            "input.experiment_representation && ",
            "input.experiment_representation.indexOf('pca_') === 0"
          ),
          class = "method-parameter-section",
          shiny::h5("Transformation parameters"),
          shiny::p("Controls used while constructing the selected reduced representation."),
          shiny::div(
            class = "compact-input-grid",
            shiny::sliderInput("pca_variance",
              help_label(
                "PCA variance retained (%)",
                "pca_variance"
              ),
              80,
              100,
              95,
              step = 1
            ),
            shiny::numericInput("pca_max_components",
              help_label(
                "Maximum PCA components",
                "pca_max_components"
              ),
              30,
              min = 2,
              max = 100,
              step = 1
            )
          ),
          shiny::conditionalPanel(
            "input.experiment_representation === 'pca_annual_clr'",
            shiny::sliderInput("clr_zero_fraction",
              help_label(
                "CLR zero replacement fraction",
                "clr_zero_fraction"
              ),
              0.05,
              0.95,
              0.5,
              step = 0.05
            )
          )
        ),
        shiny::conditionalPanel(
          "input.experiment_distance && input.experiment_distance.indexOf('dtw') !== -1",
          class = "method-parameter-section",
          shiny::h5("Distance parameters"),
          shiny::p("Controls the permitted temporal displacement during elastic alignment."),
          shiny::sliderInput("dtw_window", help_label("DTW warping window (hours)", "dtw_window"),
            1, 24, 12,
            step = 1
          )
        ),
        shiny::conditionalPanel(
          "['hdbscan','soft_dtw','som','deep_autoencoder'].includes(input.experiment_algorithm)",
          class = "method-parameter-section",
          shiny::h5("Clustering method parameters"),
          shiny::p("Hyperparameters used only by the selected clustering algorithm."),
          shiny::conditionalPanel(
            "input.experiment_algorithm === 'hdbscan'",
            shiny::div(
              class = "compact-input-grid",
              shiny::numericInput("hdbscan_min_points",
                help_label(
                  "HDBSCAN min points",
                  "hdbscan_min_points"
                ),
                3,
                min = 3,
                step = 1
              ),
              shiny::sliderInput("max_noise_share",
                help_label(
                  "Maximum HDBSCAN noise (%)",
                  "max_noise_share"
                ),
                0,
                60,
                20,
                step = 5
              )
            )
          ),
          shiny::conditionalPanel(
            "input.experiment_algorithm === 'soft_dtw'",
            shiny::numericInput("soft_dtw_gamma",
              help_label(
                "Soft-DTW gamma",
                "soft_dtw_gamma"
              ),
              0.05,
              min = 0.001,
              step = 0.01
            )
          ),
          shiny::conditionalPanel(
            "input.experiment_algorithm === 'som'",
            shiny::numericInput("som_iterations",
              help_label(
                "SOM iterations",
                "som_iterations"
              ),
              100,
              min = 20,
              step = 20
            )
          ),
          shiny::conditionalPanel(
            "input.experiment_algorithm === 'deep_autoencoder'",
            shiny::div(
              class = "compact-input-grid",
              shiny::numericInput("deep_latent_dimensions",
                help_label(
                  "Deep latent dimensions",
                  "deep_latent_dimensions"
                ),
                4,
                min = 2,
                step = 1
              ),
              shiny::numericInput("deep_epochs",
                help_label(
                  "Deep training epochs",
                  "deep_epochs"
                ),
                80,
                min = 20,
                step = 20
              )
            )
          )
        )
      )
    )
  )
}
