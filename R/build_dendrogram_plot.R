#' Build a cluster-coloured dendrogram from a hierarchical fit
#' @param fit Standardized hierarchical clustering fit.
#' @param title Plot title.
#' @return A ggplot object, or NULL when the fit is not hierarchical.
build_dendrogram_plot <- function(fit, title = "DTW hierarchical structure") {
  if (is.null(fit) || isS4(fit) || !is.list(fit)) return(NULL)
  if (!inherits(fit$model, "hclust")) return(NULL)
  if (!requireNamespace("ggplot2", quietly = TRUE)) stop("Package 'ggplot2' is required.")

  model <- fit$model
  cluster <- fit$cluster
  model_labels <- model$labels %||% names(cluster) %||% as.character(seq_along(model$order))
  k <- length(unique(cluster))
  if (is.null(cluster) || !length(cluster) || k < 1L) {
    cluster <- stats::cutree(model, k = 1L)
    k <- 1L
  }
  cluster <- stats::setNames(as.integer(cluster), names(cluster) %||% model_labels)
  leaf_cluster <- cluster[model_labels]
  palette <- get_app_palette()
  cluster_colours <- stats::setNames(
    grDevices::colorRampPalette(palette$clusters)(k), sort(unique(cluster))
  )

  leaf_positions <- stats::setNames(seq_along(model$order), model$order)
  node_x <- numeric(nrow(model$merge))
  node_leaves <- vector("list", nrow(model$merge))
  segments <- vector("list", nrow(model$merge))
  child_data <- function(child) {
    if (child < 0L) {
      index <- -child
      return(list(x = unname(leaf_positions[as.character(index)]), y = 0, leaves = index))
    }
    list(x = node_x[child], y = model$height[child], leaves = node_leaves[[child]])
  }
  branch_cluster <- function(leaves) {
    values <- unique(leaf_cluster[leaves])
    if (length(values) == 1L && !is.na(values)) as.character(values) else "Trunk"
  }

  for (node in seq_len(nrow(model$merge))) {
    left <- child_data(model$merge[node, 1])
    right <- child_data(model$merge[node, 2])
    node_x[node] <- mean(c(left$x, right$x))
    node_leaves[[node]] <- c(left$leaves, right$leaves)
    height <- model$height[node]
    segments[[node]] <- rbind(
      data.frame(x = left$x, y = left$y, xend = left$x, yend = height,
                 branch = branch_cluster(left$leaves)),
      data.frame(x = right$x, y = right$y, xend = right$x, yend = height,
                 branch = branch_cluster(right$leaves)),
      data.frame(x = left$x, y = height, xend = right$x, yend = height,
                 branch = branch_cluster(node_leaves[[node]]))
    )
  }
  segments <- do.call(rbind, segments)
  merges_below_cut <- length(model$height) + 1L - k
  lower <- if (merges_below_cut > 0L) model$height[merges_below_cut] else 0
  upper <- if (merges_below_cut < length(model$height)) {
    model$height[merges_below_cut + 1L]
  } else {
    max(model$height)
  }
  cut_height <- mean(c(lower, upper))
  label_gap <- max(model$height) * 0.035
  labels <- data.frame(
    x = seq_along(model$order), y = -label_gap,
    label = model_labels[model$order], cluster = factor(leaf_cluster[model$order])
  )
  branch_colours <- c(cluster_colours, Trunk = palette$ink_soft %||% "#8C8588")

  ggplot2::ggplot(segments) +
    ggplot2::geom_segment(
      ggplot2::aes(x = x, y = y, xend = xend, yend = yend, colour = branch),
      linewidth = 0.78, lineend = "round"
    ) +
    ggplot2::geom_hline(
      yintercept = cut_height, colour = palette$accent,
      linewidth = 0.7, linetype = "22", alpha = 0.9
    ) +
    ggplot2::geom_text(
      data = labels,
      ggplot2::aes(x = x, y = y, label = label, colour = cluster),
      inherit.aes = FALSE, angle = 55, hjust = 1, size = 3
    ) +
    ggplot2::scale_colour_manual(values = branch_colours, name = "Cluster") +
    ggplot2::scale_x_continuous(expand = ggplot2::expansion(mult = c(0.015, 0.015))) +
    ggplot2::scale_y_continuous(expand = ggplot2::expansion(mult = c(0.09, 0.06))) +
    ggplot2::labs(
      title = title,
      subtitle = sprintf(
        "Complete linkage over constrained DTW distances · cut into %d clusters",
        k
      ),
      caption = "Coloured branches fall within the selected cut; the dashed line marks its height.",
      x = NULL, y = "DTW merge distance"
    ) +
    ggplot2::theme_minimal(base_size = 11) +
    ggplot2::theme(
      panel.grid.minor = ggplot2::element_blank(),
      panel.grid.major.x = ggplot2::element_blank(),
      axis.text.x = ggplot2::element_blank(), axis.ticks.x = ggplot2::element_blank(),
      legend.position = "top", legend.title = ggplot2::element_text(face = "bold"),
      plot.caption = ggplot2::element_text(colour = palette$ink_soft, hjust = 0)
    )
}
