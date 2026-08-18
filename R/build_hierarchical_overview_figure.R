#' Build a three-panel overview of one hierarchical clustering result
#' @param result Materialized hierarchical pipeline result.
#' @return A grid grob containing the dendrogram, cluster profiles and member curves.
build_hierarchical_overview_figure <- function(result) {
  if (!inherits(result$fit$model, "hclust")) {
    stop("A hierarchical clustering result is required.")
  }
  if (!requireNamespace("gridExtra", quietly = TRUE)) {
    stop("Package 'gridExtra' is required.")
  }

  palette <- get_app_palette()
  clusters <- sort(unique(result$fit$cluster))
  cluster_count <- length(clusters)
  colours <- stats::setNames(
    grDevices::colorRampPalette(palette$clusters)(length(clusters)),
    as.character(clusters)
  )
  hour_breaks <- c(1L, 25L, 49L, 73L, 97L, 121L, 145L, 168L)
  hour_labels <- c("Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun", "Sun 23:00")

  dendrogram <- build_dendrogram_plot(
    result$fit,
    "Complete-linkage hierarchy"
  ) +
    ggplot2::coord_flip(clip = "off") +
    ggplot2::labs(subtitle = NULL, caption = NULL, x = NULL, y = "DTW merge distance") +
    ggplot2::theme(
      legend.position = "none",
      axis.text.x = ggplot2::element_text(size = 7),
      axis.text.y = ggplot2::element_blank(),
      axis.ticks.y = ggplot2::element_blank(),
      plot.title = ggplot2::element_text(size = 13, face = "bold")
    )

  members <- result$cluster_members
  profiles <- build_cluster_profile_view(
    result,
    horizon = "weekly",
    probs = c(0.25, 0.75)
  )$summaries
  profiles$cluster <- factor(profiles$cluster, levels = clusters)
  profile_plot <- ggplot2::ggplot(
    profiles,
    ggplot2::aes(interval, median, colour = cluster, fill = cluster)
  ) +
    ggplot2::geom_ribbon(
      ggplot2::aes(ymin = lower, ymax = upper),
      alpha = 0.34,
      colour = NA
    ) +
    ggplot2::geom_line(linewidth = 1.05) +
    ggplot2::facet_grid(cluster ~ ., scales = "free_y", switch = "y") +
    ggplot2::scale_colour_manual(values = colours, guide = "none") +
    ggplot2::scale_fill_manual(values = colours, guide = "none") +
    ggplot2::scale_x_continuous(breaks = hour_breaks, labels = hour_labels) +
    ggplot2::labs(title = "Median profiles and IQR", x = NULL, y = NULL) +
    ggplot2::theme_minimal(base_size = 10) +
    ggplot2::theme(
      panel.grid.minor = ggplot2::element_blank(),
      panel.grid.major.y = ggplot2::element_blank(),
      axis.text.x = ggplot2::element_text(angle = 45, hjust = 1, size = 7),
      strip.placement = "outside",
      strip.text.y.left = ggplot2::element_text(angle = 0, face = "bold", colour = palette$ink),
      plot.title = ggplot2::element_text(size = 13, face = "bold")
    )

  members$cluster <- factor(members$cluster, levels = clusters)
  member_plot <- ggplot2::ggplot(
    members,
    ggplot2::aes(hour_of_week, normalized_value, colour = cluster, group = series_id)
  ) +
    ggplot2::geom_line(linewidth = 0.38, alpha = 0.58) +
    ggplot2::facet_grid(cluster ~ ., scales = "free_y", switch = "y") +
    ggplot2::scale_colour_manual(values = colours, guide = "none") +
    ggplot2::scale_x_continuous(breaks = hour_breaks, labels = hour_labels) +
    ggplot2::labs(title = "Individual normalized weekly profiles", x = NULL, y = NULL) +
    ggplot2::theme_minimal(base_size = 9) +
    ggplot2::theme(
      panel.grid = ggplot2::element_blank(),
      axis.text.y = ggplot2::element_blank(),
      axis.ticks.y = ggplot2::element_blank(),
      axis.text.x = ggplot2::element_text(angle = 45, hjust = 1, size = 7),
      strip.placement = "outside",
      strip.background = ggplot2::element_blank(),
      strip.text.y.left = ggplot2::element_text(
        angle = 0, face = "bold", colour = palette$ink
      ),
      plot.title = ggplot2::element_text(size = 13, face = "bold")
    )

  gridExtra::arrangeGrob(
    dendrogram, profile_plot, member_plot,
    nrow = 1,
    widths = c(1, 1, 1),
    top = grid::textGrob(
      sprintf("Hierarchical DTW | %d electricity-load clusters", cluster_count),
      gp = grid::gpar(fontsize = 17, fontface = "bold", col = palette$ink),
      x = 0.02, hjust = 0
    ),
    bottom = grid::textGrob(
      sprintf(
        "Anonymized GoiEner 2020 sample | constrained DTW | complete linkage | k = %d",
        cluster_count
      ),
      gp = grid::gpar(fontsize = 9, col = palette$ink_soft %||% "#6F686C"),
      x = 0.02, hjust = 0
    )
  )
}
