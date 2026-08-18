input_help <- list(
  data_mode = paste0(
    "Use the bundled anonymized GoiEner sample to explore the workflow, or upload your own ",
    "hourly curves."
  ),
  upload_format = paste0(
    "Canonical long CSV uses one file containing all curves: each row is one hourly ",
    "observation and a series-ID column identifies its curve. One CSV per series uses ",
    "a separate file for each curve; the filename becomes the series ID, so those files ",
    "need only timestamp and consumption columns."
  ),
  files = paste0(
    "Upload exactly one file for Canonical long CSV, or multiple files for One CSV per ",
    "series. Every file must use the selected delimiter, column names and common timezone. ",
    "The app does not persist uploads after the Shiny session ends."
  ),
  timestamp_column = paste0(
    "Exact name of the column containing each hourly date-time, for example timestamp. ",
    "Values must be unambiguous and consistently formatted, such as 2024-01-01 00:00:00. ",
    "The selected common timezone is used to interpret every curve."
  ),
  value_column = paste0(
    "Exact name of the numeric electricity-consumption column, for example value. All ",
    "curves should use the same measurement unit and hourly aggregation. Negative values ",
    "are rejected by the current quality policy."
  ),
  series_id_column = paste0(
    "Required only for Canonical long CSV. This column identifies which rows belong to ",
    "the same meter or load profile; for example, all rows labelled meter_001 form one curve."
  ),
  delimiter = paste0(
    "Character separating fields in every uploaded file. Select comma for standard CSV, ",
    "semicolon for common European exports, or tab for tab-delimited text."
  ),
  timezone = paste0(
    "One IANA timezone used to parse timestamps across every uploaded curve, for example ",
    "UTC or Europe/Madrid. All files must share this input timezone. After parsing, the current ",
    "study standardizes calendar extraction to UTC; a regional input timezone does not preserve ",
    "local civil-clock grouping in downstream representations."
  ),
  anonymize_ids = paste0(
    "Replaces source identifiers before quality checks, models and exports. The ",
    "mapping is not persisted."
  ),
  id_prefix = "Prefix used to create identifiers such as profile_001.",
  complete_year_missing = paste0(
    "Maximum fraction of missing hourly positions inside the selected ",
    "January–December year. Accepted gaps are imputed later."
  ),
  max_missing = paste0(
    "Maximum missingness over the complete source history. This gate is ",
    "evaluated before imputation."
  ),
  min_coverage = paste0(
    "Minimum inclusive temporal coverage. The web study always also requires a ",
    "complete natural year."
  ),
  aggregation = paste0(
    "Median is robust to exceptional days; mean preserves their influence when ",
    "constructing the 168-hour typical week."
  ),
  normalization = paste0(
    "Defines whether clustering compares shape, energy allocation or absolute ",
    "magnitude. Original kWh are retained for interpretation."
  ),
  pca_variance = paste0(
    "Minimum cumulative variance targeted by PCA. The fitted number of ",
    "components is data-dependent."
  ),
  pca_max_components = paste0(
    "Safety cap on PCA dimensionality. If this cap is reached, retained variance ",
    "may be below the target."
  ),
  clr_zero_fraction = paste0(
    "Zeros cannot be logged. Each zero is replaced by this fraction of that ",
    "profile's smallest positive hourly share, then the composition is reclosed."
  ),
  experiment_representation = paste0(
    "The numerical description of each meter. It determines what information ",
    "can influence similarity."
  ),
  experiment_algorithm = paste0(
    "The rule used to form groups. Choices are restricted by the selected ",
    "representation."
  ),
  experiment_distance = paste0(
    "The mathematical meaning of similarity. Only distances compatible with the ",
    "representation and algorithm are shown."
  ),
  experiment_remove = paste0(
    "Select one queued representation–algorithm–distance experiment ",
    "to remove."
  ),
  k_mode = paste0(
    "Choose whether K-dependent methods test every value in a range or fit one fixed ",
    "number of clusters. HDBSCAN discovers its own cluster count. This changes the ",
    "candidate set, not the recommendation formula."
  ),
  k_range = paste0(
    "Inclusive K values fitted for every queued method that requires K. A wider range ",
    "creates more candidates and can change the relative recommendation score because ",
    "metrics are rescaled within the current benchmark."
  ),
  fixed_k = paste0(
    "Exact cluster count fitted by every K-dependent candidate. It does not force ",
    "HDBSCAN to produce that number of clusters."
  ),
  repeats = paste0(
    "Number of repeated 80% profile subsamples used to estimate stability with the ",
    "adjusted Rand index. More repeats improve the evidence but increase runtime; they ",
    "do not directly change the fitted full-data clusters."
  ),
  dtw_window = paste0(
    "Maximum temporal displacement allowed by constrained DTW. Smaller windows ",
    "preserve the meaning of clock time."
  ),
  seed = paste0(
    "Controls random initialization and stability subsampling. Reusing the seed makes ",
    "the benchmark reproducible; it is not a quality target or recommendation weight."
  ),
  min_cluster_share = paste0(
    "Eligibility filter for every algorithm. A fitted candidate cannot be recommended ",
    "when its smallest non-noise cluster contains less than this share of all accepted ",
    "profiles. The candidate and its clusters remain available for inspection."
  ),
  min_stability = paste0(
    "Eligibility filter for every algorithm. It requires the mean adjusted-Rand ",
    "agreement across repeated 80% subsamples to reach this value. It filters the ",
    "recommendation; it does not alter cluster assignments."
  ),
  min_silhouette = paste0(
    "Eligibility filter for every algorithm. It requires the candidate's mean ",
    "silhouette, calculated with its evaluation distance, to reach this value. Values ",
    "near 1 indicate clearer separation; the filter does not refit the model."
  ),
  max_noise_share = paste0(
    "Maximum share of meters HDBSCAN may label as noise before being excluded ",
    "from recommendation."
  ),
  weight_silhouette = paste0(
    "Ranking preference used only after all eligibility filters. It controls the ",
    "contribution of silhouette after that metric has been rescaled from 0 to 1 across ",
    "the eligible candidates in this benchmark. The three weights are converted to ",
    "proportions that sum to one. The resulting score is a relative comparison index, ",
    "not predictive accuracy."
  ),
  weight_stability = paste0(
    "Ranking preference used only for eligible candidates. It controls the contribution ",
    "of rescaled conditional subsample stability. Increasing it favours reproducible ",
    "partitions for the already prepared representation, ",
    "but does not change any clusters already fitted."
  ),
  weight_balance = paste0(
    "Ranking preference used only for eligible candidates. It controls the contribution ",
    "of rescaled cluster-size balance. Increasing it favours similarly sized groups, ",
    "which may not always match a meaningful rare consumption pattern."
  ),
  hdbscan_min_points = paste0(
    "Minimum number of nearby profiles used by HDBSCAN to identify a dense ",
    "group. Larger values make small or weakly supported clusters less likely ",
    "and may classify more profiles as noise."
  ),
  soft_dtw_gamma = paste0(
    "Smoothness of the Soft-DTW minimum. Values approaching zero behave more ",
    "like ordinary DTW."
  ),
  som_iterations = paste0(
    "Number of training passes for the self-organising map. More passes cost ",
    "time and may improve map convergence."
  ),
  deep_latent_dimensions = "Size of the nonlinear autoencoder embedding used before K-means.",
  deep_epochs = paste0(
    "Number of optimization passes through the representation matrix. This ",
    "exploratory method needs the Torch runtime."
  ),
  run = paste0(
    "Validate the data, construct every queued representation and fit the ",
    "complete candidate grid."
  ),
  model_choice = paste0(
    "Select the fitted clustering result used throughout the analysis. Method ",
    "selection continues to compare the benchmark candidates; the recommendation ",
    "is marked explicitly."
  ),
  series = "Choose one accepted profile for inspection in Prepare data.",
  series_view = paste0(
    "Switch between the complete annual curve, recurrent weekly and daily ",
    "summaries, or a day-by-hour annual heatmap. This changes only the ",
    "inspection view."
  ),
  series_ribbon = paste0(
    "Lower and upper percentiles calculated at each recurring hour across all ",
    "observed weeks or days. The default P25-P75 band is the interquartile ",
    "range."
  ),
  series_jitter = paste0(
    "Adds every observed hourly value behind the typical day or week. Horizontal ",
    "jitter and high transparency reveal the distribution without changing the data. ",
    "It is disabled by default because interactive rendering becomes heavier."
  ),
  profile_jitter = paste0(
    "Adds the hourly observations assigned to each cluster behind its median and ",
    "percentile ribbon. It is available for daily and weekly summaries and is disabled ",
    "by default to keep the interactive chart responsive."
  ),
  profile_band = paste0(
    "Lower and upper percentiles of the shaded geom_ribbon around each cluster ",
    "median. P25-P75 is the interquartile range; wider limits show more member ",
    "variability."
  )
)

