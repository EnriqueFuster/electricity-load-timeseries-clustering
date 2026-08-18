#' Plot synthetic profiles and their associated member curves
#' @param profile_view Output from build_cluster_profile_view().
#' @param palette Application palette.
#' @param show_members Whether transparent associated curves are drawn behind the ribbon.
#' @param show_observations Whether recurring views include transparent hourly observations.
#' @return A ggplot object.
plot_cluster_profile_view <- function(profile_view, palette = get_app_palette(),
                                      show_members = FALSE,
                                      show_observations = FALSE) {
  members <- profile_view$members
  summaries <- profile_view$summaries
  cluster_ids <- sort(unique(as.character(members$cluster)))
  colors <- stats::setNames(
    grDevices::colorRampPalette(palette$clusters)(length(cluster_ids)),
    cluster_ids
  )

  plot <- ggplot2::ggplot(
    summaries,
    ggplot2::aes(interval, median,
      group = factor(cluster),
      text = paste0(
        "Cluster: ", cluster, "<br>Interval: ", interval,
        "<br>Median: ", round(median, 4),
        "<br>Lower percentile: ", round(lower, 4),
        "<br>Upper percentile: ", round(upper, 4)
      )
    )
  )
  if (show_members) {
    plot <- plot + suppressWarnings(ggplot2::geom_line(
      data = members,
      ggplot2::aes(interval, normalized_value,
        group = series_id,
        text = paste0(
          "Series: ", series_id, "<br>Interval: ", interval,
          "<br>Normalized load: ", round(normalized_value, 4)
        )
      ),
      inherit.aes = FALSE, color = "#706A70", alpha = .10, linewidth = .28
    ))
  }
  if (
    isTRUE(show_observations) &&
      profile_view$horizon %in% c("daily", "weekly")
  ) {
    plot <- plot + ggplot2::geom_jitter(
      data = profile_view$observations,
      ggplot2::aes(interval, normalized_value),
      inherit.aes = FALSE,
      width = .16,
      height = 0,
      alpha = .07,
      size = .45,
      color = "#625A60"
    )
  }

  plot +
    ggplot2::geom_ribbon(
      ggplot2::aes(ymin = lower, ymax = upper, fill = factor(cluster)),
      alpha = .34, color = NA
    ) +
    ggplot2::geom_line(
      ggplot2::aes(color = factor(cluster)),
      linewidth = 1.05
    ) +
    ggplot2::facet_wrap(~cluster, ncol = 1, scales = "free_y") +
    ggplot2::scale_x_continuous(
      breaks = profile_view$axis$breaks,
      labels = profile_view$axis$labels
    ) +
    ggplot2::scale_color_manual(values = colors) +
    ggplot2::scale_fill_manual(values = colors) +
    ggplot2::labs(
      title = paste(tools::toTitleCase(profile_view$horizon), "synthetic profiles"),
      subtitle = sprintf(
        "Median profile and P%d-P%d ribbon%s",
        round(profile_view$probs[1] * 100), round(profile_view$probs[2] * 100),
        if (show_members) ", with transparent associated curves" else ""
      ),
      x = profile_view$axis$label, y = "Normalized load"
    ) +
    ggplot2::theme_minimal(base_size = 11) +
    ggplot2::theme(legend.position = "none", panel.grid.minor = ggplot2::element_blank())
}
