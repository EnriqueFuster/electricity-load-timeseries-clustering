#' Define supported representation, algorithm and distance combinations
#' @return One row per selectable clustering recipe.
get_clustering_recipe_catalog <- function() {
  data.frame(
    recipe = c(
      "kmeans_euclidean", "pam_euclidean", "pam_manhattan", "pam_dtw",
      "dtw_dba", "dtw_hclust", "kshape", "som_euclidean", "gmm_model",
      "hdbscan_euclidean", "hdbscan_manhattan", "soft_dtw", "deep_autoencoder"
    ),
    algorithm = c(
      "kmeans", "pam", "pam", "pam", "dtw_dba", "hierarchical", "kshape",
      "som", "gmm", "hdbscan", "hdbscan", "soft_dtw", "deep_autoencoder"
    ),
    distance = c(
      "euclidean", "euclidean", "manhattan", "dtw_basic", "dtw_basic", "dtw_basic", "sbd",
      "euclidean", "model_based", "euclidean", "manhattan", "soft_dtw", "latent_euclidean"
    ),
    method_tier = c(
      "baseline", "baseline", "literature-backed", "literature-backed",
      "methodological-extension", "literature-backed", "literature-backed",
      "literature-backed", "literature-backed", "methodological-extension",
      "methodological-extension", "methodological-extension", "exploratory"
    ),
    representation_scope = c(
      "all", "all", "all", "whole-series", "whole-series", "whole-series", "whole-series",
      "all", "reduced", "reduced", "reduced", "whole-series", "reduced"
    ),
    uses_k = c(TRUE, TRUE, TRUE, TRUE, TRUE, TRUE, TRUE, TRUE, TRUE, FALSE, FALSE, TRUE, TRUE),
    stringsAsFactors = FALSE
  )
}