help_label <- function(text, key) {
  help_text <- input_help[[key]]
  if (is.null(help_text)) {
    return(text)
  }
  shiny::div(
    class = "input-label-with-help",
    shiny::span(text),
    bslib::tooltip(
      shiny::tags$button(
        type = "button", class = "input-help-button",
        `aria-label` = paste("Information about", text),
        bsicons::bs_icon("info-circle")
      ),
      help_text,
      placement = "right",
      options = list(customClass = "input-help-tooltip")
    )
  )
}

help_action <- function(control, text) {
  bslib::tooltip(control, text, placement = "right")
}

help_header <- function(text, explanation) {
  shiny::div(
    class = "card-header-with-help",
    shiny::span(text),
    shiny::div(
      class = "card-header-actions",
      bslib::tooltip(
        shiny::tags$button(
          type = "button", class = "input-help-button",
          `aria-label` = paste("Information about", text),
          bsicons::bs_icon("info-circle")
        ),
        explanation,
        placement = "left"
      )
    )
  )
}
app_section_header <- function(kicker, title, description) {
  shiny::tags$header(
    class = "app-section-header",
    shiny::div(
      class = "app-section-heading",
      shiny::span(class = "app-section-kicker", kicker),
      shiny::h1(title)
    ),
    shiny::p(description)
  )
}
