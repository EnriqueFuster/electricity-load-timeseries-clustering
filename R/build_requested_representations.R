#' Build only the representations requested by the experiment grid
#' @param clean Clean hourly observations.
#' @param typical_week Long typical-week table already used for interpretation.
#' @param requested Character vector of representation identifiers.
#' @param preprocessing Preprocessing configuration.
#' @param verbose Print representation-level progress messages.
#' @return List containing matrices and an auditable metadata table.
build_requested_representations <- function(
  clean, typical_week, requested, preprocessing,
  verbose = TRUE
) {
  supported <- c(
    "typical_week", "day_type_hour", "seasonal_daypart", "behavioral_features",
    "pca_typical_week", "pca_annual_unit_sum", "pca_annual_clr", "pca_annual_zscore",
    "catch22_global", "catch22_seasonal", "catch24_seasonal"
  )
  unsupported <- setdiff(requested, supported)
  if (length(unsupported)) stop("Unsupported representation: ", paste(unsupported, collapse = ", "))

  pca_variance <- preprocessing$pca_explained_variance %||% 0.95
  pca_max <- preprocessing$pca_max_components %||% 30L
  zero_fraction <- preprocessing$clr_zero_replacement_fraction %||% 0.5
  weekly_raw <- representation_to_matrix(typical_week)
  weekly_normalized <- normalize_load_curve(weekly_raw, preprocessing$normalization)
  matrices <- list()

  add_matrix <- function(name, value) matrices[[name]] <<- value
  announce <- function(text) if (isTRUE(verbose)) message("  Representation: ", text)

  if ("typical_week" %in% requested) add_matrix("typical_week", weekly_normalized)

  if ("day_type_hour" %in% requested) {
    announce("weekday/weekend hourly profile")
    profile <- build_day_type_hour_profile(clean, preprocessing$aggregation)
    add_matrix("day_type_hour", normalize_load_curve(
      representation_to_matrix(profile[c("series_id", "feature_index", "value")]),
      preprocessing$normalization
    ))
  }
  if ("seasonal_daypart" %in% requested) {
    announce("season, day-type and four-hour blocks")
    profile <- build_seasonal_daypart_profile(clean, preprocessing$aggregation)
    add_matrix("seasonal_daypart", normalize_load_curve(
      feature_table_to_matrix(profile[c("series_id", "feature_index", "value")]),
      preprocessing$normalization
    ))
  }
  if ("behavioral_features" %in% requested) {
    announce("interpretable behavioural features")
    add_matrix("behavioral_features", build_behavioral_feature_matrix(clean))
  }
  if ("pca_typical_week" %in% requested) {
    announce("PCA of the normalized typical week")
    add_matrix("pca_typical_week", build_pca_score_matrix(weekly_normalized, pca_variance, pca_max))
  }

  annual_names <- c(
    "pca_annual_unit_sum", "pca_annual_clr", "pca_annual_zscore",
    "catch22_global", "catch22_seasonal", "catch24_seasonal"
  )
  annual_matrix <- NULL
  if (any(annual_names %in% requested)) {
    announce("aligning complete years to a common 8,760-hour calendar")
    annual_matrix <- build_annual_hourly_matrix(clean)
  }
  if ("pca_annual_unit_sum" %in% requested) {
    announce("unit-sum annual curve followed by PCA")
    closed <- close_annual_composition(annual_matrix)
    add_matrix("pca_annual_unit_sum", build_pca_score_matrix(closed, pca_variance, pca_max))
  }
  if ("pca_annual_clr" %in% requested) {
    announce("unit-sum, zero replacement, CLR and PCA")
    closed <- close_annual_composition(annual_matrix)
    clr <- apply_clr_transform(replace_compositional_zeros(closed, zero_fraction))
    add_matrix("pca_annual_clr", build_pca_score_matrix(clr, pca_variance, pca_max))
  }
  if ("pca_annual_zscore" %in% requested) {
    announce("row-wise z-score annual curve followed by PCA")
    standardized <- normalize_load_curve(annual_matrix, "zscore")
    add_matrix("pca_annual_zscore", build_pca_score_matrix(standardized, pca_variance, pca_max))
  }
  if ("catch22_global" %in% requested) {
    announce("global catch22 features")
    add_matrix("catch22_global", build_catch22_feature_matrix(annual_matrix))
  }
  if ("catch22_seasonal" %in% requested) {
    announce("seasonal catch22 features")
    add_matrix("catch22_seasonal", build_catch22_feature_matrix(annual_matrix, seasonal = TRUE))
  }
  if ("catch24_seasonal" %in% requested) {
    announce("seasonal catch22 features with mean and standard deviation")
    add_matrix("catch24_seasonal", build_catch22_feature_matrix(
      annual_matrix,
      seasonal = TRUE, include_mean_sd = TRUE
    ))
  }

  metadata_catalog <- data.frame(
    representation = supported,
    representation_family = c(
      "whole-series", rep("feature-based", 3), "transformation-based",
      rep("transformation-based", 3), rep("feature-based", 3)
    ),
    base_representation = c(
      "typical_week", "day_type_hour", "seasonal_daypart", "behavioural_summary",
      "typical_week", rep("annual_8760", 6)
    ),
    normalization = c(
      rep(preprocessing$normalization, 3), "feature_zscore",
      preprocessing$normalization, "unit_sum", "unit_sum", "row_zscore",
      rep("feature_zscore", 3)
    ),
    transformation = c(
      rep("none", 5), "none", "clr", "none", "catch22", "seasonal_catch22",
      "seasonal_catch24"
    ),
    dimensionality_reduction = c(rep("none", 4), rep(paste0("pca_", pca_variance), 4), rep(
      "none",
      3
    )),
    stringsAsFactors = FALSE
  )
  metadata <- metadata_catalog[match(names(matrices), metadata_catalog$representation), ,
    drop = FALSE
  ]
  list(matrices = matrices, metadata = metadata, weekly_raw = weekly_raw)
}
