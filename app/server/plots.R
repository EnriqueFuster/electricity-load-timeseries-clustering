series_inspection_plot <- shiny::reactive({
  shiny::req(input$series, input$series_view, input$series_ribbon)
  build_series_inspection_plot(
    active_result(), input$series, input$series_view, config$palette,
    ribbon_probs = input$series_ribbon / 100,
    show_observations = isTRUE(input$series_jitter)
  )
})
output$series_view_plot <- plotly::renderPlotly({
  plotly::ggplotly(series_inspection_plot(), tooltip = c("text", "x", "y", "fill"))
})

output$prototype_plot <- plotly::renderPlotly(plotly::ggplotly(active_analysis()$plots$prototypes,
  tooltip = c(
    "x",
    "y",
    "colour"
  )
))
cluster_profile_view <- shiny::reactive({
  shiny::req(input$profile_horizon)
  build_cluster_profile_view(active_result(), input$profile_horizon, profile_band_probs())
})
cluster_profile_plot <- shiny::reactive({
  plot_cluster_profile_view(
    cluster_profile_view(),
    config$palette,
    show_observations = isTRUE(input$profile_jitter)
  )
})
output$profile_ribbon_context <- shiny::renderUI({
  view <- cluster_profile_view()
  probabilities <- round(view$probs * 100)
  shiny::div(
    class = "profile-ribbon-context",
    shiny::span(class = "ribbon-swatch"),
    shiny::strong(sprintf("P%d-P%d uncertainty band", probabilities[1], probabilities[2])),
    shiny::span(sprintf(
      paste0(
        "Computed from %s. Median band width %.3f normalized units; %.1f%% of ",
        "intervals have a non-zero band."
      ),
      view$ribbon_basis, view$ribbon_width$median, 100 * view$ribbon_width$positive_share
    ))
  )
})

output$cluster_members_plot <- plotly::renderPlotly({
  plotly::ggplotly(cluster_profile_plot(), tooltip = c("text", "x", "y", "fill"))
})
output$silhouette_plot <- plotly::renderPlotly(plotly::ggplotly(benchmark_plots()$silhouette,
  tooltip = c(
    "x",
    "y",
    "colour"
  )
))
output$stability_plot <- plotly::renderPlotly(plotly::ggplotly(benchmark_plots()$stability,
  tooltip = c(
    "x",
    "y",
    "colour"
  )
))
output$runtime_plot <- plotly::renderPlotly(plotly::ggplotly(benchmark_plots()$runtime,
  tooltip = c(
    "x",
    "y",
    "colour"
  )
))
output$dunn_plot <- plotly::renderPlotly(plotly::ggplotly(benchmark_plots()$dunn, tooltip = c(
  "x",
  "y", "colour"
)))
output$smallest_share_plot <- plotly::renderPlotly(
  plotly::ggplotly(
    benchmark_plots()$smallest_share,
    tooltip = c(
      "x",
      "y",
      "colour"
    )
  )
)
output$noise_share_plot <- plotly::renderPlotly(plotly::ggplotly(benchmark_plots()$noise_share,
  tooltip = c(
    "x",
    "y",
    "colour"
  )
))
output$balance_plot <- plotly::renderPlotly({
  metrics <- comparison_metrics()
  colors <- config$palette$algorithms[intersect(
    names(config$palette$algorithms),
    unique(metrics$algorithm)
  )]
  plot <- ggplot2::ggplot(metrics, ggplot2::aes(k, cluster_balance,
    color = algorithm, linetype = representation,
    shape = distance, group = interaction(recipe, representation)
  )) +
    ggplot2::geom_line(linewidth = .8) +
    ggplot2::geom_point(size = 2.4) +
    ggplot2::scale_color_manual(values = colors) +
    ggplot2::scale_shape_manual(values = c(
      euclidean = 16, manhattan = 17, dtw_basic = 15, sbd = 18,
      model_based = 3, soft_dtw = 8, latent_euclidean = 7
    )) +
    ggplot2::geom_point(
      data = metrics[metrics$model_key == benchmark_run()$result$benchmark_recommendation_key, ],
      shape = 21,
      fill = "white",
      stroke = 1.25,
      size = 4.8
    ) +
    ggplot2::geom_point(
      data = metrics[metrics$model_key == active_result()$recommended$model_key, ],
      shape = 23,
      fill = config$palette$accent,
      color = config$palette$ink,
      size = 4.1
    ) +
    ggplot2::labs(y = "Smallest / largest cluster", title = "Cluster-size balance") +
    ggplot2::theme_minimal(base_size = 11)
  plotly::ggplotly(plot)
})
output$pca_plot <- plotly::renderPlotly(plotly::ggplotly(active_analysis()$plots$pca,
  tooltip = c(
    "text",
    "x",
    "y",
    "colour"
  )
))
output$silhouette_detail_plot <- plotly::renderPlotly(
  plotly::ggplotly(
    active_analysis()$plots$silhouette_detail,
    tooltip = c(
      "text",
      "x",
      "y"
    )
  )
)
output$peer_distance_plot <- plotly::renderPlotly(
  plotly::ggplotly(
    active_analysis()$plots$peer_distance,
    tooltip = c(
      "text",
      "x",
      "y"
    )
  )
)
output$dissimilarity_plot <- plotly::renderPlotly(
  plotly::ggplotly(
    active_analysis()$plots$dissimilarity,
    tooltip = c(
      "text",
      "fill"
    )
  )
)
output$cluster_heatmap_plot <- plotly::renderPlotly({
  build_calendar_heatmap_widget(active_result()$cluster_heatmap, config$palette$heatmap)
})
output$size_plot <- plotly::renderPlotly(plotly::ggplotly(active_analysis()$plots$cluster_sizes,
  tooltip = c(
    "x",
    "y"
  )
))
output$atypicality_plot <- plotly::renderPlotly(
  plotly::ggplotly(
    active_analysis()$plots$atypicality,
    tooltip = c(
      "x",
      "y",
      "colour"
    )
  )
)
algorithm_plot_at <- function(index) {
  plots <- algorithm_analysis()$plots
  shiny::validate(shiny::need(
    length(plots) >= index,
    "No additional plot is required for this method."
  ))
  plots[[index]]
}
output$algorithm_plot_1 <- plotly::renderPlotly(plotly::ggplotly(algorithm_plot_at(1L),
  tooltip = c(
    "text",
    "x",
    "y",
    "fill",
    "colour",
    "size"
  )
))
output$algorithm_plot_2 <- plotly::renderPlotly(plotly::ggplotly(algorithm_plot_at(2L),
  tooltip = c(
    "text",
    "x",
    "y",
    "fill",
    "colour",
    "size"
  )
))
output$algorithm_plot_3 <- plotly::renderPlotly(plotly::ggplotly(algorithm_plot_at(3L),
  tooltip = c(
    "text",
    "x",
    "y",
    "fill",
    "colour",
    "size"
  )
))

