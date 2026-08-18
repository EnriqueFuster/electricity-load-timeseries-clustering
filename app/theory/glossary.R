theory_glossary_ui <- function() {
  # nolint start: line_length_linter.
  terms <- list(
    c("AIC", "Akaike Information Criterion", "Likelihood-based model comparison with a penalty for the number of estimated parameters."),
    c("ARI", "Adjusted Rand Index", "Agreement between two partitions, corrected for chance."),
    c("BIC", "Bayesian Information Criterion", "A likelihood-and-complexity criterion. The mclust convention used here reports larger values as stronger support within the fitted candidate family."),
    c("catch22", "22 CAnonical Time-series CHaracteristics", "A compact set of 22 diverse time-series features selected for broad coverage and computational efficiency."),
    c("catch24", "catch22 plus mean and standard deviation", "The catch22 feature set with two elementary level-and-scale features restored."),
    c("CLR", "Centred log-ratio", "A compositional transformation that expresses every share relative to the profile's geometric mean."),
    c("CRAN", "Comprehensive R Archive Network", "The primary repository from which the R package dependencies used by the project are distributed."),
    c("DBA", "Dynamic Time Warping Barycenter Averaging", "An iterative method for estimating a representative sequence after temporal alignment."),
    c("DEC", "Deep Embedded Clustering", "A joint deep-representation and clustering approach; the application's autoencoder recipe is explicitly not DEC."),
    c("DTW", "Dynamic Time Warping", "An elastic dissimilarity that aligns ordered sequences while comparing them."),
    c("EM", "Expectation–maximisation", "The iterative estimation procedure commonly used to fit Gaussian mixture models."),
    c("GMM", "Gaussian Mixture Model", "A probabilistic model in which observations arise from a mixture of Gaussian components."),
    c("HAC", "Hierarchical agglomerative clustering", "A bottom-up method that repeatedly merges the closest groups to form a dendrogram."),
    c("HDBSCAN", "Hierarchical Density-Based Spatial Clustering of Applications with Noise", "A density-based method that can identify irregular groups and label weakly supported observations as noise."),
    c("HMM", "Hidden Markov Model", "A sequence model with unobserved states that generate the observed measurements; discussed as future research, not an implemented recipe."),
    c("IANA", "Internet Assigned Numbers Authority", "The source of canonical timezone identifiers such as Europe/Madrid."),
    c("KL", "Kullback–Leibler", "A directional divergence between probability distributions; discussed as a future extension."),
    c("L1", "L1 norm", "The sum of absolute coordinate differences, which defines Manhattan distance."),
    c("NCC", "Normalised cross-correlation", "A correlation-based comparison across temporal shifts, used to construct SBD."),
    c("PAA", "Piecewise Aggregate Approximation", "A dimensionality-reduction method that averages consecutive time intervals; listed as a future representation."),
    c("PAM", "Partitioning Around Medoids", "A K-medoids algorithm that represents every cluster with an observed profile."),
    c("PC", "Principal component", "One orthogonal direction learned by PCA; PC1 and PC2 are the first two directions."),
    c("PCA", "Principal Component Analysis", "A linear transformation that compresses correlated variables into orthogonal components ordered by explained variance."),
    c("SAX", "Symbolic Aggregate approXimation", "A symbolic representation of a reduced time series; listed as a future extension."),
    c("SBD", "Shape-Based Distance", "A dissimilarity derived from the best normalised cross-correlation across temporal shifts."),
    c("SOM", "Self-Organising Map", "A neural mapping method that places similar observations on nearby units of a low-dimensional grid."),
    c("UTC", "Coordinated Universal Time", "The common analytical calendar currently used after input timestamps are parsed.")
  )
  # nolint end

  bslib::nav_panel(
    "Glossary",
    shiny::div(
      class = "theory-glossary-page",
      shiny::div(
        class = "theory-glossary-hero",
        shiny::div(
          shiny::span(class = "theory-glossary-kicker", "REFERENCE"),
          shiny::h2("Acronyms and technical shorthand"),
          shiny::p(paste0(
            "A single alphabetical reference for the abbreviations used throughout Learn. ",
            "Definitions describe how each term is used in this app."
          ))
        )#,
        # shiny::div(
        #   class = "theory-glossary-count",
        #   shiny::strong(length(terms)),
        #   shiny::span("defined terms")
        # )
      ),
      shiny::div(
        class = "theory-glossary-table-wrap",
        shiny::tags$table(
          class = "theory-glossary-table",
          shiny::tags$thead(shiny::tags$tr(
            shiny::tags$th("Term"),
            shiny::tags$th("Full name"),
            shiny::tags$th("Meaning in this app")
          )),
          shiny::tags$tbody(lapply(terms, function(term) {
            shiny::tags$tr(
              shiny::tags$td(shiny::tags$abbr(title = term[[2]], term[[1]])),
              shiny::tags$td(term[[2]]),
              shiny::tags$td(term[[3]])
            )
          }))
        )
      )
    )
  )
}
