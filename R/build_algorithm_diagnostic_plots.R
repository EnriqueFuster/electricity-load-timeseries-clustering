#' Build diagnostics that are mathematically specific to the active algorithm
#' @param result Materialized pipeline result.
#' @return List with title, description and up to three named ggplot objects.
build_algorithm_diagnostic_plots <- function(result) {
  if (!requireNamespace("ggplot2", quietly = TRUE)) stop("Package 'ggplot2' is required.")
  fit <- result$fit
  algorithm <- as.character(result$recommended$algorithm[1])
  matrix <- result$matrix
  clusters <- fit$cluster[rownames(matrix)]
  palette <- get_app_palette()
  cluster_ids <- sort(unique(as.character(clusters)))
  colors <- stats::setNames(
    grDevices::colorRampPalette(palette$clusters)(length(cluster_ids)),
    cluster_ids
  )
  empty_result <- function(title, description, message) {
    list(
      title = title, description = description,
      tab_names = "Method notes",
      plots = list(
        ggplot2::ggplot() +
          ggplot2::annotate("text", 0, 0,
            label = message,
            color = palette$ink
          ) +
          ggplot2::theme_void()
      )
    )
  }
  prototype_plot <- function(title, subtitle) {
    prototypes <- fit$prototypes %||% calculate_cluster_prototypes(matrix, clusters)
    prototype_clusters <- sort(unique(as.integer(clusters)))
    if (length(prototype_clusters) != nrow(prototypes)) {
      prototype_clusters <- seq_len(nrow(prototypes))
    }
    frame <- data.frame(
      cluster = rep(prototype_clusters, each = ncol(prototypes)),
      coordinate = rep(seq_len(ncol(prototypes)), nrow(prototypes)),
      value = as.vector(t(prototypes))
    )
    ggplot2::ggplot(frame, ggplot2::aes(coordinate, value, color = factor(cluster))) +
      ggplot2::geom_line(linewidth = .9) +
      ggplot2::facet_wrap(~cluster, scales = "free_y") +
      ggplot2::scale_color_manual(values = colors) +
      ggplot2::labs(
        title = title, subtitle = subtitle, x = "Model-space coordinate",
        y = "Prototype value"
      ) +
      ggplot2::theme_minimal(base_size = 11) +
      ggplot2::theme(legend.position = "none")
  }

  # CENTROID AND MEDOID METHODS ------------------------------------------
  if (algorithm == "kmeans") {
    dispersion <- data.frame(cluster = seq_along(fit$model$withinss), withinss = fit$model$withinss)
    dispersion_plot <- ggplot2::ggplot(dispersion, ggplot2::aes(factor(cluster), withinss,
      fill = factor(cluster)
    )) +
      ggplot2::geom_col(width = .68) +
      ggplot2::scale_fill_manual(values = colors) +
      ggplot2::labs(
        title = "Within-cluster sum of squares",
        subtitle = sprintf(
          "Between-cluster share: %.1f%%",
          100 * fit$model$betweenss / fit$model$totss
        ),
        x = "Cluster",
        y = "Within sum of squares"
      ) +
      ggplot2::theme_minimal(base_size = 11) +
      ggplot2::theme(legend.position = "none")
    return(list(
      title = "K-means geometry",
      description = paste0(
        "Exact objective decomposition and arithmetic centroids in the ",
        "representation used for fitting."
      ),
      tab_names = c("Objective decomposition", "Arithmetic centroids"),
      plots = list(
        dispersion_plot,
        prototype_plot(
          "Arithmetic centroids",
          "These are the exact K-means centres in model space."
        )
      )
    ))
  }

  if (algorithm == "pam") {
    medoid_ids <- as.character(fit$model$medoids)
    distance <- as.matrix(fit$distance_matrix)
    medoid_distance <- vapply(seq_along(clusters), function(index) {
      medoid <- medoid_ids[match(clusters[index], sort(unique(clusters)))]
      distance[index, match(medoid, rownames(distance))]
    }, numeric(1))
    frame <- data.frame(
      series_id = names(clusters), cluster = factor(clusters), distance = medoid_distance,
      is_medoid = names(clusters) %in% medoid_ids
    )
    medoid_plot <- ggplot2::ggplot(frame, ggplot2::aes(cluster, distance,
      color = cluster,
      text = series_id
    )) +
      ggplot2::geom_jitter(width = .1, alpha = .65, size = 2) +
      ggplot2::geom_point(
        data = frame[frame$is_medoid, ], shape = 23, fill = "white", size = 4,
        stroke = 1.1
      ) +
      ggplot2::scale_color_manual(values = colors) +
      ggplot2::labs(
        title = "Distance to the observed medoid",
        subtitle = "Diamond points are the real profiles selected as medoids.",
        x = "Cluster",
        y = "Declared dissimilarity"
      ) +
      ggplot2::theme_minimal(base_size = 11) +
      ggplot2::theme(legend.position = "none")
    return(list(
      title = "PAM / K-medoids representatives",
      description = paste0(
        "PAM represents every group with an observed profile rather than an ",
        "arithmetic mean."
      ),
      tab_names = c("Distance to medoids", "Observed medoids"),
      plots = list(
        medoid_plot,
        prototype_plot(
          "Observed medoid profiles",
          "Every line is an actual profile selected by PAM."
        )
      )
    ))
  }

  # ORDERED TIME-SERIES METHODS ------------------------------------------
  if (algorithm %in% c("dtw_dba", "soft_dtw", "kshape")) {
    labels <- c(
      dtw_dba = "DTW barycentre averaging", soft_dtw = "Soft-DTW centroids",
      kshape = "k-Shape centroids"
    )
    subtitles <- c(
      dtw_dba = "DBA prototypes are estimated after constrained temporal alignments.",
      soft_dtw = "Centroids minimize the differentiable Soft-DTW objective.",
      kshape = "Shape centroids summarize aligned, normalized cross-correlation morphology."
    )
    plots <- list(prototype_plot(labels[[algorithm]], subtitles[[algorithm]]))
    if (algorithm == "dtw_dba") {
      target_index <- which.max(result$assignments$mean_within_cluster_dissimilarity)
      target_cluster <- clusters[target_index]
      prototype_index <- match(target_cluster, sort(unique(clusters)))
      alignment <- dtw::dtw(
        as.numeric(matrix[target_index, ]), as.numeric(fit$prototypes[prototype_index, ]),
        window.type = "sakoechiba",
        window.size = result$config$modeling$dtw_window_size %||% 12L,
        keep.internals = TRUE
      )
      path <- data.frame(
        profile_coordinate = alignment$index1,
        prototype_coordinate = alignment$index2
      )
      plots[[2]] <- ggplot2::ggplot(path, ggplot2::aes(profile_coordinate, prototype_coordinate)) +
        ggplot2::geom_abline(slope = 1, intercept = 0, color = "#cfc5c0", linetype = 2) +
        ggplot2::geom_path(color = palette$primary, linewidth = .9) +
        ggplot2::coord_equal() +
        ggplot2::labs(
          title = paste("Warping path for", names(clusters)[target_index]),
          subtitle = "The most atypical profile is aligned to its exact DBA prototype.",
          x = "Profile coordinate", y = "Prototype coordinate"
        ) +
        ggplot2::theme_minimal(base_size = 11)
    }
    if (algorithm == "kshape") {
      aligned <- lapply(seq_len(nrow(matrix)), function(index) {
        prototype_index <- match(clusters[index], sort(unique(clusters)))
        alignment <- dtwclust::SBD(fit$prototypes[prototype_index, ], matrix[index, ],
          znorm = FALSE
        )
        data.frame(
          series_id = rownames(matrix)[index], cluster = unname(clusters[index]),
          coordinate = seq_len(ncol(matrix)),
          value = alignment$yshift, sbd = as.numeric(alignment$dist)
        )
      })
      aligned <- do.call(rbind, aligned)
      plots[[2]] <- ggplot2::ggplot(aligned, ggplot2::aes(coordinate, value,
        group = series_id,
        text = series_id
      )) +
        ggplot2::geom_line(color = "#8f9aa1", alpha = .28, linewidth = .4) +
        ggplot2::facet_wrap(~cluster) +
        ggplot2::labs(
          title = "Curves after exact SBD alignment", x = "Aligned coordinate",
          y = "Normalized value"
        ) +
        ggplot2::theme_minimal(base_size = 11)
      sbd_rows <- unique(aligned[c("series_id", "cluster", "sbd")])
      plots[[3]] <- ggplot2::ggplot(
        sbd_rows,
        ggplot2::aes(factor(cluster),
          sbd,
          color = factor(cluster),
          text = series_id
        )
      ) +
        ggplot2::geom_jitter(width = .1, size = 2.2, alpha = .72) +
        ggplot2::scale_color_manual(values = colors) +
        ggplot2::labs(title = "Shape-based distance to centroid", x = "Cluster", y = "SBD") +
        ggplot2::theme_minimal(base_size = 11) +
        ggplot2::theme(legend.position = "none")
    }
    tab_names <- switch(algorithm,
      dtw_dba = c("DBA prototypes", "Warping path"),
      soft_dtw = "Soft-DTW centroids",
      kshape = c("Shape centroids", "Aligned curves", "Distance to centroid")
    )
    return(list(
      title = labels[[algorithm]],
      description = subtitles[[algorithm]],
      tab_names = tab_names,
      plots = plots
    ))
  }

  # HIERARCHICAL, TOPOLOGICAL AND PROBABILISTIC METHODS ------------------
  if (algorithm == "hierarchical") {
    tree <- build_dendrogram_plot(fit, "Active constrained-DTW hierarchy")
    return(list(title = "Hierarchical DTW tree", description = paste0(
      "This dendrogram belongs to the active complete-linkage fit. Coloured branches ",
      "show the selected clusters, the dashed line shows the cut and branch height ",
      "is constrained-DTW dissimilarity."
    ), tab_names = "Dendrogram", plots = list(tree)))
  }

  if (algorithm == "som") {
    model <- fit$model
    points <- as.data.frame(model$grid$pts)
    names(points)[1:2] <- c("x", "y")
    points$hits <- tabulate(model$unit.classif, nbins = nrow(points))
    unit_cluster <- vapply(seq_len(nrow(points)), function(unit) {
      assigned <- clusters[model$unit.classif == unit]
      if (!length(assigned)) {
        return(NA_integer_)
      }
      as.integer(unique(assigned)[1])
    }, integer(1))
    points$cluster <- factor(unit_cluster, levels = as.integer(cluster_ids))
    som_plot <- ggplot2::ggplot(
      points,
      ggplot2::aes(x,
        y,
        size = hits,
        fill = cluster,
        text = paste(
          "Profiles:",
          hits
        )
      )
    ) +
      ggplot2::geom_point(shape = 21, color = "white", stroke = 1, alpha = .92) +
      ggplot2::scale_fill_manual(values = colors) +
      ggplot2::scale_size_continuous(range = c(7, 20)) +
      ggplot2::coord_equal() +
      ggplot2::labs(
        title = "SOM hit and cluster map",
        subtitle = paste0(
          "Position preserves map topology; area is the number of profiles assigned ",
          "to each unit."
        ),
        x = NULL,
        y = NULL
      ) +
      ggplot2::theme_void(base_size = 11)
    codes <- model$codes[[1]]
    coordinate_distance <- as.matrix(stats::dist(points[c("x", "y")]))
    nearest_spacing <- min(coordinate_distance[coordinate_distance > 0])
    neighbours <- coordinate_distance <= nearest_spacing * 1.05 & coordinate_distance > 0
    u_value <- vapply(seq_len(nrow(codes)), function(index) {
      adjacent <- which(neighbours[index, ])
      if (!length(adjacent)) {
        return(0)
      }
      focal_code <- rep(
        codes[index, ],
        each = length(adjacent)
      )
      mean(sqrt(rowSums((codes[adjacent, , drop = FALSE] - focal_code)^2)))
    }, numeric(1))
    points$u_distance <- u_value
    u_plot <- ggplot2::ggplot(
      points,
      ggplot2::aes(x,
        y,
        fill = u_distance,
        text = paste(
          "U-distance:",
          round(
            u_distance,
            4
          )
        )
      )
    ) +
      ggplot2::geom_point(shape = 21, size = 15, color = "white", stroke = .8) +
      ggplot2::scale_fill_gradientn(colours = palette$heatmap) +
      ggplot2::coord_equal() +
      ggplot2::labs(
        title = "SOM U-Matrix",
        subtitle = "Higher values mark stronger boundaries between neighbouring codebook vectors.",
        fill = "Neighbour\ndistance"
      ) +
      ggplot2::theme_void(base_size = 11)
    return(list(
      title = "Self-organising map",
      description = paste0(
        "The hexagonal map is the algorithm's native topology; final colors are ",
        "codebook clusters."
      ),
      tab_names = c(
        "Hit map",
        "U-Matrix",
        "Cluster prototypes"
      ),
      plots = list(
        som_plot,
        u_plot,
        prototype_plot(
          "SOM cluster prototypes",
          "Cluster means in the fitted representation."
        )
      )
    ))
  }

  if (algorithm == "gmm") {
    posterior <- fit$model$z
    profile_ids <- rownames(posterior)
    if (is.null(profile_ids) || length(profile_ids) != nrow(posterior)) {
      profile_ids <- rownames(matrix)
    }
    posterior_frame <- expand.grid(
      profile = profile_ids,
      component = seq_len(ncol(posterior)),
      KEEP.OUT.ATTRS = FALSE
    )
    posterior_frame$probability <- as.vector(posterior)
    confidence <- data.frame(
      series_id = profile_ids,
      cluster = factor(clusters),
      probability = apply(
        posterior,
        1,
        max
      )
    )
    posterior_plot <- ggplot2::ggplot(posterior_frame, ggplot2::aes(component, profile,
      fill = probability
    )) +
      ggplot2::geom_tile() +
      ggplot2::scale_fill_gradientn(colours = palette$heatmap, limits = c(0, 1)) +
      ggplot2::labs(
        title = "Posterior membership probabilities",
        x = "Gaussian component",
        y = "Profile",
        fill = "Probability"
      ) +
      ggplot2::theme_minimal(base_size = 11)
    confidence_plot <- ggplot2::ggplot(
      confidence,
      ggplot2::aes(
        stats::reorder(
          series_id,
          probability
        ),
        probability,
        color = cluster
      )
    ) +
      ggplot2::geom_point(size = 2.3) +
      ggplot2::coord_flip() +
      ggplot2::scale_color_manual(values = colors) +
      ggplot2::labs(
        title = "Classification confidence", x = NULL,
        y = "Maximum posterior probability"
      ) +
      ggplot2::theme_minimal(base_size = 11)
    plots <- list(posterior_plot, confidence_plot)
    bic <- fit$model$bic
    if (!is.null(bic)) {
      if (length(bic) == 1L && is.null(dim(bic))) {
        bic_frame <- data.frame(
          components = fit$model$G,
          covariance = fit$model$modelName,
          bic = as.numeric(bic)
        )
      } else {
        bic_matrix <- as.matrix(bic)
        component_values <- suppressWarnings(as.integer(rownames(bic_matrix)))
        if (
          length(component_values) != nrow(bic_matrix) ||
            anyNA(component_values)
        ) {
          component_values <- seq_len(nrow(bic_matrix))
        }
        covariance_values <- colnames(bic_matrix)
        if (is.null(covariance_values)) covariance_values <- "Selected model"
        bic_frame <- data.frame(
          expand.grid(
            components = component_values,
            covariance = covariance_values,
            KEEP.OUT.ATTRS = FALSE
          ),
          bic = as.vector(bic_matrix)
        )
      }
      bic_frame <- bic_frame[is.finite(bic_frame$bic), ]
      if (nrow(bic_frame)) {
        plots[[3]] <- ggplot2::ggplot(
          bic_frame,
          ggplot2::aes(components,
            bic,
            color = covariance,
            group = covariance
          )
        ) +
          ggplot2::geom_line(linewidth = .75) +
          ggplot2::geom_point(size = 1.8) +
          ggplot2::labs(
            title = "Gaussian covariance-model BIC",
            subtitle = "Higher BIC is preferred within the models evaluated by mclust.",
            x = "Components",
            y = "BIC",
            color = "Covariance"
          ) +
          ggplot2::theme_minimal(base_size = 11)
      }
    }
    return(list(
      title = "Gaussian mixture uncertainty",
      description = paste0(
        "Posterior probabilities and BIC expose assignment ambiguity and ",
        "covariance-model evidence."
      ),
      tab_names = c(
        "Membership probabilities",
        "Classification confidence",
        "Covariance-model BIC"
      )[seq_along(plots)],
      plots = plots
    ))
  }

  if (algorithm == "hdbscan") {
    frame <- data.frame(
      series_id = names(clusters), cluster = factor(clusters),
      membership = fit$membership_probability, outlier = fit$outlier_score
    )
    probability_plot <- ggplot2::ggplot(frame, ggplot2::aes(membership, outlier,
      color = cluster,
      text = series_id
    )) +
      ggplot2::geom_point(size = 2.7, alpha = .82) +
      ggplot2::scale_color_manual(values = colors) +
      ggplot2::labs(
        title = "Density membership and outlier evidence",
        subtitle = "Cluster 0 denotes noise.",
        x = "Membership probability",
        y = "Outlier score"
      ) +
      ggplot2::theme_minimal(base_size = 11)
    rank_plot <- ggplot2::ggplot(frame, ggplot2::aes(stats::reorder(series_id, outlier), outlier,
      color = cluster
    )) +
      ggplot2::geom_point(size = 2.3) +
      ggplot2::coord_flip() +
      ggplot2::scale_color_manual(values = colors) +
      ggplot2::labs(title = "HDBSCAN outlier ranking", x = NULL, y = "Outlier score") +
      ggplot2::theme_minimal(base_size = 11)
    plots <- list(probability_plot, rank_plot)
    if (inherits(fit$model$hc, "hclust")) {
      hierarchy_fit <- list(model = fit$model$hc, cluster = clusters)
      plots[[3]] <- build_dendrogram_plot(hierarchy_fit, "HDBSCAN mutual-reachability hierarchy")
    }
    return(list(
      title = "HDBSCAN density diagnostics",
      description = paste0(
        "Membership strength, outlier scores and hierarchy come directly from the ",
        "fitted density model."
      ),
      tab_names = c(
        "Membership & outliers",
        "Outlier ranking",
        "Density hierarchy"
      )[seq_along(plots)],
      plots = plots
    ))
  }

  # LEARNED REPRESENTATION ------------------------------------------------
  if (algorithm == "deep_autoencoder") {
    embedding <- fit$embedding
    latent <- if (ncol(embedding) > 2L) {
      stats::prcomp(embedding,
        center = TRUE,
        scale. = FALSE
      )$x[,
        1:2,
        drop = FALSE
      ]
    } else {
      embedding[,
        1:2,
        drop = FALSE
      ]
    }
    latent_frame <- data.frame(
      series_id = rownames(latent),
      latent_1 = latent[
        ,
        1
      ],
      latent_2 = latent[
        ,
        2
      ],
      cluster = factor(clusters)
    )
    latent_plot <- ggplot2::ggplot(latent_frame, ggplot2::aes(latent_1, latent_2,
      color = cluster,
      text = series_id
    )) +
      ggplot2::geom_point(size = 2.8, alpha = .84) +
      ggplot2::scale_color_manual(values = colors) +
      ggplot2::labs(title = "Learned latent geometry", x = "Latent axis 1", y = "Latent axis 2") +
      ggplot2::theme_minimal(base_size = 11)
    plots <- list(latent_plot)
    tab_names <- "Latent geometry"
    if (!is.null(fit$loss_history)) {
      loss_frame <- data.frame(epoch = seq_along(fit$loss_history), loss = fit$loss_history)
      plots[[length(plots) + 1L]] <- ggplot2::ggplot(loss_frame, ggplot2::aes(epoch, loss)) +
        ggplot2::geom_line(color = palette$primary, linewidth = .9) +
        ggplot2::labs(title = "Autoencoder training loss", x = "Epoch", y = "Reconstruction MSE") +
        ggplot2::theme_minimal(base_size = 11)
      tab_names <- c(tab_names, "Training loss")
    }
    if (!is.null(fit$reconstruction_error)) {
      reconstruction_frame <- data.frame(
        series_id = names(fit$reconstruction_error) %||% rownames(matrix),
        error = as.numeric(fit$reconstruction_error), cluster = factor(clusters)
      )
      plots[[length(plots) + 1L]] <- ggplot2::ggplot(
        reconstruction_frame,
        ggplot2::aes(stats::reorder(series_id, error), error, color = cluster)
      ) +
        ggplot2::geom_point(size = 2.3) +
        ggplot2::coord_flip() +
        ggplot2::scale_color_manual(values = colors) +
        ggplot2::labs(
          title = "Reconstruction error by profile", x = NULL,
          y = "Mean squared error"
        ) +
        ggplot2::theme_minimal(base_size = 11)
      tab_names <- c(tab_names, "Reconstruction error")
    }
    return(list(
      title = "Autoencoder representation learning",
      description = paste0(
        "The latent view and training loss diagnose the nonlinear representation ",
        "fitted before K-means."
      ),
      tab_names = tab_names,
      plots = plots
    ))
  }

  empty_result(
    "Method-specific diagnostics",
    "No dedicated diagnostic is registered.",
    paste(
      "No specific visualization for",
      algorithm
    )
  )
}
