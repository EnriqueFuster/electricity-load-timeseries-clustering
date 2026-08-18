#' Build one of the profile-level data inspection views
#' @param result Active pipeline result.
#' @param series_id Profile identifier.
#' @param view One of annual, weekly, daily, or heatmap.
#' @param palette Application palette.
#' @param ribbon_probs Lower and upper probabilities for recurring-profile bands.
#' @param show_observations Whether recurring views include transparent hourly observations.
#' @return A ggplot object.
build_series_inspection_plot <- function(result, series_id, view = "weekly",
                                         palette = get_app_palette(),
                                         ribbon_probs = c(0.25, 0.75),
                                         show_observations = FALSE) {
  view <- match.arg(view, c("annual", "weekly", "daily", "heatmap"))
  if (
    length(ribbon_probs) != 2L ||
      any(!is.finite(ribbon_probs)) ||
      any(ribbon_probs < 0 | ribbon_probs > 1) ||
      ribbon_probs[1] >= ribbon_probs[2]
  ) {
    stop("ribbon_probs must contain two increasing probabilities between 0 and 1.")
  }
  clean <- result$clean[result$clean$series_id == series_id, , drop = FALSE]
  if (!nrow(clean)) stop("The selected series is not available in the clean dataset.")
  ribbon_label <- sprintf("P%d-P%d", round(ribbon_probs[1] * 100), round(ribbon_probs[2] * 100))

  if (view == "annual") {
    return(
      ggplot2::ggplot(clean, ggplot2::aes(timestamp, value,
        group = 1,
        text = paste0("Time: ", timestamp, "<br>Consumption: ", round(value, 4))
      )) +
        ggplot2::geom_line(color = palette$primary, linewidth = .42) +
        ggplot2::labs(title = "Complete annual hourly curve", x = NULL, y = "Consumption") +
        ggplot2::theme_minimal(base_size = 11)
    )
  }

  if (view == "weekly") {
    calendar <- as.POSIXlt(clean$timestamp, tz = "UTC")
    clean$hour_of_week <- ((calendar$wday + 6L) %% 7L) * 24L + calendar$hour + 1L
    weekly <- summarize_recurring_profile(clean, "hour_of_week", ribbon_probs)
    plot <- ggplot2::ggplot(weekly, ggplot2::aes(
      interval,
      median,
      group = 1,
      text = paste0(
        "Hour of week: ", interval, "<br>Median: ", round(median, 4),
        "<br>", ribbon_label, ": ", round(lower, 4), " – ", round(upper, 4)
      )
    ))
    if (isTRUE(show_observations)) {
      plot <- plot + ggplot2::geom_jitter(
        data = clean,
        ggplot2::aes(hour_of_week, value),
        inherit.aes = FALSE,
        width = .16,
        height = 0,
        alpha = .10,
        size = .65,
        color = palette$primary
      )
    }
    return(
      plot +
        ggplot2::geom_ribbon(ggplot2::aes(ymin = lower, ymax = upper),
          fill = palette$accent, alpha = .30, color = NA
        ) +
        ggplot2::geom_line(color = palette$primary, linewidth = .85) +
        ggplot2::scale_x_continuous(
          breaks = seq(1, 168, 24),
          labels = c("Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun")
        ) +
        ggplot2::labs(
          title = "Typical week", subtitle = paste(
            "Median and", ribbon_label,
            "ribbon across observed weeks"
          ),
          x = NULL, y = "Consumption"
        ) +
        ggplot2::theme_minimal(base_size = 11)
    )
  }

  if (view == "daily") {
    clean$hour_of_day <- as.POSIXlt(clean$timestamp, tz = "UTC")$hour + 1L
    daily <- summarize_recurring_profile(clean, "hour_of_day", ribbon_probs)
    plot <- ggplot2::ggplot(daily, ggplot2::aes(
      interval,
      median,
      group = 1,
      text = paste0(
        "Hour: ", sprintf("%02d:00", interval - 1L),
        "<br>Median: ", round(median, 4), "<br>", ribbon_label, ": ",
        round(lower, 4), " – ", round(upper, 4)
      )
    ))
    if (isTRUE(show_observations)) {
      plot <- plot + ggplot2::geom_jitter(
        data = clean,
        ggplot2::aes(hour_of_day, value),
        inherit.aes = FALSE,
        width = .16,
        height = 0,
        alpha = .10,
        size = .65,
        color = palette$primary
      )
    }
    return(
      plot +
        ggplot2::geom_ribbon(ggplot2::aes(ymin = lower, ymax = upper),
          fill = palette$accent, alpha = .30, color = NA
        ) +
        ggplot2::geom_line(color = palette$primary, linewidth = .95) +
        ggplot2::scale_x_continuous(
          breaks = c(1, 4, 8, 12, 16, 20, 24),
          labels = c("00", "03", "07", "11", "15", "19", "23")
        ) +
        ggplot2::labs(
          title = "Typical day", subtitle = paste(
            "Median and", ribbon_label,
            "ribbon across observed days"
          ),
          x = "Hour of day", y = "Consumption"
        ) +
        ggplot2::theme_minimal(base_size = 11)
    )
  }

  calendar <- as.POSIXlt(clean$timestamp, tz = "UTC")
  clean$day_of_year <- calendar$yday + 1L
  clean$hour_of_day <- calendar$hour
  grid <- expand.grid(day_of_year = seq_len(366L), hour_of_day = 0:23)
  heatmap <- merge(grid, clean[c("day_of_year", "hour_of_day", "value")],
    by = c("day_of_year", "hour_of_day"), all.x = TRUE
  )

  ggplot2::ggplot(heatmap, ggplot2::aes(day_of_year, hour_of_day)) +
    ggplot2::geom_tile(fill = "#ECE8E4") +
    ggplot2::geom_tile(
      data = heatmap[is.finite(heatmap$value), ],
      ggplot2::aes(
        fill = value,
        text = paste0(
          "Day: ", day_of_year, "<br>Hour: ", sprintf("%02d:00", hour_of_day),
          "<br>Consumption: ", round(value, 4)
        )
      )
    ) +
    ggplot2::scale_fill_gradientn(colours = palette$heatmap, na.value = "#ECE8E4") +
    ggplot2::scale_x_continuous(
      breaks = c(1, 32, 60, 91, 121, 152, 182, 213, 244, 274, 305, 335),
      labels = month.abb
    ) +
    ggplot2::scale_y_reverse(breaks = seq(0, 23, 3)) +
    ggplot2::labs(title = "Annual hourly heatmap", x = NULL, y = "Hour", fill = "Consumption") +
    ggplot2::theme_minimal(base_size = 11) +
    ggplot2::theme(panel.grid = ggplot2::element_blank())
}
