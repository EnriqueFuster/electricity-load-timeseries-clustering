register_theory_explorers(input, output, session)

chart_heights <- c(
  prototype_plot = 660, cluster_members_plot = 820,
  series_view_plot = 720, silhouette_plot = 620,
  stability_plot = 560, runtime_plot = 560, balance_plot = 560,
  dunn_plot = 560, smallest_share_plot = 560, noise_share_plot = 560,
  pca_plot = 700, size_plot = 700, silhouette_detail_plot = 720,
  peer_distance_plot = 720, dissimilarity_plot = 800,
  cluster_heatmap_plot = 860, atypicality_plot = 760,
  algorithm_plot_1 = 720, algorithm_plot_2 = 720, algorithm_plot_3 = 720
)

# A card owns one chart binding at a time. This mirrors the stable Plotly
# pattern used by e-strategy-app and avoids hidden duplicate outputs.
register_chart_container <- function(chart_id, chart_height) {
  force(chart_id)
  force(chart_height)
  container_id <- paste0(chart_id, "_container")
  output[[container_id]] <- shiny::renderUI({
    if (identical(input$visualization_mode, "interactive")) {
      shiny::div(
        class = "interactive-chart-shell",
        shiny::div(
          class = "interactive-chart-loading",
          shiny::span(class = "loading-pulse"),
          "Rendering interactive chart…"
        ),
        plotly::plotlyOutput(chart_id, height = chart_height)
      )
    } else {
      shiny::plotOutput(paste0(chart_id, "_static"), height = chart_height)
    }
  })
}

for (chart_id in names(chart_heights)) {
  local({
    current_id <- chart_id
    register_chart_container(current_id, unname(chart_heights[[current_id]]))
  })
}

catalog <- get_clustering_recipe_catalog()
catch22_available <- requireNamespace("Rcatch22", quietly = TRUE)
catch22_representations <- c("catch22_global", "catch22_seasonal", "catch24_seasonal")
representation_family <- c(
  typical_week = "whole-series", seasonal_daypart = "feature-based",
  behavioral_features = "feature-based", pca_typical_week = "transformation-based",
  pca_annual_unit_sum = "transformation-based", pca_annual_clr = "transformation-based",
  pca_annual_zscore = "transformation-based", catch22_global = "feature-based",
  catch22_seasonal = "feature-based", catch24_seasonal = "feature-based"
)
algorithm_labels <- c(
  kmeans = "K-means", pam = "PAM / k-medoids", dtw_dba = "DTW + DBA",
  hierarchical = "Hierarchical clustering", kshape = "k-Shape", som = "Self-Organising Map",
  gmm = "Gaussian mixture model", hdbscan = "HDBSCAN", soft_dtw = "Soft-DTW clustering",
  deep_autoencoder = "Deep autoencoder + K-means"
)
distance_labels <- c(
  euclidean = "Euclidean", manhattan = "Manhattan", dtw_basic = "Constrained DTW",
  sbd = "Shape-based distance (SBD)", model_based = "GMM feature-space geometry",
  soft_dtw = "Soft-DTW", latent_euclidean = "Euclidean in learned latent space"
)
representation_explanations <- c(
  typical_week = "168 ordered hourly values summarize the recurrent Monday–Sunday shape.",
  seasonal_daypart = paste0(
    "Up to 48 season × day-type × four-hour-block features preserve coarse ",
    "calendar behaviour."
  ),
  behavioral_features = paste0(
    "Interpretable magnitude, regularity, peak-timing, daypart and seasonal ",
    "attributes describe each meter."
  ),
  pca_typical_week = paste0(
    "Orthogonal weekly scores retain the configured share of normalized ",
    "variance before clustering."
  ),
  pca_annual_unit_sum = paste0(
    "The complete 8,760-hour year is divided by annual energy, then PCA retains ",
    "its dominant allocation patterns."
  ),
  pca_annual_clr = paste0(
    "Annual energy shares are zero-replaced, mapped to centred log-ratios and ",
    "reduced with PCA. Similarity concerns relative allocation between hours."
  ),
  pca_annual_zscore = paste0(
    "Each complete annual curve is standardized by its own mean and standard ",
    "deviation before PCA, emphasizing annual shape."
  ),
  catch22_global = paste0(
    "Twenty-two canonical time-series characteristics summarize the complete ",
    "annual curve and are standardized across meters."
  ),
  catch22_seasonal = paste0(
    "catch22 is calculated separately for winter, spring, summer and autumn to ",
    "retain seasonal changes in dynamics."
  ),
  catch24_seasonal = paste0(
    "Seasonal catch22 is augmented with mean and standard deviation, restoring ",
    "level and dispersion information."
  )
)
algorithm_explanations <- c(
  kmeans = "K-means searches for compact Euclidean groups around arithmetic centroids.",
  pam = paste0(
    "PAM minimizes dissimilarity to observed representative medoids and ",
    "accepts several distances."
  ),
  dtw_dba = paste0(
    "DTW + DBA forms elastic time-series groups and estimates aligned ",
    "barycentre prototypes."
  ),
  hierarchical = paste0(
    "Hierarchical clustering builds an inspectable merge tree from ",
    "constrained-DTW dissimilarities."
  ),
  kshape = paste0(
    "k-Shape explicitly z-normalizes each curve, then groups morphology using ",
    "cross-correlation and shape centroids."
  ),
  som = paste0(
    "SOM learns a topology-preserving map; its codebook vectors are then ",
    "grouped into the requested K."
  ),
  gmm = "GMM fits probabilistic Gaussian components and returns posterior membership confidence.",
  hdbscan = paste0(
    "HDBSCAN extracts persistent density groups, discovers K and may mark ",
    "isolated profiles as noise."
  ),
  soft_dtw = paste0(
    "Soft-DTW clustering uses a smooth elastic alignment objective on ordered ",
    "weekly curves."
  ),
  deep_autoencoder = paste0(
    "An exploratory autoencoder learns a nonlinear embedding that is ",
    "subsequently clustered with K-means."
  )
)
distance_explanations <- c(
  euclidean = paste0(
    "Euclidean distance compares matching coordinates using the square root of ",
    "summed squared residuals; K-means minimizes its squared form."
  ),
  manhattan = paste0(
    "Manhattan distance sums absolute coordinate differences and is less ",
    "dominated by a single deviation."
  ),
  dtw_basic = paste0(
    "Constrained DTW permits nearby temporal alignment within the configured ",
    "warping window."
  ),
  sbd = "SBD compares normalized time-series shape through cross-correlation.",
  model_based = paste0(
    "GMM fitting is likelihood-based; common validation uses Euclidean ",
    "dissimilarity in the feature embedding used to fit the mixture."
  ),
  soft_dtw = paste0(
    "Soft-DTW smoothly aggregates possible temporal alignments; gamma controls ",
    "smoothness."
  ),
  latent_euclidean = paste0(
    "Euclidean distance is calculated after the neural encoder maps inputs ",
    "into latent coordinates."
  )
)
initial_config <- read_project_config(file.path(config$root, "config", "demo.yml"))
initial_experiments <- data.frame(
  representation = "typical_week", recipe = "kmeans_euclidean",
  aggregation = "median", normalization = "zscore",
  pca_variance = NA_real_, pca_max_components = NA_integer_, clr_zero_fraction = NA_real_,
  dtw_window = NA_integer_, hdbscan_min_points = NA_integer_, max_noise_share = NA_real_,
  soft_dtw_gamma = NA_real_, som_iterations = NA_integer_,
  deep_latent_dimensions = NA_integer_, deep_epochs = NA_integer_,
  stringsAsFactors = FALSE
)
if (!catch22_available) {
  initial_experiments <- initial_experiments[
    !initial_experiments$representation %in% catch22_representations, ,
    drop = FALSE
  ]
}
experiments <- shiny::reactiveVal(initial_experiments)

