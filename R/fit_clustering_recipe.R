#' Fit one declared clustering recipe
#' @param matrix Series-by-feature matrix.
#' @param recipe Recipe identifier from get_clustering_recipe_catalog().
#' @param k Cluster count, or min_points for HDBSCAN.
#' @param seed Random seed.
#' @param window_size DTW warping window.
#' @param distance_matrix Optional cached distances.
#' @param advanced Advanced method settings.
#' @return Standardized clustering result.
fit_clustering_recipe <- function(matrix, recipe, k, seed, window_size,
                                  distance_matrix = NULL, advanced = list()) {
  switch(recipe,
    kmeans_euclidean = fit_kmeans_clustering(matrix, k, seed),
    pam_euclidean = fit_pam_clustering(matrix, k, "euclidean", window_size, distance_matrix),
    pam_manhattan = fit_pam_clustering(matrix, k, "manhattan", window_size, distance_matrix),
    pam_dtw = fit_pam_clustering(matrix, k, "dtw_basic", window_size, distance_matrix),
    dtw_dba = fit_dtw_dba_clustering(matrix, k, seed, window_size),
    dtw_hclust = fit_dtw_hierarchical_clustering(matrix, k, seed, window_size, distance_matrix),
    kshape = fit_kshape_clustering(matrix, k, seed),
    som_euclidean = fit_som_clustering(matrix, k, seed, advanced$som_iterations %||% 100L),
    gmm_model = fit_gmm_clustering(matrix, k, seed),
    hdbscan_euclidean = fit_hdbscan_clustering(matrix, k, "euclidean"),
    hdbscan_manhattan = fit_hdbscan_clustering(matrix, k, "manhattan"),
    soft_dtw = fit_soft_dtw_clustering(matrix, k, seed, advanced$soft_dtw_gamma %||% 0.05),
    deep_autoencoder = fit_deep_autoencoder_clustering(
      matrix, k, seed, advanced$deep_latent_dimensions %||% 4L, advanced$deep_epochs %||% 80L
    ),
    stop("Unknown clustering method configuration: ", recipe)
  )
}
