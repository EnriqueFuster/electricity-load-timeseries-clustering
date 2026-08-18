theory_validation <- function(entry) {
  list(
    entry("silhouette",
      "Silhouette",
      "Internal metric",
      "Compares within-cluster cohesion with separation from the nearest alternative cluster.",
      "For every meter, compute (b-a)/max(a,b), then average over evaluable meters.",
      paste0(
        "Use as the main internal check of cohesion and separation. It is calculated ",
        "with the distance selected for that experiment."
      ),
      "It can favour convex separation and does not measure business usefulness.",
      "All fitted candidates with at least two non-noise clusters.",
      interpretation = paste0(
        "Near one is separated, near zero overlaps and negative values question ",
        "assignments."
      )
    ),
    entry(
      "stability",
      "Conditional subsample stability",
      "Repeatability evidence",
      paste0(
        "Measures whether the clustering step changes when some meters are removed while ",
        "the already prepared representation is held fixed."
      ),
      paste0(
        "Refit clustering on repeated 80% row subsamples, compare labels for meters shared ",
        "by each pair of fits with adjusted Rand index, then average those comparisons."
      ),
      "Use to identify partitions that depend strongly on which meters are present.",
      paste0(
        "Upstream PCA bases, feature scaling and other learned preprocessing are not ",
        "re-estimated. This is not end-to-end pipeline stability."
      ),
      "All algorithms; failed repetitions indicate an unstable or unsuitable method.",
      "Number of subsamples and seed.",
      "One is agreement up to label permutation; near zero is chance-like."
    ),
    entry("balance",
      "Cluster balance",
      "Structure metric",
      "Smallest non-noise cluster divided by the largest.",
      "Tabulate fitted labels and take min size / max size.",
      "Use as a warning against severe fragmentation or domination.",
      "Real populations can be imbalanced; equality is not inherently correct.",
      "All hard partitions.",
      interpretation = "Treat low balance as an inspection trigger, not automatic invalidity."
    ),
    entry("dunn",
      "Dunn index",
      "Internal metric",
      "Minimum between-cluster separation divided by maximum within-cluster diameter.",
      "Use the candidate distance matrix to compare the closest clusters with the widest cluster.",
      "Use as a supporting check of between-cluster separation.",
      "Very sensitive to extreme observations and unstable tiny clusters.",
      "All candidates with a valid distance matrix.",
      interpretation = "Higher is better, but compare only within coherent experimental settings."
    ),
    entry("runtime",
      "Runtime",
      "Operational metric",
      "Elapsed fitting and validation cost for a candidate.",
      "Measure wall-clock time around fitting, distance construction and stability evaluation.",
      "Use to judge whether a small improvement justifies the extra computation time.",
      "Hardware and caching affect values; runtime is not quality.",
      "All benchmark candidates.",
      interpretation = "Compare orders of magnitude rather than tiny timing differences."
    ),
    entry(
      "gates",
      "Recommendation gates",
      "Decision rule",
      "User-defined thresholds determine eligibility before models are ranked.",
      "Apply minimum cluster share, stability and silhouette plus maximum HDBSCAN noise share.",
      "Use to define minimum acceptance rules without hiding methods that failed.",
      "Thresholds are hypotheses and can exclude meaningful niche groups.",
      "All candidates; noise ceiling is most relevant to HDBSCAN.",
      "All four thresholds are editable in the sidebar."
    ),
    entry(
      "recommendation",
      "Recommendation policy",
      "Decision policy",
      paste0(
        "Ranks candidates that survive the eligibility gates; it does not estimate ",
        "the probability that a clustering is correct."
      ),
      paste0(
        "Within the eligible candidates of this run, silhouette, conditional stability ",
        "and balance are min-max scaled and combined with normalized user weights. The ",
        "policy subtracts 0.01 × K, then uses smaller K and runtime as tie-breakers."
      ),
      "Use the result to decide which candidate to inspect first.",
      paste0(
        "The score is run-relative and cannot be compared across benchmarks with different ",
        "candidate sets. Dunn is not included; runtime is only a late tie-breaker; the K ",
        "penalty is a heuristic, not AIC or BIC."
      ),
      "Every successfully fitted candidate remains available for inspection.",
      "Eligibility gates and three ranking weights.",
      paste0(
        "If a metric is constant across eligible candidates, it contributes the same scaled ",
        "value to all of them and does not discriminate between candidates."
      )
    ),
    entry("profiles",
      "Weekly interpretation profiles",
      "Visual diagnostic",
      "Projects every selected clustering back into a shared weekly visual language.",
      paste0(
        "Assignments from the selected method are joined back to normalized ",
        "typical-week curves; mean interpretation profiles and member dispersion are drawn."
      ),
      "Use to decide whether a numerical cluster has coherent physical morphology.",
      paste0(
        "The mean weekly interpretation profile is not necessarily the fitted prototype: ",
        "PAM uses a medoid, DBA a barycenter, k-Shape a shape centroid and GMM a component model."
      ),
      "Available for every selected clustering result.",
      interpretation = "Inspect timing, peak width, dispersion and exceptional members."
    ),
    entry("pca_plot",
      "PCA diagnostic projection",
      "Visual diagnostic",
      "Projects the active numerical representation into two dimensions for inspection.",
      "A separate PCA is fitted to the active matrix solely for plotting PC1 and PC2.",
      "Use to spot broad overlap, gradients and outlying meters.",
      paste0(
        "Two dimensions can distort separation and this diagnostic PCA is not ",
        "necessarily the fitted representation."
      ),
      "Available when at least two principal components can be estimated.",
      interpretation = "Do not infer proof of clusters from visual gaps alone."
    ),
    entry("dendrogram",
      "Dendrogram",
      "Visual diagnostic",
      "Displays the nested merge structure of the constrained-DTW hierarchical model.",
      "Tree segments encode complete-linkage merges and leaves are coloured by the selected cut.",
      "Use to inspect whether a chosen K corresponds to pronounced branches.",
      "Only meaningful for hierarchical DTW and can become crowded with many profiles.",
      "Hierarchical DTW models.",
      interpretation = "Vertical merge height is dissimilarity, not probability."
    ),
    entry("heatmap",
      "Calendar intensity heatmap",
      "Visual diagnostic",
      "Shows when cluster members tend to be above or below their own average load.",
      paste0(
        "Each hourly reading is divided by that meter's mean consumption first. These ",
        "relative intensities are then averaged by cluster, day of year and hour."
      ),
      "Use to reveal seasonality, operating schedules and missing calendar coverage.",
      paste0(
        "A value of 1 is approximately meter-level average load. Absolute magnitude is ",
        "removed, and an absent cell is not zero consumption."
      ),
      "Available for every selected result using the retained hourly data.",
      interpretation = "Colour is relative intensity; grey denotes no observation."
    ),
    entry("atypicality",
      "Within-cluster atypicality",
      "Visual diagnostic",
      "Ranks meters by mean dissimilarity to peers in their assigned cluster.",
      "Use the selected representation and its corresponding distance where available.",
      "Use to identify edge cases for review and potential data issues.",
      "Atypical does not mean erroneous and large heterogeneous clusters can alter the baseline.",
      "All active hard assignments.",
      interpretation = "Review high values together with raw and weekly curves."
    )
  )
}
