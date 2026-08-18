#' Build an efficient native Plotly calendar heatmap
#'
#' ggplotly converts every geom_tile cell into polygon geometry. For annual
#' calendars this can block the Shiny session while tens of thousands of SVG
#' shapes are serialized. Native heatmap traces transmit one compact matrix per
#' cluster instead.
#' @param heatmap_data Output from calculate_cluster_calendar_heatmap().
#' @param colours Sequential colour palette.
#' @return Plotly widget with one vertically stacked heatmap per cluster.
build_calendar_heatmap_widget <- function(heatmap_data, colours = get_app_palette()$heatmap) {
  clusters <- sort(unique(heatmap_data$cluster))
  observed_values <- heatmap_data$relative_intensity[heatmap_data$observed]
  upper_limit <- stats::quantile(observed_values, 0.99, na.rm = TRUE, names = FALSE)
  if (!is.finite(upper_limit) || upper_limit <= 0) upper_limit <- 1

  panels <- lapply(seq_along(clusters), function(index) {
    cluster_id <- clusters[index]
    cluster_data <- heatmap_data[heatmap_data$cluster == cluster_id, ]
    cluster_data <- cluster_data[order(cluster_data$day_of_year, cluster_data$hour_of_day), ]

    intensity <- matrix(cluster_data$relative_intensity, nrow = 24L, ncol = 366L)
    consumption <- matrix(cluster_data$mean_consumption, nrow = 24L, ncol = 366L)

    plotly::plot_ly(
      x = seq_len(366L), y = 0:23, z = intensity,
      customdata = consumption,
      type = "heatmap", colors = colours, zmin = 0, zmax = upper_limit,
      showscale = index == 1L,
      colorbar = list(title = "Relative<br>intensity", thickness = 12),
      hovertemplate = paste(
        "Cluster", cluster_id,
        "<br>Day %{x}<br>Hour %{y}:00",
        "<br>Relative intensity %{z:.2f}",
        "<br>Mean consumption %{customdata:.3f}<extra></extra>"
      )
    ) |>
      plotly::layout(
        title = list(text = paste("Cluster", cluster_id), x = 0.01, font = list(size = 13)),
        xaxis = list(
          tickmode = "array",
          tickvals = c(1, 32, 61, 92, 122, 153, 183, 214, 245, 275, 306, 336),
          ticktext = month.abb,
          title = ""
        ),
        yaxis = list(autorange = "reversed", tickvals = seq(0, 23, 3), title = "Hour")
      )
  })

  widget <- plotly::subplot(
    panels,
    nrows = length(panels), shareX = TRUE, shareY = TRUE,
    titleX = TRUE, titleY = TRUE, margin = 0.035
  )
  plotly::layout(
    widget,
    paper_bgcolor = "#FFFFFF", plot_bgcolor = "#F2F4F8",
    margin = list(l = 55, r = 70, t = 35, b = 45),
    hoverlabel = list(bgcolor = "#FFFFFF", font = list(color = "#1D293F"))
  )
}
