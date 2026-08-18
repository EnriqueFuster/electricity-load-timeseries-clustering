get_learning_taxonomy <- function() {
  catalog <- get_theory_catalog()
  entry <- theory_entry
  find_entry <- function(section, id) {
    entries <- catalog[[section]]
    entries[[match(id, vapply(entries, `[[`, character(1), "id"))]]
  }
  pick_entries <- function(section, ids) lapply(ids, function(id) find_entry(section, id))

  temporal_entries <- list(
    entry("weekly_basis", "Typical-week basis", "Temporal representation", paste0(
      "Align the natural year by UTC weekday and hour, then represent recurrent ",
      "behaviour on a Monday-to-Sunday analytical clock."
    ), paste0(
      "Each observation is assigned to one of 168 positions. Repeated observations ",
      "at the same position are summarized in the next stage."
    ), paste0(
      "Use when recurrent weekly schedules matter more than exact dates and UTC calendar ",
      "grouping is acceptable for the study."
    ),
    "Seasonal contrasts and exceptional dates are deliberately collapsed.",
    "Enables typical-week, weekly PCA and ordered time-series experiments.",
    interpretation = paste0(
      "This defines the calendar grid; it does not yet choose mean versus median ",
      "or normalize consumption."
    )
    ),
    entry("annual_basis", "Complete-year hourly basis", "Temporal representation", paste0(
      "Retain the UTC-aligned January-to-December sequence of 8,760 hourly coordinates ",
      "for every accepted meter."
    ), paste0(
      "Quality-controlled natural years are aligned to a common hourly calendar; ",
      "leap-day observations are removed for equal-length matrices."
    ),
    "Use when seasonality, holidays and annual timing form part of the research question.",
    "It is high-dimensional and requires genuinely complete annual histories.",
    "Enables annual unit-sum, CLR or row-z-score preparation followed by PCA.",
    interpretation = paste0(
      "Each coordinate remains a specific UTC common-calendar hour until a later ",
      "reduction is applied. The selected input timezone parses timestamps but does not ",
      "change this downstream UTC calendar policy."
    )
    ),
    entry("seasonal_basis", "Season × day type × time block", "Temporal representation", paste0(
      "Organize the year into interpretable calendar cells combining season, ",
      "weekday/weekend status and hour block."
    ), paste0(
      "Every timestamp is mapped to one of four seasons, two day types and six ",
      "four-hour blocks before repeated cells are summarized."
    ),
    "Use when compact, named calendar effects are preferable to thousands of hourly coordinates.",
    "Fixed seasons and broad blocks can hide narrow peaks.",
    "Builds the seasonal-daypart engineered representation.",
    interpretation = "This is an aggregation grid, not an elastic time-series distance."
    ),
    entry("behavioural_basis", "Behavioural feature basis", "Temporal representation", paste0(
      "Describe each annual meter history through physically meaningful attributes ",
      "rather than a retained clock-time sequence."
    ), paste0(
      "Annual, seasonal and daypart summaries become load factor, variability, ",
      "timing and energy-share descriptors."
    ),
    "Use when explanations must map directly to operational or energy-domain quantities.",
    "Feature selection embeds analyst judgement and discards the ordered curve.",
    "Builds the behavioural-feature representation for feature-space clustering.",
    interpretation = "Adjacent output columns are named attributes, not adjacent hours."
    )
  )
  aggregation_entries <- list(
    entry("median_aggregation",
      "Median of repeated hours",
      "Hourly aggregation statistic",
      "Use the median observation in each repeated calendar position.",
      "For every meter and calendar cell, sort available values and take the central value.",
      paste0(
        "Choose it when the intended coordinate is the typical repeated level and ",
        "isolated extremes should have limited influence."
      ),
      "It can suppress genuine infrequent peaks and does not preserve total energy.",
      "Applies where the temporal basis contains repeated hourly cells.",
      interpretation = "The coordinate is a typical central level, not interval energy."
    ),
    entry("mean_aggregation",
      "Mean of repeated hours",
      "Hourly aggregation statistic",
      "Use the arithmetic mean observation in each repeated calendar position.",
      "Sum all values in the same meter and calendar cell and divide by their count.",
      "Use when every occurrence should contribute proportionally and average level is meaningful.",
      "Outliers and exceptional days influence it more strongly than the median.",
      "Applies where the temporal basis contains repeated hourly cells.",
      interpretation = "The result is the empirical arithmetic mean for that calendar position."
    )
  )

  list(
    foundations = catalog$foundations,
    temporal = temporal_entries,
    aggregation = aggregation_entries,
    normalization = pick_entries("similarity", c("zscore", "unit_sum", "none")),
    transformation = c(
      pick_entries(
        "representations",
        c(
          "typical_week",
          "pca_week",
          "annual_unit_pca",
          "annual_clr_pca",
          "annual_z_pca",
          "seasonal_daypart",
          "behavioral",
          "catch22_global",
          "catch22_seasonal",
          "catch24_seasonal"
        )
      ),
      pick_entries(
        "similarity",
        "clr"
      )
    ),
    algorithms = catalog$algorithms,
    distance = pick_entries("similarity", c(
      "euclidean", "manhattan", "dtw", "sbd", "soft_dtw",
      "derived"
    )),
    validation = catalog$validation
  )
}

# Longer teaching notes complement the concise catalogue. They deliberately
# answer the questions a first-time reader asks: what enters the method, what
# happens to it, what comes out, and what nearby option would answer differently.