# Static rendering is the reliable default. Plotly remains available from
# the shared chart-rendering selector without being a single point of
# failure for the analytical results.
output$prototype_plot_static <- shiny::renderPlot(active_analysis()$plots$prototypes, res = 110)
output$cluster_members_plot_static <- shiny::renderPlot(cluster_profile_plot(), res = 110)
output$silhouette_plot_static <- shiny::renderPlot(benchmark_plots()$silhouette, res = 110)
output$stability_plot_static <- shiny::renderPlot(benchmark_plots()$stability, res = 110)
output$runtime_plot_static <- shiny::renderPlot(benchmark_plots()$runtime, res = 110)
output$dunn_plot_static <- shiny::renderPlot(benchmark_plots()$dunn, res = 110)
output$smallest_share_plot_static <- shiny::renderPlot(benchmark_plots()$smallest_share, res = 110)
output$noise_share_plot_static <- shiny::renderPlot(benchmark_plots()$noise_share, res = 110)
output$pca_plot_static <- shiny::renderPlot(active_analysis()$plots$pca, res = 110)
output$size_plot_static <- shiny::renderPlot(active_analysis()$plots$cluster_sizes, res = 110)
output$atypicality_plot_static <- shiny::renderPlot(active_analysis()$plots$atypicality, res = 110)
output$silhouette_detail_plot_static <- shiny::renderPlot(
  active_analysis()$plots$silhouette_detail,
  res = 110
)
output$peer_distance_plot_static <- shiny::renderPlot(active_analysis()$plots$peer_distance,
  res = 110
)
output$dissimilarity_plot_static <- shiny::renderPlot(active_analysis()$plots$dissimilarity,
  res = 110
)
output$cluster_heatmap_plot_static <- shiny::renderPlot(active_analysis()$plots$cluster_heatmap,
  res = 110
)
output$algorithm_plot_1_static <- shiny::renderPlot(algorithm_plot_at(1L), res = 110)
output$algorithm_plot_2_static <- shiny::renderPlot(algorithm_plot_at(2L), res = 110)
output$algorithm_plot_3_static <- shiny::renderPlot(algorithm_plot_at(3L), res = 110)

output$series_view_plot_static <- shiny::renderPlot(series_inspection_plot(), res = 110)

output$balance_plot_static <- shiny::renderPlot(
  {
    metrics <- comparison_metrics()
    colors <- config$palette$algorithms[intersect(
      names(config$palette$algorithms),
      unique(metrics$algorithm)
    )]
    ggplot2::ggplot(metrics, ggplot2::aes(k, cluster_balance,
      color = algorithm, linetype = representation,
      shape = distance, group = interaction(recipe, representation)
    )) +
      ggplot2::geom_line(linewidth = .8) +
      ggplot2::geom_point(size = 2.4) +
      ggplot2::scale_color_manual(values = colors) +
      ggplot2::scale_shape_manual(values = c(
        euclidean = 16, manhattan = 17, dtw_basic = 15, sbd = 18,
        model_based = 3, soft_dtw = 8, latent_euclidean = 7
      )) +
      ggplot2::geom_point(
        data = metrics[metrics$model_key == benchmark_run()$result$benchmark_recommendation_key, ],
        shape = 21, fill = "white", stroke = 1.25, size = 4.8
      ) +
      ggplot2::geom_point(
        data = metrics[metrics$model_key == active_result()$recommended$model_key, ],
        shape = 23, fill = config$palette$accent, color = config$palette$ink, size = 4.1
      ) +
      ggplot2::labs(y = "Smallest / largest cluster", title = "Cluster-size balance") +
      ggplot2::theme_minimal(base_size = 11)
  },
  res = 110
)
