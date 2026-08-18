get_theory_academic_profile <- function(entry) {
  equations <- c(
    median_aggregation = "m_ih = median{x_it : calendar_position(t) = h}",
    mean_aggregation = "m_ih = (1/n_ih) sum_{t: calendar_position(t)=h} x_it",
    zscore = "z_it = (x_it - mean_i) / sd_i",
    unit_sum = "p_it = x_it / sum_t(x_it),  with  sum_t(p_it) = 1",
    clr = "clr(p_it) = log(p_it) - (1/T) sum_s log(p_is) = log(p_it / g(p_i))",
    euclidean = "d_2(x,y) = sqrt(sum_t (x_t - y_t)^2)",
    manhattan = "d_1(x,y) = sum_t |x_t - y_t|",
    dtw = "DTW(x,y) = min_{A in alignments} sum_(i,j in A) c(x_i,y_j)",
    sbd = "SBD(x,y) = 1 - max_shift NCC(x, shift(y))",
    soft_dtw = "softDTW_gamma(x,y) = -gamma log sum_A exp(-cost(A)/gamma)",
    kmeans = "min_{C,mu} sum_k sum_{i in C_k} ||x_i - mu_k||^2",
    pam = "min_{m_1,...,m_K in data} sum_i min_k d(x_i,m_k)",
    dtw_dba = paste0(
      "Assignment minimizes DTW; DBA updates each prototype from coordinates ",
      "aligned to it."
    ),
    hierarchical = "Complete linkage: D(A,B) = max_{i in A, j in B} d(i,j)",
    kshape = "Assignment minimizes SBD; centroids maximize aligned normalized cross-correlation.",
    som = "m_c <- m_c + alpha(t) h_(winner,c)(t) [x - m_c]",
    gmm = "p(x_i) = sum_k pi_k N(x_i | mu_k, Sigma_k);  z_i = argmax_k P(k|x_i)",
    hdbscan = "d_mreach(a,b) = max{core_k(a), core_k(b), d(a,b)}",
    soft_cluster = "min_{C,mu} sum_k sum_{i in C_k} softDTW_gamma(x_i,mu_k)",
    deep = "min_theta sum_i ||x_i - decoder(encoder(x_i))||^2; then K-means on z_i",
    silhouette = "s(i) = [b(i)-a(i)] / max{a(i),b(i)}",
    stability = "ARI corrects pairwise partition agreement for agreement expected by chance.",
    balance = "balance = min_k n_k / max_k n_k",
    dunn = "Dunn = min_{k != l} delta(C_k,C_l) / max_k diameter(C_k)",
    pca_week = "X = U D V'; scores = X V_q, with q chosen by cumulative explained variance.",
    annual_unit_pca = "p_it = x_it / sum_t x_it; then PCA(p_i1,...,p_i8760)",
    annual_clr_pca = "p_i -> zero replacement -> clr(p_i) -> PCA scores",
    annual_z_pca = "x_i -> row z-score(x_i) -> PCA scores",
    recommendation = paste0(
      "score = w_s silhouette_scaled + w_r stability_scaled + w_b balance_scaled ",
      "- K penalty"
    )
  )

  implementations <- c(
    weekly_basis = paste0(
      "base::weekdays(), base::as.POSIXlt() and base::interaction() provide ",
      "official primitives for constructing weekday-by-hour positions."
    ),
    annual_basis = paste0(
      "base::seq.POSIXt(), base::as.POSIXct() and base::format() provide the ",
      "aligned hourly calendar used to index a natural year."
    ),
    seasonal_basis = paste0(
      "base::cut(), base::weekdays() and base::interaction() construct season, ",
      "day-type and time-block cells before aggregation."
    ),
    behavioural_basis = paste0(
      "stats::aggregate(), stats::quantile(), stats::sd() and base::mean() provide ",
      "official primitives for named demand attributes."
    ),
    median_aggregation = paste0(
      "stats::median() calculates a centre with limited sensitivity to isolated ",
      "extreme values within each repeated meter-by-calendar cell."
    ),
    mean_aggregation = paste0(
      "base::mean() calculates the arithmetic centre within every repeated ",
      "meter-by-calendar cell."
    ),
    unit = paste0(
      "Useful official R primitives are stats::aggregate(), stats::median() and ",
      "base::split(); the statistical unit must still be defined by the study ",
      "design."
    ),
    question = paste0(
      "No library function decides the scientific meaning of similarity. R ",
      "functions only execute the representation, distance and model specified by ",
      "the analyst."
    ),
    layers = paste0(
      "Typical official building blocks include stats::scale(), stats::prcomp(), ",
      "stats::dist(), stats::kmeans() and cluster::pam()."
    ),
    quality = paste0(
      "Relevant official tools include base::duplicated(), ",
      "stats::complete.cases(), stats::approx() and time-zone-aware base date-time ",
      "functions."
    ),
    evidence = paste0(
      "Official validation functions include cluster::silhouette(); resampling ",
      "agreement can be computed with mclust::adjustedRandIndex()."
    ),
    typical_week = paste0(
      "stats::aggregate() and stats::median() or base::mean() provide the core ",
      "repeated-hour aggregation operations."
    ),
    seasonal_daypart = paste0(
      "stats::aggregate() supports season × day-type × block summaries after the ",
      "calendar factors have been constructed."
    ),
    behavioral = paste0(
      "stats::quantile(), stats::sd(), stats::median() and stats::aggregate() are ",
      "standard tools for engineered load descriptors."
    ),
    pca_week = paste0(
      "stats::prcomp() estimates PCA scores, loadings and explained standard ",
      "deviations from the prepared weekly matrix."
    ),
    annual_unit_pca = paste0(
      "base::rowSums() closes rows to unit sum and stats::prcomp() performs the ",
      "linear reduction."
    ),
    annual_clr_pca = paste0(
      "compositions::clr() is the reference R implementation of the centred ",
      "log-ratio; stats::prcomp() then reduces CLR coordinates."
    ),
    annual_z_pca = paste0(
      "base::scale() performs centring/scaling and stats::prcomp() estimates the ",
      "annual shape components."
    ),
    catch22_global = paste0(
      "Rcatch22::catch22_all() calculates the canonical feature set; base::scale() ",
      "standardizes features across meters."
    ),
    catch22_seasonal = paste0(
      "Rcatch22::catch22_all() is applied independently to each seasonal ",
      "subsequence before feature-wise scaling."
    ),
    catch24_seasonal = paste0(
      "Rcatch22::catch22_all(), base::mean() and stats::sd() form the catch24 ",
      "extension."
    ),
    daily_dictionary = paste0(
      "A reference implementation can combine stats::kmeans() or cluster::pam() ",
      "for daily archetypes with a second clustering stage on meter-level ",
      "frequencies."
    ),
    zscore = paste0(
      "base::scale() is the standard R function for centring and scaling; row-wise ",
      "use requires applying it separately to each profile."
    ),
    unit_sum = paste0(
      "base::rowSums() supplies the denominator for converting non-negative rows ",
      "into energy shares."
    ),
    none = paste0(
      "No transformation function is required; the prepared numeric matrix is ",
      "passed directly to the selected distance or model."
    ),
    clr = paste0(
      "compositions::clr() provides the formal CLR map. Zeros must be replaced and ",
      "the composition reclosed before calling it."
    ),
    euclidean = paste0(
      "stats::dist(method='euclidean') computes pairwise distances; ",
      "stats::kmeans() optimizes squared Euclidean geometry."
    ),
    manhattan = paste0(
      "stats::dist(method='manhattan') computes L1 dissimilarities; ",
      "cluster::pam() can consume them."
    ),
    dtw = "dtwclust::dtw_basic() computes DTW dissimilarity and accepts a Sakoe–Chiba window.",
    sbd = "dtwclust::sbd() and dtwclust::tsclust() for k-Shape clustering.",
    soft_dtw = paste0(
      "dtwclust::sdtw() supplies the smoothed elastic dissimilarity used by the ",
      "Soft-DTW clustering method."
    ),
    derived = paste0(
      "mclust::Mclust() exposes posterior mixture membership; torch modules ",
      "provide learned encoders whose codes can be passed to stats::kmeans()."
    ),
    kmeans = paste0(
      "stats::kmeans() provides Lloyd, Forgy, MacQueen and Hartigan–Wong variants ",
      "with configurable centres, starts and iterations."
    ),
    pam = paste0(
      "cluster::pam() accepts a numeric matrix or a precomputed dissimilarity ",
      "object and returns medoids and assignments."
    ),
    dtw_dba = paste0(
      "dtwclust::tsclust(type='partitional', distance='dtw_basic', ",
      "centroid='dba') implements elastic assignment with DBA prototypes."
    ),
    hierarchical = paste0(
      "stats::hclust(method='complete') and stats::cutree() operate on a DTW ",
      "dissimilarity supplied by dtwclust::dtw_basic()."
    ),
    kshape = paste0(
      "dtwclust::tsclust() with distance='sbd' and centroid='shape' implements ",
      "k-Shape-style partitioning."
    ),
    som = paste0(
      "kohonen::supersom() trains the map; codebook vectors can subsequently be ",
      "grouped with stats::kmeans()."
    ),
    gmm = "mclust::Mclust() performs EM estimation and covariance-model selection using BIC.",
    hdbscan = paste0(
      "dbscan::hdbscan() returns cluster labels, membership probabilities, outlier ",
      "scores and the density hierarchy."
    ),
    soft_cluster = paste0(
      "dtwclust::tsclust() can combine dtwclust::sdtw() with Soft-DTW centroid ",
      "estimation."
    ),
    deep = paste0(
      "torch::nn_module() defines encoder/decoder networks; torch::optim_adam() ",
      "trains them and stats::kmeans() clusters latent codes."
    ),
    silhouette = paste0(
      "cluster::silhouette() computes observation-level and average silhouette ",
      "widths from labels and dissimilarities."
    ),
    stability = paste0(
      "mclust::adjustedRandIndex() compares repeated partitions while correcting ",
      "agreement expected by chance."
    ),
    balance = paste0(
      "base::table(), base::min() and base::max() calculate the ",
      "smallest-to-largest cluster-size ratio."
    ),
    dunn = paste0(
      "clusterCrit::intCriteria(crit='Dunn') is a standard R implementation for ",
      "Euclidean feature matrices."
    ),
    runtime = "base::system.time() or base::proc.time() measure elapsed computational cost.",
    gates = paste0(
      "base::which() and base::rank() support threshold eligibility and ordering; ",
      "no specialized clustering library function is required."
    ),
    profiles = paste0(
      "stats::quantile() computes profile envelopes and ggplot2::geom_ribbon() ",
      "displays them around ggplot2::geom_line()."
    ),
    pca_plot = paste0(
      "stats::prcomp() creates the diagnostic projection; ggplot2::geom_point() ",
      "displays the first two scores."
    ),
    dendrogram = paste0(
      "stats::hclust(), stats::as.dendrogram() and stats::cutree() provide the ",
      "official hierarchy objects and tree cut."
    ),
    heatmap = paste0(
      "stats::aggregate() prepares day × hour cells; ggplot2::geom_tile() or ",
      "plotly::plot_ly(type='heatmap') renders intensity."
    ),
    atypicality = paste0(
      "stats::dist() supplies lock-step dissimilarities; row-wise summaries rank ",
      "distance from cluster peers."
    ),
    recommendation = paste0(
      "base::rank() and base::scale() can combine eligible validation scores after ",
      "applying explicit thresholds."
    ),
    controlled = paste0(
      "No package function guarantees a controlled benchmark; the analyst must ",
      "hold all non-tested layers and random seeds constant."
    )
  )

  reference_sets <- list(
    time_series = list(
      c(
        "dtwclust: time-series clustering reference",
        "https://search.r-project.org/CRAN/refmans/dtwclust/html/tsclust.html"
      ),
      c(
        "Aghabozorgi et al. (2015), Time-series clustering review",
        "https://doi.org/10.1016/j.is.2015.04.007"
      )
    ),
    classical = list(
      c("R stats: kmeans", "https://stat.ethz.ch/R-manual/R-devel/library/stats/html/kmeans.html"),
      c("R cluster: PAM", "https://search.r-project.org/CRAN/refmans/cluster/html/pam.html")
    ),
    features = list(
      c("Lubba et al. (2019), catch22", "https://doi.org/10.1007/s10618-019-00647-x"),
      c("Rcatch22 package manual", "https://stat.ethz.ch/CRAN/web/packages/Rcatch22/Rcatch22.pdf")
    ),
    soft_dtw = list(
      c("Cuturi & Blondel (2017), Soft-DTW", "https://proceedings.mlr.press/v70/cuturi17a.html"),
      c(
        "dtwclust: Soft-DTW implementation",
        "https://search.r-project.org/CRAN/refmans/dtwclust/html/sdtw.html"
      )
    ),
    density = list(c(
      "R dbscan: HDBSCAN",
      "https://search.r-project.org/CRAN/refmans/dbscan/html/hdbscan.html"
    )),
    mixture = list(c(
      "R mclust: Mclust",
      "https://search.r-project.org/CRAN/refmans/mclust/html/Mclust.html"
    )),
    composition = list(c(
      "Aitchison compositional geometry overview",
      "https://doi.org/10.1111/j.2517-6161.1982.tb01195.x"
    )),
    validation = list(c(
      "R cluster: silhouette",
      "https://search.r-project.org/CRAN/refmans/cluster/html/silhouette.html"
    )),
    load_typologies = list(
      c(
        "Quesada et al. (2025), electricity consumption typologies",
        "https://doi.org/10.1016/j.egyr.2025.09.002"
      ),
      c(
        "Rajabi et al. (2020), load-pattern clustering comparison",
        "https://doi.org/10.1016/j.rser.2019.109628"
      )
    )
  )

  reference_group <- if (entry$id %in% c(
    "seasonal_daypart",
    "behavioral",
    "som"
  )) {
    "load_typologies"
  } else if (entry$id %in% c(
    "dtw",
    "sbd",
    "dtw_dba",
    "hierarchical",
    "kshape",
    "typical_week"
  )) {
    "time_series"
  } else if (entry$id %in% c(
    "soft_dtw",
    "soft_cluster"
  )) {
    "soft_dtw"
  } else if (entry$id %in% c(
    "catch22_global",
    "catch22_seasonal",
    "catch24_seasonal"
  )) {
    "features"
  } else if (entry$id %in% c(
    "clr",
    "annual_clr_pca",
    "unit_sum",
    "annual_unit_pca"
  )) {
    "composition"
  } else if (entry$id == "hdbscan") {
    "density"
  } else if (entry$id == "gmm") {
    "mixture"
  } else if (entry$id %in% c(
    "silhouette",
    "stability",
    "balance",
    "dunn",
    "gates",
    "recommendation"
  )) {
    "validation"
  } else {
    "classical"
  }

  equation <- unname(equations[entry$id])
  if (is.na(equation)) {
    equation <- paste0(
      "This is a design or interpretation layer rather than a single estimating ",
      "equation. Its formal role is to define the input data, admissible results ",
      "or decision rule used by the downstream model."
    )
  }
  implementation <- unname(implementations[entry$id])
  if (is.na(implementation)) {
    implementation <- paste0(
      "No single official R function represents this methodological decision; it ",
      "is expressed by combining documented preprocessing, modelling and ",
      "validation functions."
    )
  }

  list(
    equation = equation,
    implementation = implementation,
    assumptions = paste(
      paste0(
        "The numerical representation must match the scientific question, meters ",
        "must remain comparable after preprocessing, and the selected distance must ",
        "be meaningful on those coordinates."
      ),
      entry$limitations
    ),
    study_check = paste(
      "Before accepting this choice, state what information it retains and removes.",
      entry$use_when,
      paste0(
        "Then compare it with at least one simpler matched baseline and inspect ",
        "the original hourly curves."
      )
    ),
    references = reference_sets[[reference_group]]
  )
}
