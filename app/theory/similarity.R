theory_similarity <- function(entry) {
  list(
    entry("zscore",
      "Z-score per profile",
      "Normalization",
      "Centers and scales every profile independently, prioritizing shape over level.",
      "Subtract the row mean and divide by its standard deviation.",
      paste0(
        "Use when consumers with similar relative shapes should be close despite ",
        "different kWh levels."
      ),
      "Removes absolute magnitude and can amplify tiny fluctuations in nearly flat curves.",
      "Used before whole-series and selected calendar representations.",
      interpretation = "Distances describe standardized shape deviations."
    ),
    entry("unit_sum",
      "Unit-sum normalization",
      "Normalization",
      "Converts coordinates into shares of total represented energy.",
      "Divide each row by its positive sum.",
      "Use when relative temporal allocation matters but total demand should not.",
      paste0(
        "Requires positive annual consumption. Unlike CLR, it compares hourly shares ",
        "directly rather than comparing their log-ratios."
      ),
      "Available for weekly/calendar representations and embedded in annual unit-sum PCA.",
      interpretation = "Coordinates sum to one and are read as energy shares."
    ),
    entry(
      "none",
      "No normalization",
      "Normalization",
      "Retains both magnitude and shape in the representation’s original scale.",
      "The numerical matrix is passed through unchanged.",
      "Use when absolute demand is genuinely part of the segmentation question.",
      "Large consumers and high-variance coordinates can dominate distance.",
      "Compatible with pointwise representations; algorithm assumptions still apply."
    ),
    entry(
      "clr",
      "Centred log-ratio",
      "Transformation",
      "Maps a positive composition to log-ratios against its geometric mean.",
      paste0(
        "For each share p, compute log(p) minus the mean log share after ",
        "documented zero replacement."
      ),
      "Use for relative comparisons between compositional parts.",
      "Undefined at zero, sensitive to replacement choices, and not equivalent to z-score.",
      "Implemented in annual CLR-PCA before dimensionality reduction.",
      "Zero-replacement fraction.",
      "Only ratios between coordinates are meaningful."
    ),
    entry(
      "euclidean",
      "Euclidean distance",
      "Lock-step distance",
      "Square-root of summed squared coordinate differences.",
      paste0(
        "Matching coordinates are compared directly. Residuals are squared inside the ",
        "Euclidean norm; K-means minimizes squared Euclidean distance."
      ),
      "Use for aligned, similarly scaled coordinates and compact geometric clusters.",
      "Sensitive to scale, outliers and small peak shifts.",
      "Required by classical K-means; also used by PAM, SOM and HDBSCAN."
    ),
    entry(
      "manhattan",
      "Manhattan distance",
      "Lock-step distance",
      "Sum of absolute coordinate differences.",
      "Matching coordinates contribute linearly to total dissimilarity.",
      paste0(
        "Use when isolated large deviations should have less influence than under ",
        "Euclidean distance."
      ),
      "Still assumes coordinate alignment and can suffer in high dimensions.",
      "Implemented with PAM and HDBSCAN on compatible representations."
    ),
    entry(
      "dtw",
      "Constrained DTW",
      "Elastic distance",
      "Aligns nearby temporal events before accumulating mismatch.",
      "Dynamic programming searches monotone alignments inside a Sakoe–Chiba window.",
      "Use when similar load shapes can be shifted by a plausible number of hours.",
      "Computationally expensive; excessive warping can erase meaningful clock time.",
      "Whole ordered weekly series with PAM, DBA or hierarchical clustering.",
      "Warping-window size in hours.",
      "Inspect alignments conceptually: closeness no longer means equality at the same clock hour."
    ),
    entry(
      "sbd",
      "Shape-based distance",
      "Shift-aware similarity",
      "Uses normalized cross-correlation to compare morphology while allowing phase shift.",
      "The best normalized cross-correlation over shifts is converted into dissimilarity.",
      "Use when overall shape matters more than exact phase and magnitude.",
      "May treat shifts in peak time as equivalent even when tariff periods differ.",
      "Used by k-Shape on normalized ordered series."
    ),
    entry(
      "soft_dtw",
      "Soft-DTW",
      "Elastic distance",
      "A differentiable relaxation that smoothly aggregates alternative DTW paths.",
      "A soft minimum controlled by gamma replaces the hard minimum in the DTW recurrence.",
      "Use to test smoother elastic alignment and barycentre estimation.",
      "Slower than lock-step metrics; raw Soft-DTW is not necessarily zero on identical inputs.",
      "Implemented for ordered whole-series clustering.",
      "Gamma controls smoothness."
    ),
    entry("derived", "Model-based and latent similarity", "Model-derived similarity", paste0(
      "Some methods compare profiles through a probability model or a learned compact ",
      "representation rather than through a separately selected distance."
    ), paste0(
      "GMM fitting uses component likelihood, while common validation compares observations ",
      "in the fitted feature embedding. Autoencoder clustering applies Euclidean distance after compression."
    ),
    "Use only when the complete method and its assumptions are evaluated explicitly.",
    "Distances from different learned spaces are not physically interchangeable.",
    "GMM and autoencoder-based clustering.",
    interpretation = paste0(
      "Interpret membership confidence or latent separation alongside simple ",
      "baselines."
    )
    )
  )
}
