#' Build the standard diagnostic plot collection
#' @param result Output from run_clustering_pipeline().
#' @param profile_probs Lower and upper probabilities for cluster-profile ribbons.
#' @return Named list of ggplot objects.
build_pipeline_plots <- function(result, profile_probs = c(0.25, 0.75)) {
  if (!requireNamespace("ggplot2", quietly = TRUE)) stop("Package 'ggplot2' is required.")
  palette <- get_app_palette()
  ok <- result$metrics[result$metrics$status == "ok", ]
  active_key <- as.character(result$recommended$model_key[1])
  benchmark_key <- result$benchmark_recommendation_key %||% active_key
  ok$is_active <- ok$model_key == active_key
  ok$is_recommended <- ok$model_key == benchmark_key
  algorithm_colors <- palette$algorithms[intersect(names(palette$algorithms), unique(ok$algorithm))]
  cluster_ids <- sort(unique(as.character(result$assignments$cluster)))
  cluster_colors <- stats::setNames(
    grDevices::colorRampPalette(palette$clusters)(length(cluster_ids)),
    cluster_ids
  )
  bands <- calculate_cluster_profile_bands(
    result$weekly_matrix, result$fit$cluster,
    probs = c(profile_probs[1], 0.5, profile_probs[2])
  )
  profile_band_label <- sprintf(
    "P%d-P%d", round(profile_probs[1] * 100),
    round(profile_probs[2] * 100)
  )
  sizes <- as.data.frame(table(cluster = result$assignments$cluster), stringsAsFactors = FALSE)
  sizes$cluster <- as.integer(as.character(sizes$cluster))
  pca <- tryCatch(build_pca_representation(result$matrix, 0.95), error = function(e) NULL)
  pca_data <- if (is.null(pca) || ncol(pca$scores) < 2L) {
    NULL
  } else {
    data.frame(
      series_id = rownames(pca$scores), PC1 = pca$scores[, 1], PC2 = pca$scores[, 2],
      cluster = factor(result$assignments$cluster[match(
        rownames(pca$scores),
        result$assignments$series_id
      )])
    )
  }
  pca_two_component_variance <- if (is.null(pca)) {
    NA_real_
  } else {
    sum(pca$explained_variance[seq_len(min(2L, length(pca$explained_variance)))])
  }
  plots <- list(
    quality = ggplot2::ggplot(result$quality, ggplot2::aes(stats::reorder(series_id, missing_pct),
      missing_pct,
      fill = quality_status
    )) +
      ggplot2::geom_col() +
      ggplot2::coord_flip() +
      ggplot2::scale_fill_manual(values = palette$quality, drop = FALSE) +
      ggplot2::labs(x = NULL, y = "Missing observations (%)", title = "Input data quality") +
      ggplot2::theme_minimal(base_size = 11),
    silhouette = ggplot2::ggplot(ok, ggplot2::aes(k, silhouette,
      color = algorithm, linetype = representation,
      shape = distance, group = interaction(recipe, representation)
    )) +
      ggplot2::geom_line(linewidth = 0.8) +
      ggplot2::geom_point(size = 2.4) +
      ggplot2::geom_point(
        data = ok[ok$is_recommended, ], shape = 21, fill = "white",
        stroke = 1.25, size = 4.8
      ) +
      ggplot2::geom_point(
        data = ok[ok$is_active, ],
        shape = 23,
        fill = palette$accent,
        color = palette$ink,
        size = 4.1
      ) +
      ggplot2::scale_color_manual(values = algorithm_colors) +
      ggplot2::scale_shape_manual(values = c(
        euclidean = 16, manhattan = 17, dtw_basic = 15, sbd = 18,
        model_based = 3, soft_dtw = 8, latent_euclidean = 7
      )) +
      ggplot2::labs(title = "Separation across candidate k", y = "Average silhouette") +
      ggplot2::theme_minimal(base_size = 11),
    stability = ggplot2::ggplot(ok, ggplot2::aes(k, stability,
      color = algorithm, linetype = representation,
      shape = distance, group = interaction(recipe, representation)
    )) +
      ggplot2::geom_line(linewidth = 0.8) +
      ggplot2::geom_point(size = 2.4) +
      ggplot2::geom_point(
        data = ok[ok$is_recommended, ], shape = 21, fill = "white",
        stroke = 1.25, size = 4.8
      ) +
      ggplot2::geom_point(
        data = ok[ok$is_active, ],
        shape = 23,
        fill = palette$accent,
        color = palette$ink,
        size = 4.1
      ) +
      ggplot2::scale_color_manual(values = algorithm_colors) +
      ggplot2::scale_shape_manual(values = c(
        euclidean = 16, manhattan = 17, dtw_basic = 15, sbd = 18,
        model_based = 3, soft_dtw = 8, latent_euclidean = 7
      )) +
      ggplot2::labs(title = "Repeated-seed stability", y = "Mean adjusted Rand index") +
      ggplot2::theme_minimal(base_size = 11),
    runtime = ggplot2::ggplot(ok, ggplot2::aes(k, runtime_seconds,
      color = algorithm, linetype = representation,
      shape = distance, group = interaction(recipe, representation)
    )) +
      ggplot2::geom_line(linewidth = 0.8) +
      ggplot2::geom_point(size = 2.4) +
      ggplot2::geom_point(
        data = ok[ok$is_recommended, ], shape = 21, fill = "white",
        stroke = 1.25, size = 4.8
      ) +
      ggplot2::geom_point(
        data = ok[ok$is_active, ],
        shape = 23,
        fill = palette$accent,
        color = palette$ink,
        size = 4.1
      ) +
      ggplot2::scale_color_manual(values = algorithm_colors) +
      ggplot2::scale_shape_manual(values = c(
        euclidean = 16, manhattan = 17, dtw_basic = 15, sbd = 18,
        model_based = 3, soft_dtw = 8, latent_euclidean = 7
      )) +
      ggplot2::labs(title = "Computational cost", y = "Runtime (seconds)") +
      ggplot2::theme_minimal(base_size = 11),
    dunn = ggplot2::ggplot(ok, ggplot2::aes(k, dunn,
      color = algorithm, linetype = representation,
      shape = distance, group = interaction(recipe, representation)
    )) +
      ggplot2::geom_line(linewidth = 0.8) +
      ggplot2::geom_point(size = 2.4) +
      ggplot2::scale_color_manual(values = algorithm_colors) +
      ggplot2::scale_shape_manual(values = c(
        euclidean = 16, manhattan = 17, dtw_basic = 15, sbd = 18,
        model_based = 3, soft_dtw = 8, latent_euclidean = 7
      )) +
      ggplot2::labs(title = "Separation relative to cluster diameter", y = "Dunn index") +
      ggplot2::theme_minimal(base_size = 11),
    smallest_share = ggplot2::ggplot(ok, ggplot2::aes(k, smallest_cluster_share,
      color = algorithm,
      linetype = representation, shape = distance, group = interaction(recipe, representation)
    )) +
      ggplot2::geom_line(linewidth = 0.8) +
      ggplot2::geom_point(size = 2.4) +
      ggplot2::scale_color_manual(values = algorithm_colors) +
      ggplot2::scale_shape_manual(values = c(
        euclidean = 16, manhattan = 17, dtw_basic = 15, sbd = 18,
        model_based = 3, soft_dtw = 8, latent_euclidean = 7
      )) +
      ggplot2::labs(title = "Smallest retained cluster", y = "Share of accepted profiles") +
      ggplot2::theme_minimal(base_size = 11),
    noise_share = ggplot2::ggplot(ok, ggplot2::aes(k, noise_share,
      color = algorithm,
      linetype = representation, shape = distance, group = interaction(recipe, representation)
    )) +
      ggplot2::geom_line(linewidth = 0.8) +
      ggplot2::geom_point(size = 2.4) +
      ggplot2::scale_color_manual(values = algorithm_colors) +
      ggplot2::scale_shape_manual(values = c(
        euclidean = 16, manhattan = 17, dtw_basic = 15, sbd = 18,
        model_based = 3, soft_dtw = 8, latent_euclidean = 7
      )) +
      ggplot2::labs(title = "Profiles not assigned to a cluster", y = "Noise share") +
      ggplot2::theme_minimal(base_size = 11),
    prototypes = ggplot2::ggplot(bands, ggplot2::aes(hour_of_week, median,
      color = factor(cluster),
      fill = factor(cluster)
    )) +
      ggplot2::geom_ribbon(ggplot2::aes(ymin = lower, ymax = upper), alpha = 0.16, color = NA) +
      ggplot2::geom_line(linewidth = 0.9) +
      ggplot2::facet_wrap(~cluster, ncol = 1) +
      ggplot2::scale_color_manual(values = cluster_colors) +
      ggplot2::scale_fill_manual(values = cluster_colors) +
      ggplot2::labs(
        title = paste("Cluster profiles with", profile_band_label, "ribbons"), x = "Hour of week",
        y = "Normalized load", color = "Cluster", fill = "Cluster"
      ) +
      ggplot2::theme_minimal(base_size = 11) +
      ggplot2::theme(legend.position = "none"),
    cluster_members = ggplot2::ggplot(
      result$cluster_members,
      ggplot2::aes(hour_of_week, normalized_value, group = series_id)
    ) +
      ggplot2::geom_line(color = "#98A2AD", alpha = 0.24, linewidth = 0.35) +
      ggplot2::geom_line(
        data = result$synthetic_profiles,
        ggplot2::aes(hour_of_week, value, group = cluster),
        color = palette$primary,
        linewidth = 1.05,
        inherit.aes = FALSE
      ) +
      ggplot2::facet_wrap(~cluster, ncol = 1) +
      ggplot2::labs(
        title = "Synthetic profile and associated curves", x = "Hour of week",
        y = "Normalized load"
      ) +
      ggplot2::theme_minimal(base_size = 11),
    cluster_heatmap = ggplot2::ggplot(result$cluster_heatmap, ggplot2::aes(
      day_of_year,
      hour_of_day
    )) +
      ggplot2::geom_tile(fill = "#E8ECEE") +
      ggplot2::geom_tile(
        data = result$cluster_heatmap[result$cluster_heatmap$observed, ],
        mapping = ggplot2::aes(fill = relative_intensity)
      ) +
      ggplot2::facet_wrap(~cluster, ncol = 1) +
      ggplot2::scale_x_continuous(
        breaks = c(1, 32, 61, 92, 122, 153, 183, 214, 245, 275, 306, 336),
        labels = month.abb,
        expand = c(0, 0)
      ) +
      ggplot2::coord_cartesian(xlim = c(0.5, 366.5), expand = FALSE) +
      ggplot2::scale_y_reverse(breaks = seq(0, 23, 3), expand = c(0, 0)) +
      ggplot2::scale_fill_gradientn(
        colours = palette$heatmap,
        na.value = "#f4f6f8"
      ) +
      ggplot2::labs(
        title = "Calendar intensity by cluster",
        subtitle = "Mean profile-relative consumption; grey cells have no observations",
        x = NULL,
        y = "Hour",
        fill = "Relative\nintensity"
      ) +
      ggplot2::theme_minimal(base_size = 11) +
      ggplot2::theme(
        panel.grid = ggplot2::element_blank(),
        strip.text = ggplot2::element_text(face = "bold")
      ),
    cluster_sizes = ggplot2::ggplot(sizes, ggplot2::aes(factor(cluster), Freq,
      fill = factor(cluster)
    )) +
      ggplot2::geom_col(width = 0.7) +
      ggplot2::labs(title = "Cluster membership", x = "Cluster", y = "Series") +
      ggplot2::scale_fill_manual(values = cluster_colors) +
      ggplot2::theme_minimal(base_size = 11) +
      ggplot2::theme(legend.position = "none"),
    atypicality = ggplot2::ggplot(
      result$assignments,
      ggplot2::aes(stats::reorder(series_id, atypicality_percentile),
        atypicality_percentile,
        color = factor(cluster)
      )
    ) +
      ggplot2::geom_point(size = 2.4) +
      ggplot2::coord_flip() +
      ggplot2::scale_color_manual(values = cluster_colors) +
      ggplot2::labs(
        title = "Within-cluster atypicality", x = NULL, y = "Percentile",
        color = "Cluster"
      ) +
      ggplot2::theme_minimal(base_size = 11),
    silhouette_detail = ggplot2::ggplot(
      result$common_diagnostics$silhouette[
        !is.na(result$common_diagnostics$silhouette$silhouette),
      ],
      ggplot2::aes(order, silhouette, fill = factor(cluster), text = series_id)
    ) +
      ggplot2::geom_col(width = .88) +
      ggplot2::geom_hline(yintercept = 0, color = "#8f7c84", linewidth = .45) +
      ggplot2::facet_grid(~cluster, scales = "free_x", space = "free_x") +
      ggplot2::scale_fill_manual(values = cluster_colors) +
      ggplot2::labs(
        title = "Silhouette of every assigned profile",
        x = "Profiles ordered within cluster",
        y = "Silhouette"
      ) +
      ggplot2::theme_minimal(base_size = 11) +
      ggplot2::theme(legend.position = "none", axis.text.x = ggplot2::element_blank()),
    peer_distance = ggplot2::ggplot(
      result$common_diagnostics$peer_distance,
      ggplot2::aes(factor(cluster), mean_peer_distance, fill = factor(cluster), text = series_id)
    ) +
      ggplot2::geom_boxplot(width = .34, outlier.shape = NA, alpha = .42) +
      ggplot2::geom_jitter(width = .08, alpha = .48, size = 1.7) +
      ggplot2::scale_fill_manual(values = cluster_colors) +
      ggplot2::labs(
        title = "Exact within-cluster dissimilarity", x = "Cluster",
        y = "Mean distance to cluster peers"
      ) +
      ggplot2::theme_minimal(base_size = 11) +
      ggplot2::theme(legend.position = "none"),
    dissimilarity = ggplot2::ggplot(
      result$common_diagnostics$dissimilarity_heatmap,
      ggplot2::aes(
        column,
        row,
        fill = distance,
        text = paste0(
          "Column profile: ", column_profile,
          "<br>Column cluster: ", column_cluster,
          "<br>Row profile: ", row_profile,
          "<br>Row cluster: ", row_cluster,
          "<br>Dissimilarity: ", signif(distance, 5)
        )
      )
    ) +
      ggplot2::geom_raster() +
      ggplot2::scale_fill_gradientn(colours = palette$heatmap) +
      ggplot2::scale_y_reverse() +
      ggplot2::coord_equal() +
      ggplot2::labs(
        title = "Method-consistent dissimilarity matrix", x = "Profiles ordered by cluster",
        y = "Profiles ordered by cluster", fill = "Distance"
      ) +
      ggplot2::theme_minimal(base_size = 11) +
      ggplot2::theme(panel.grid = ggplot2::element_blank(), axis.text = ggplot2::element_blank()),
    pca = if (is.null(pca_data)) {
      ggplot2::ggplot() +
        ggplot2::annotate("text", 0, 0, label = "PCA unavailable") +
        ggplot2::theme_void()
    } else {
      ggplot2::ggplot(pca_data, ggplot2::aes(PC1, PC2, color = cluster, text = series_id)) +
        ggplot2::geom_point(size = 3, alpha = 0.85) +
        ggplot2::scale_color_manual(values = cluster_colors) +
        ggplot2::labs(
          title = sprintf(
            "PCA inspection view · PC1 + PC2 explain %.1f%%",
            100 * pca_two_component_variance
          ),
          subtitle = sprintf(
            "%d component%s required to reach at least 95%% in this selected representation",
            pca$components,
            if (pca$components == 1L) " is" else "s are"
          ),
          x = sprintf("PC1 · %.1f%%", 100 * pca$explained_variance[1]),
          y = sprintf("PC2 · %.1f%%", 100 * pca$explained_variance[2]),
          color = "Cluster"
        ) +
        ggplot2::theme_minimal(base_size = 11)
    }
  )

  dendrogram <- build_dendrogram_plot(result$dendrogram_fit)
  if (!is.null(dendrogram)) plots$dendrogram <- dendrogram
  plots
}
