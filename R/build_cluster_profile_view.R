#' Prepare cluster curves for a selected time horizon
#'
#' The clustering result is not refitted here. This function only changes the
#' time scale used to inspect the members of the active clusters.
#' @param result Output from run_clustering_pipeline().
#' @param horizon One of daily, weekly, or annual.
#' @param probs Lower and upper probabilities used for the profile ribbon.
#' @return A list with member curves, hourly summaries and axis metadata.
build_cluster_profile_view <- function(result, horizon = "weekly", probs = c(0.25, 0.75)) {
  horizon <- match.arg(horizon, c("daily", "weekly", "annual"))
  invalid_probabilities <- length(probs) != 2L ||
    any(!is.finite(probs)) ||
    any(probs < 0 | probs > 1) ||
    probs[1] >= probs[2]

  if (invalid_probabilities) {
    stop("probs must contain two increasing probabilities between 0 and 1.")
  }
  normalization <- result$config$preprocessing$normalization

  if (horizon == "daily") {
    daily <- result$clean
    daily$interval <- as.integer(format(daily$timestamp, "%H", tz = "UTC")) + 1L
    daily <- stats::aggregate(value ~ series_id + interval, daily, stats::median, na.rm = TRUE)
    matrix <- long_profile_to_matrix(daily, 24L)
    axis <- list(
      label = "Hour of day", breaks = c(1, 4, 8, 12, 16, 20, 24),
      labels = c("00", "03", "07", "11", "15", "19", "23")
    )
  } else if (horizon == "weekly") {
    matrix <- result$weekly_matrix
    axis <- list(
      label = "Hour of week", breaks = seq(1, 168, 24),
      labels = c("Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun")
    )
  } else {
    matrix <- normalize_load_curve(build_annual_hourly_matrix(result$clean), normalization)
    axis <- list(label = "Month", breaks = c(
      1, 745, 1417, 2161, 2881, 3625,
      4345, 5089, 5833, 6553, 7297, 8017
    ), labels = month.abb)
  }

  if (horizon == "daily") matrix <- normalize_load_curve(matrix, normalization)
  assignments <- result$assignments[c("series_id", "cluster")]
  members <- data.frame(
    series_id = rep(rownames(matrix), each = ncol(matrix)),
    interval = rep(seq_len(ncol(matrix)), nrow(matrix)),
    normalized_value = as.vector(t(matrix)),
    stringsAsFactors = FALSE
  )
  members <- merge(members, assignments, by = "series_id", sort = FALSE)
  members <- members[order(members$cluster, members$series_id, members$interval), ]

  ribbon_observations <- if (horizon %in% c("daily", "weekly")) {
    build_cluster_ribbon_observations(result, horizon, normalization)
  } else {
    members
  }
  summaries <- do.call(rbind, lapply(split(
    ribbon_observations,
    list(ribbon_observations$cluster, ribbon_observations$interval)
  ), function(values) {
    data.frame(
      cluster = values$cluster[1], interval = values$interval[1],
      lower = stats::quantile(values$normalized_value, probs[1], na.rm = TRUE, names = FALSE),
      median = stats::median(values$normalized_value, na.rm = TRUE),
      upper = stats::quantile(values$normalized_value, probs[2], na.rm = TRUE, names = FALSE)
    )
  }))

  widths <- summaries$upper - summaries$lower
  list(
    members = members,
    observations = ribbon_observations,
    summaries = summaries,
    axis = axis,
    horizon = horizon,
    probs = probs,
    ribbon_basis = if (horizon %in% c(
      "daily",
      "weekly"
    )) {
      "source observations"
    } else {
      "member profiles"
    },
    ribbon_width = list(
      median = stats::median(widths, na.rm = TRUE),
      maximum = max(widths, na.rm = TRUE),
      positive_share = mean(widths > sqrt(.Machine$double.eps), na.rm = TRUE)
    )
  )
}

# Preserve within-profile calendar variability in recurring cluster bands.
# Computing percentiles from already-aggregated typical curves would smooth the
# interval twice and can collapse a genuine ribbon into a line.
build_cluster_ribbon_observations <- function(result, horizon, normalization) {
  annual_matrix <- normalize_load_curve(build_annual_hourly_matrix(result$clean), normalization)
  observations <- do.call(rbind, lapply(rownames(annual_matrix), function(series_id) {
    series <- result$clean[result$clean$series_id == series_id, , drop = FALSE]
    series <- series[format(series$timestamp, "%m-%d", tz = "UTC") != "02-29", , drop = FALSE]
    series <- series[order(series$timestamp), , drop = FALSE]
    if (nrow(series) != ncol(annual_matrix)) {
      stop("Ribbon observations could not be aligned to the annual matrix.")
    }
    calendar <- as.POSIXlt(series$timestamp, tz = "UTC")
    interval <- if (horizon == "daily") {
      calendar$hour + 1L
    } else {
      ((calendar$wday + 6L) %% 7L) * 24L + calendar$hour + 1L
    }
    data.frame(
      series_id = series_id,
      interval = interval,
      normalized_value = as.numeric(annual_matrix[series_id, ]),
      stringsAsFactors = FALSE
    )
  }))
  assignments <- result$assignments[c("series_id", "cluster")]
  merge(observations, assignments, by = "series_id", sort = FALSE)
}

# Convert an equally spaced long profile into a series-by-interval matrix.
long_profile_to_matrix <- function(data, intervals) {
  ids <- sort(unique(data$series_id))
  output <- matrix(NA_real_, nrow = length(ids), ncol = intervals, dimnames = list(ids, NULL))
  output[cbind(match(data$series_id, ids), data$interval)] <- data$value
  if (any(!is.finite(output))) stop("The profile view contains incomplete hourly intervals.")
  output
}

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
