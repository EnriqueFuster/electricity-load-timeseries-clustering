theory_algorithms <- function(entry) {
  list(
    entry(
      "kmeans", "K-means", "Centroid partitioning",
      "Fast Euclidean baseline around arithmetic centroids.", paste0(
        "Alternate assignment to the nearest centroid and recomputation of ",
        "coordinate means until convergence."
      ),
      "Use for compact approximately spherical groups and as the mandatory simple baseline.",
      "Requires K; sensitive to initialization and outliers; requires Euclidean distance.",
      "Euclidean-compatible representations.",
      "K, random seed and repeated starts.",
      "Centroids are synthetic means and may not resemble an observed meter."
    ),
    entry(
      "pam",
      "PAM / K-medoids",
      "Medoid partitioning",
      paste0(
        "Partitions observations around real representative meters while accepting ",
        "precomputed dissimilarities."
      ),
      "PAM swaps candidate medoids to minimize total dissimilarity to the nearest medoid.",
      paste0(
        "Use when robustness and an observed representative are important or when ",
        "distance is not Euclidean."
      ),
      "Requires K and pairwise distances can be expensive for large samples.",
      "Experiments using Euclidean, Manhattan or constrained DTW distance.",
      "K and selected distance.",
      "Inspect each medoid and compare it with the synthetic mean profile."
    ),
    entry(
      "dtw_dba",
      "DTW + DBA",
      "Elastic partitioning",
      paste0(
        "Partitional time-series clustering with elastic assignment and aligned ",
        "barycentre prototypes."
      ),
      paste0(
        "Profiles are assigned using constrained DTW; DTW Barycenter Averaging ",
        "updates a prototype through aligned coordinates."
      ),
      "Use for shifted but morphologically similar weekly curves.",
      "Requires K, initialization and a defensible warping window; computation is substantial.",
      "Normalized ordered whole-series representations.",
      "K, seed and DTW window.",
      "The DBA prototype is an aligned synthetic curve, not a pointwise average."
    ),
    entry(
      "hierarchical",
      "Hierarchical DTW",
      "Hierarchical",
      "Builds a complete-linkage tree from constrained-DTW dissimilarities.",
      paste0(
        "Start with singleton meters and repeatedly merge the pair of groups with ",
        "the smallest maximum cross-group dissimilarity."
      ),
      "Use when nested structure and a dendrogram are valuable.",
      paste0(
        "Early merges cannot be revised and complete linkage is sensitive to ",
        "extreme pairwise distances."
      ),
      "Ordered weekly curves with constrained DTW.",
      "DTW window and the final tree cut K.",
      "Branch height is merge dissimilarity, not probability or energy."
    ),
    entry(
      "kshape",
      "k-Shape",
      "Shape partitioning",
      "Groups normalized time-series morphology using SBD and shape centroids.",
      paste0(
        "Iterative assignment uses normalized cross-correlation; centroid extraction ",
        "solves a shape-alignment problem."
      ),
      "Use when scale and phase are secondary to curve morphology.",
      "Requires K and can hide meaningful clock-time displacement.",
      paste0(
        "Ordered whole series. This implementation explicitly applies row-wise z-normalization ",
        "inside the k-Shape wrapper regardless of upstream scale."
      ),
      "K and random seed.",
      "Compare shape centroids with clock-time profiles before operational interpretation."
    ),
    entry(
      "som",
      "Self-organising map",
      "Approximate neighbourhood preservation",
      "Learns a two-dimensional codebook map and groups its nodes into final clusters.",
      paste0(
        "Competitive learning moves a winning unit and its neighbours toward each ",
        "input; codebook vectors are then clustered."
      ), "Use to explore nonlinear neighbourhood structure and gradual transitions.", paste0(
        "Results depend on map size, learning schedule and initialization; the final ",
        "hard partition adds another modelling layer."
      ),
      "Feature and reduced representations.",
      "Training iterations, seed and final K.",
      "Neighbouring map units indicate similarity even when assigned to different final clusters."
    ),
    entry(
      "gmm",
      "Gaussian mixture model",
      "Probabilistic",
      "Models observations as a mixture of Gaussian component densities.",
      paste0(
        "Maximum likelihood estimates component means, covariance structures and ",
        "mixing proportions; posterior probability determines assignment."
      ),
      paste0(
        "Use when probabilistic membership is useful and spherical or axis-aligned ",
        "diagonal Gaussian components are defensible."
      ),
      "Gaussian and covariance assumptions are fragile in high dimensions and small samples.",
      "Reduced or feature representations; internal PCA may protect covariance estimation.",
      "Candidate K and covariance-model selection.",
      "Inspect posterior uncertainty instead of treating every hard label as equally certain."
    ),
    entry(
      "hdbscan",
      "HDBSCAN",
      "Density based",
      "Finds persistent density-connected clusters and can mark observations as noise.",
      paste0(
        "Mutual-reachability distances create a density hierarchy from which ",
        "stable groups are extracted."
      ),
      paste0(
        "Use to investigate persistent density-connected groups and explicit noise ",
        "without fixing K."
      ),
      paste0(
        "Results can be sensitive to min-points; sparse high-dimensional spaces ",
        "may appear mostly noise."
      ),
      "Reduced/feature matrices with Euclidean or Manhattan distance.",
      "Minimum points and maximum acceptable noise share.",
      "Cluster 0 is unassigned noise, not a normal behavioural segment."
    ),
    entry(
      "soft_cluster",
      "Soft-DTW clustering",
      "Elastic partitioning",
      "Uses Soft-DTW dissimilarity and smooth elastic prototypes.",
      "Candidate groups are optimized using the gamma-smoothed alignment objective.",
      "Use as an elastic methodological extension against hard DTW baselines.",
      paste0(
        "Runtime and gamma sensitivity require scrutiny; the implementation is ",
        "restricted to whole series."
      ),
      "Ordered normalized typical-week curves.",
      "K, gamma and seed.",
      "Improvements should be material enough to justify added complexity."
    ),
    entry(
      "deep",
      "Autoencoder + K-means",
      "Learned representation",
      "A neural network compresses and reconstructs inputs; K-means clusters the latent codes.",
      paste0(
        "The encoder and decoder minimize reconstruction loss, after which ",
        "conventional K-means is fitted in the latent layer."
      ), paste0(
        "Use as an exploratory nonlinear reduction hypothesis with enough data and ",
        "strong baselines."
      ), paste0(
        "Needs Torch, tuning and larger samples; reconstruction quality does not ",
        "guarantee cluster quality and this is not joint DEC."
      ),
      "Feature or reduced input matrices.",
      "Latent dimensions, epochs, seed and K.",
      paste0(
        "Report it as exploratory autoencoder compression followed by K-means, ",
        "not generically as ‘deep clustering’."
      )
    )
  )
}