representation_options <- list(
  weekly = c(
    "None · retain 168 ordered hours" = "typical_week",
    "PCA · compressed weekly scores" = "pca_typical_week"
  ),
  annual = c(
    "Unit-sum + PCA" = "pca_annual_unit_sum",
    "Unit-sum + CLR + PCA" = "pca_annual_clr",
    "Row z-score + PCA" = "pca_annual_zscore",
    "Global catch22 features" = "catch22_global",
    "Seasonal catch22 features" = "catch22_seasonal",
    "Seasonal catch24 features" = "catch24_seasonal"
  ),
  seasonal = c("Calendar aggregation · 48 interpretable features" = "seasonal_daypart"),
  behavioral = c("Engineered behavior and energy features" = "behavioral_features")
)
representation_labels <- stats::setNames(
  unlist(lapply(representation_options, names), use.names = FALSE),
  unlist(representation_options, use.names = FALSE)
)
temporal_explanations <- c(
  weekly = paste0(
    "Compresses the year into 168 ordered Monday–Sunday hours. It preserves ",
    "recurrent clock-time behaviour while smoothing seasonal and exceptional-day ",
    "effects."
  ),
  annual = paste0(
    "Keeps the complete common calendar of 8,760 hourly positions. It can retain ",
    "seasonality and exceptional periods, but requires dimensionality reduction ",
    "or feature extraction."
  ),
  seasonal = paste0(
    "Aggregates consumption by season, working-day type and four-hour block. The ",
    "resulting 48 coordinates are compact and operationally interpretable."
  ),
  behavioral = paste0(
    "Replaces the ordered curve with interpretable indicators of energy, peaks, ",
    "regularity, dayparts and seasonal behaviour. Exact hour-to-hour ordering is ",
    "not retained."
  )
)
aggregation_explanations <- c(
  median = paste0(
    "For each hour of the typical week, the median across observed weeks is ",
    "used. This is robust to holidays, outages and isolated peaks."
  ),
  mean = paste0(
    "For each hour of the typical week, the arithmetic mean across observed ",
    "weeks is used. Every observation influences the profile, including ",
    "exceptional peaks."
  )
)
normalization_explanations <- c(
  zscore = paste0(
    "Each curve is centred and scaled by its own standard deviation, so ",
    "clustering emphasizes shape rather than absolute demand."
  ),
  unit_sum = paste0(
    "Each curve is divided by its total energy, so coordinates express the share ",
    "allocated to each interval."
  ),
  none = paste0(
    "Original scale is retained, allowing both demand magnitude and temporal ",
    "shape to affect similarity."
  )
)
