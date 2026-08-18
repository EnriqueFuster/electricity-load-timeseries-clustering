theory_representations <- function(entry) {
  list(
    entry(
      "typical_week",
      "Typical week",
      "Whole series",
      "A 168-coordinate Monday–Sunday curve built with the configured median or mean.",
      paste0(
        "Every accepted observation is assigned to its hour of week and aggregated ",
        "across the selected year. Ordering is preserved."
      ), paste0(
        "Use when recurrent weekly clock-time behaviour is the main signal and ",
        "detailed curves must remain visualizable."
      ), paste0(
        "Seasonal changes and exceptional days are averaged away; adjacent ",
        "coordinates are highly correlated."
      ),
      "Supports Euclidean, PAM, constrained DTW, DTW+DBA, hierarchical DTW, k-Shape and Soft-DTW.",
      "Aggregation statistic and shared normalization.",
      "Inspect whether cluster profiles differ by timing, width and persistence of peaks."
    ),
    entry(
      "seasonal_daypart",
      "Season × day type × time block",
      "Calendar-based features",
      paste0(
        "Forty-eight named consumption features: four meteorological seasons × ",
        "weekday/weekend × six four-hour periods."
      ),
      paste0(
        "For each meter, every hourly reading is assigned to a season, a day type ",
        "and one of the periods 00:00–03:59, 04:00–07:59, 08:00–11:59, ",
        "12:00–15:59, 16:00–19:59 or 20:00–23:59. The selected mean or median is ",
        "calculated within each of the 48 cells."
      ), paste0(
        "Use when the groups must distinguish winter from summer and working days ",
        "from weekends while remaining easy to explain in physical time."
      ), paste0(
        "Four-hour periods smooth narrow peaks. The fixed seasons assume Northern ",
        "Hemisphere timing, and the weekday/weekend split may not represent shift work."
      ),
      paste0(
        "Use feature-space algorithms and Euclidean or Manhattan distance; not ",
        "sequence-warping distances."
      ),
      "Aggregation statistic and shared normalization.",
      paste0(
        "Read every feature as consumption in a named calendar period. Quesada et ",
        "al. (2025) selected the corresponding 24 season × four-hour features; this ",
        "implementation adds weekday/weekend separation as a testable extension."
      )
    ),
    entry(
      "behavioral", "Behavioural and energy features", "Engineered behaviour", paste0(
        "A curated description of magnitude, load factor, variability, peak timing, ",
        "daypart shares and seasonal levels."
      ),
      paste0(
        "The pipeline calculates physically named statistics and standardizes ",
        "every feature across meters."
      ),
      "Use when segment explanations must refer to understandable demand characteristics.",
      paste0(
        "Chosen features encode modelling judgement; correlations can give one ",
        "phenomenon excessive influence."
      ),
      "Suitable for PAM, K-means, SOM, GMM, HDBSCAN and exploratory latent models.",
      "Feature definitions are fixed; clustering hyperparameters remain configurable.",
      paste0(
        "Compare standardized feature distances with summaries in the original ",
        "consumption units before assigning meaning."
      )
    ),
    entry(
      "pca_week",
      "PCA of typical week",
      "Linear reduction",
      "PCA compresses the normalized 168-hour typical week into orthogonal scores.",
      paste0(
        "PCA is fitted across meters and retains the smallest dimension reaching the ",
        "variance target, subject to a maximum-component cap."
      ), paste0(
        "Use to test whether weekly collinearity can be removed without losing ",
        "clustering results."
      ), paste0(
        "Components mix hours, maximize variance rather than separation and can be ",
        "unstable with very small samples."
      ), paste0(
        "Compatible with feature/reduced-space algorithms; elastic distances no ",
        "longer have a time-axis meaning."
      ),
      "Explained-variance target and maximum components.",
      "Inspect retained variance and compare against the unreduced weekly baseline."
    ),
    entry(
      "annual_unit_pca",
      "Annual unit-sum + PCA",
      "Annual reduction",
      "The complete 8,760-hour curve is converted to annual energy shares before PCA.",
      paste0(
        "Each row is divided by its annual total; aligned hourly shares are then ",
        "reduced across meters."
      ),
      paste0(
        "Use when the scientific question concerns when annual energy is allocated, ",
        "independently of total consumption."
      ), paste0(
        "Absolute annual demand disappears and rare low-share hours can contribute ",
        "little to ordinary Euclidean variance."
      ),
      paste0(
        "Use Euclidean or Manhattan distance after reduction; the retained scores are ",
        "not an ordered time series."
      ),
      "PCA variance target and component cap.",
      paste0(
        "Compare with annual z-score and CLR-PCA to determine whether absolute ",
        "hourly deviations or relative energy shares drive the groups."
      )
    ),
    entry(
      "annual_clr_pca",
      "Annual unit-sum + CLR + PCA",
      "Compositional reduction",
      paste0(
        "Hourly annual shares are expressed as log-ratios relative to their ",
        "geometric mean before PCA."
      ),
      paste0(
        "Rows are closed to one, zeros are replaced and reclosed, CLR is applied, ",
        "and PCA reduces the resulting 8,760 coordinates."
      ), paste0(
        "Use when relative allocation between hours is meaningful and compositional ",
        "subparts should be compared through ratios."
      ), paste0(
        "Zero replacement affects very sparse curves; CLR coordinates are singular ",
        "and physically less direct than shares."
      ),
      "Use feature-space algorithms with Euclidean distance between CLR-PCA scores.",
      "Zero-replacement fraction, variance target and component cap.",
      paste0(
        "A positive coordinate means an hour is large relative to that profile’s ",
        "geometric mean, not that kWh is high."
      )
    ),
    entry(
      "annual_z_pca",
      "Annual row z-score + PCA",
      "Annual reduction",
      "Every annual curve is centered and scaled within meter before PCA.",
      paste0(
        "For each row, the annual mean is subtracted and values are divided by the ",
        "annual standard deviation; PCA then learns common shape directions."
      ), "Use for full-calendar morphology when meter level and scale must not drive groups.",
      paste0(
        "Annual magnitude and within-profile volatility level are removed; flat ",
        "profiles need careful handling."
      ),
      "Compatible with feature-space algorithms, not temporal warping after PCA.",
      "PCA variance target and component cap.",
      "Differences represent standardized deviations from each meter’s own annual baseline."
    ),
    entry(
      "catch22_global", "Global catch22", "Generic time-series features", paste0(
        "Twenty-two generic time-series characteristics summarize distributional and ",
        "temporal dynamics over the complete year."
      ), paste0(
        "Rcatch22 extracts selected properties covering autocorrelation, ",
        "predictability, fluctuation and nonlinear structure; columns are ",
        "standardized across meters."
      ), paste0(
        "Use as an unsupervised representation hypothesis. catch22 was selected using ",
        "classification benchmarks, not electricity clustering benchmarks."
      ), paste0(
        "Clock-time location and direct curve reconstruction are lost; ",
        "scale-sensitive mean and standard deviation are intentionally absent."
      ),
      "Feature-space methods only. Requires the optional Rcatch22 package.",
      "No extraction parameter; downstream clustering parameters still apply.",
      paste0(
        "Interpret feature families cautiously and compare against an explainable ",
        "behavioural-feature baseline."
      )
    ),
    entry(
      "catch22_seasonal",
      "Seasonal catch22",
      "Canonical features",
      "Four ordered catch22 blocks describe changes in temporal dynamics between seasons.",
      paste0(
        "Winter is reordered December → January → February to preserve cyclic adjacency; ",
        "22 features are extracted from each seasonal block and standardized."
      ), "Use when a global feature could hide contrasting seasonal dynamics.", paste0(
        "The 88-dimensional result needs enough meters and multiplies correlated or ",
        "noisy feature estimates."
      ),
      "Feature-space algorithms only. Requires Rcatch22 and a complete annual curve.",
      "Fixed meteorological seasons.",
      "Compare global and seasonal variants while holding algorithm and distance constant."
    ),
    entry(
      "catch24_seasonal", "Seasonal catch24", "Canonical + level", paste0(
        "Seasonal catch22 is augmented with mean and standard deviation in every ",
        "season, yielding up to 96 features."
      ), paste0(
        "The same four seasonal blocks are extracted, then elementary location and ",
        "dispersion statistics are appended before feature-wise scaling."
      ), "Use when both dynamics and seasonal demand level should influence segmentation.", paste0(
        "Mean and standard deviation can dominate if they duplicate other magnitude ",
        "signals; dimensionality is relatively high."
      ), "Feature-space algorithms only and requires Rcatch22.",
      "Fixed seasons; no catch22 tuning parameter.", paste0(
        "A controlled comparison with seasonal catch22 reveals what restored level ",
        "and dispersion contribute."
      )
    )
  )
}
