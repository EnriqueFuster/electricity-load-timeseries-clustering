build_benchmark_panel <- function() {
  shiny::div(
    class = "workflow-page",
    build_experiment_builder(),
    build_experiment_queue(),
    shiny::div(
      class = "input-card-grid policy-grid",
      build_cluster_search(),
      build_recommendation_policy()
    ),
    shiny::div(
      class = "run-workflow",
      shiny::div(
        bsicons::bs_icon("cpu"),
        shiny::div(
          shiny::strong("Ready to fit the benchmark"),
          shiny::span("Interactive runs are limited to 80 series and 750,000 rows.")
        )
      ),
      help_action(
        shiny::actionButton("run",
          "Run benchmark",
          class = "run-button",
          icon = shiny::icon("play")
        ),
        input_help$run
      )
    )
  )
}

build_experiment_builder <- function() {
  shiny::tags$section(
    class = "input-card experiment-builder-card",
    input_card_heading("diagram-3", "Experiment builder", paste0(
      "Build one clustering experiment from left to right. Each choice limits the ",
      "following menus to combinations that can be fitted correctly."
    )),
    shiny::div(
      class = "recipe-builder",
      shiny::div(
        class = "recipe-step",
        shiny::span("1"),
        shiny::selectInput(
          "temporal_basis",
          help_label(
            "Temporal representation",
            "experiment_representation"
          ),
          c(
            "Typical week · 168 ordered hours" = "weekly",
            "Complete year · 8,760 ordered hours" = "annual",
            "Season × day type × time block" = "seasonal",
            "Behavioral summary" = "behavioral"
          )
        )
      ),
      shiny::div(
        class = "recipe-step",
        shiny::span("2"),
        shiny::conditionalPanel(
          "input.temporal_basis === 'weekly'",
          shiny::selectInput(
            "aggregation",
            help_label(
              "Hourly aggregation statistic",
              "aggregation"
            ),
            c(
              "Median · robust to exceptional days" = "median",
              "Mean · preserves total influence" = "mean"
            )
          )
        ),
        shiny::conditionalPanel("input.temporal_basis !== 'weekly'",
          class = "stage-not-applicable",
          "No repeated-hour aggregation"
        )
      ),
      shiny::div(
        class = "recipe-step",
        shiny::span("3"),
        shiny::selectInput(
          "normalization",
          help_label(
            "Normalization / comparison objective",
            "normalization"
          ),
          c(
            "Shape · z-score per series" = "zscore",
            "Shape shares · unit sum" = "unit_sum",
            "Magnitude + shape · no normalization" = "none"
          )
        )
      ),
      shiny::div(
        class = "recipe-step",
        shiny::span("4"),
        shiny::selectInput("representation_method",
          help_label(
            "Transformation / reduction",
            "experiment_representation"
          ),
          choices = NULL
        )
      ),
      shiny::div(
        class = "recipe-step",
        shiny::span("5"),
        shiny::selectInput("experiment_algorithm",
          help_label(
            "Clustering algorithm",
            "experiment_algorithm"
          ),
          choices = NULL
        )
      ),
      shiny::div(
        class = "recipe-step",
        shiny::span("6"),
        shiny::selectInput("experiment_distance",
          help_label(
            "Distance / similarity",
            "experiment_distance"
          ),
          choices = NULL
        )
      ),
      shiny::div(
        class = "internal-input",
        shiny::selectInput("experiment_representation",
          NULL,
          choices = "typical_week"
        )
      )
    ),
    shiny::uiOutput("experiment_explanation"),
    shiny::uiOutput("optional_dependency_status"),
    build_advanced_inputs(),
    help_action(
      shiny::actionButton("add_experiment",
        "Add this experiment",
        icon = shiny::icon("plus"),
        class = "builder-button"
      ),
      "Add the valid combination to the benchmark queue."
    )
  )
}

build_experiment_queue <- function() {
  shiny::tags$section(
    class = "input-card experiment-queue-card",
    input_card_heading(
      "list-check", "Benchmark queue",
      "Only the combinations listed here will be fitted."
    ),
    shiny::uiOutput("experiment_queue"),
    shiny::div(
      class = "queue-actions",
      help_action(
        shiny::actionButton("clear_experiments",
          "Remove all",
          icon = shiny::icon("trash"),
          class = "builder-secondary queue-utility"
        ),
        "Empty the benchmark queue."
      ),
      help_action(
        shiny::actionButton("reset_experiments",
          "Restore defaults",
          class = "builder-secondary"
        ),
        "Replace the queue with the balanced default benchmark."
      )
    )
  )
}

build_cluster_search <- function() {
  shiny::tags$section(
    class = "input-card cluster-search-card",
    input_card_heading(
      "search",
      "Cluster search",
      paste0(
        "Define which cluster counts are fitted and how the stability of each ",
        "candidate is assessed."
      )
    ),
    shiny::tags$section(
      class = "recommendation-control-group",
      shiny::div(
        class = "recommendation-group-heading",
        shiny::div(
          shiny::span("CANDIDATE PARTITIONS"),
          shiny::h5("Which cluster counts should be fitted")
        ),
        shiny::p(
          "K applies to methods that require a predefined number of clusters."
        )
      ),
      shiny::radioButtons(
        "k_mode",
        help_label(
          "Number of clusters",
          "k_mode"
        ),
        c(
          "Compare a range of k values" = "auto",
          "Fit one fixed k value" = "manual"
        ),
        inline = TRUE
      ),
      shiny::conditionalPanel(
        "input.k_mode == 'auto'",
        shiny::sliderInput(
          "k_range",
          help_label(
            "Candidate k range",
            "k_range"
          ),
          2,
          10,
          c(
            2,
            5
          ),
          step = 1
        )
      ),
      shiny::conditionalPanel(
        "input.k_mode == 'manual'",
        shiny::sliderInput(
          "fixed_k",
          help_label(
            "Fixed k",
            "fixed_k"
          ),
          2,
          10,
          3,
          step = 1
        )
      ),
      shiny::p(
        class = "recommendation-group-note",
        paste0(
          "The selected values create fitted candidates; they do not tell the ",
          "recommendation policy which result should win. HDBSCAN estimates its own ",
          "number of clusters and therefore ignores k."
        )
      )
    ),
    shiny::tags$section(
      class = "recommendation-control-group",
      shiny::div(
        class = "recommendation-group-heading",
        shiny::div(
          shiny::span("VALIDATION AND REPRODUCIBILITY"),
          shiny::h5("How reliably should candidates be checked")
        ),
        shiny::p("These controls define repeated evaluation, not ranking preferences.")
      ),
      shiny::div(
        class = "compact-input-grid",
        shiny::sliderInput(
          "repeats",
          help_label(
            "Stability subsamples",
            "repeats"
          ),
          2,
          10,
          4,
          step = 1
        ),
        shiny::numericInput(
          "seed",
          help_label(
            "Random seed",
            "seed"
          ),
          4107,
          min = 1,
          step = 1
        )
      ),
      shiny::p(
        class = "recommendation-group-note cluster-search-note",
        paste0(
          "Stability is calculated for every successful candidate using repeated 80% ",
          "profile subsamples. More repetitions strengthen this diagnostic but increase ",
          "runtime. The seed supports reproducibility; it is not a quality target."
        )
      )
    )
  )
}

build_recommendation_policy <- function() {
  shiny::tags$section(
    class = "input-card",
    input_card_heading(
      "award",
      "Recommendation policy",
      paste0(
        "Choose how fitted candidates become eligible, how eligible results are ranked ",
        "and which complete method configuration is recommended."
      )
    ),
    shiny::tags$section(
      class = "recommendation-control-group",
      shiny::div(
        class = "recommendation-group-heading",
        shiny::div(
          shiny::span("ELIGIBILITY FILTERS"),
          shiny::h5("Which fitted candidates may be recommended")
        ),
        shiny::p("These thresholds are pass/fail safeguards, not score weights.")
      ),
      shiny::div(
        class = "threshold-grid",
        shiny::sliderInput("min_cluster_share",
          help_label(
            "Minimum cluster share (%)",
            "min_cluster_share"
          ),
          1,
          25,
          5,
          step = 1
        ),
        shiny::sliderInput("min_stability",
          help_label(
            "Minimum stability",
            "min_stability"
          ),
          0,
          1,
          0,
          step = .05
        ),
        shiny::sliderInput("min_silhouette",
          help_label(
            "Minimum silhouette",
            "min_silhouette"
          ),
          -0.25,
          0.75,
          0,
          step = .05
        )
      ),
      shiny::p(
        class = "recommendation-group-note",
        paste0(
          "A successful fit and an evaluable silhouette are always required. HDBSCAN ",
          "also applies the maximum noise share configured in its method parameters."
        )
      )
    ),
    shiny::tags$section(
      class = "recommendation-control-group",
      shiny::div(
        class = "recommendation-group-heading",
        shiny::div(
          shiny::span("RANKING WEIGHTS"),
          shiny::h5("How eligible candidates are ordered")
        ),
        shiny::p(
          paste0(
            "Each metric is rescaled from 0 to 1 across the eligible candidates; ",
            "the weights then determine its contribution to the score."
          )
        )
      ),
      shiny::div(
        class = "weight-grid",
        shiny::numericInput("weight_silhouette",
          help_label(
            "Silhouette weight",
            "weight_silhouette"
          ),
          0.55,
          min = 0,
          max = 1,
          step = .05
        ),
        shiny::numericInput("weight_stability",
          help_label(
            "Stability weight",
            "weight_stability"
          ),
          0.30,
          min = 0,
          max = 1,
          step = .05
        ),
        shiny::numericInput("weight_balance",
          help_label(
            "Balance weight",
            "weight_balance"
          ),
          0.15,
          min = 0,
          max = 1,
          step = .05
        )
      ),
      shiny::p(
        class = "recommendation-group-note",
        paste0(
          "The resulting score orders candidates only within this benchmark. It is not ",
          "accuracy and should not be compared with a score from another benchmark run. ",
          "A small 0.01 × k penalty favours simpler solutions when evidence is similar."
        )
      )
    ),
    shiny::div(
      class = "recommendation-policy-note",
      bsicons::bs_icon("info-circle"),
      shiny::p(
        shiny::strong("What the recommendation means. "),
        paste0(
          "It selects one complete fitted method configuration: representation, ",
          "transformation, ",
          "distance, algorithm and cluster count. This becomes the default result but ",
          "does not change any fitted clusters. Every successful alternative remains ",
          "available, ",
          "and the final choice still requires temporal inspection and practical judgement."
        )
      )
    )
  )
}
