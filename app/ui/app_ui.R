build_about_menu <- function() {
  shiny::tags$details(
    class = "about-menu",
    shiny::tags$summary(
      shiny::span("About"),
      shiny::span(class = "about-menu-chevron", `aria-hidden` = "true")
    ),
    shiny::div(
      class = "about-menu-panel",
      shiny::p("This project has been developed by Enrique Fuster."),
      shiny::tags$a(
        class = "about-menu-link",
        href = "https://github.com/EnriqueFuster",
        target = "_blank",
        rel = "noopener noreferrer",
        `aria-label` = "View repository on GitHub",
        shiny::span("View on GitHub"),
        shiny::span(class = "about-menu-arrow", `aria-hidden` = "true", "\u2197")
      )
    )
  )
}

build_app_ui <- function(config) {
  controls <- build_input_workspace()
  experiment_controls <- build_model_design_workspace()

  page <- bslib::page_navbar(
    title = shiny::div(
      class = "brand",
      shiny::tags$img(
        class = "brand-mark",
        src = "load-clustering-assets/electricity-load-clustering-mark.webp",
        alt = ""
      ),
      shiny::div(
        "Electricity Load Clustering",
        shiny::span("Benchmarking clustering methods for hourly load profiles")
      )
    ),
    id = "analysis_tab",
    selected = "Data",
    theme = config$theme,
    window_title = "Electricity Load Clustering",
    # Analytical pages must grow with their charts. A fillable navbar forces
    # every card into the viewport height and creates clipped, scrollable plots.
    fillable = FALSE,
    header = NULL,
    bslib::nav_panel(
      "Prepare data",
      value = "Data",
      shiny::div(
        class = "data-workspace primary-workspace",
        app_section_header(
          "DATA", "Prepare and inspect hourly load profiles",
          paste0(
            "Set the minimum data-quality requirements, then inspect the accepted ",
            "profiles before comparing clustering methods."
          )
        ),
        bslib::navset_card_tab(
          id = "data_workspace",
          selected = "Data preparation",
          bslib::nav_panel("Data preparation", controls),
          bslib::nav_panel("Profile inspection", build_data_inspection_workspace())
        )
      )
    ),
    bslib::nav_panel(
      "Design experiments",
      experiment_controls,
      value = "Experiments"
    ),
    bslib::nav_panel(
      "Analyse results",
      value = "Results",
      shiny::div(
        class = "results-workspace",
        app_section_header(
          "RESULTS", "Compare and interpret the clustering results",
          paste0(
            "Compare the candidate clusterings, then inspect the load patterns and ",
            "validation results for the selected method."
          )
        ),
        bslib::navset_card_tab(
          id = "results_workspace",
          selected = "Selected model analysis",
          build_selected_model_analysis(),
          bslib::nav_panel(
            "Model selection",
            shiny::uiOutput("compatibility_note"),
            build_model_selection_filters(),
            bslib::navset_card_tab(
              title = shiny::div(
                class = "benchmark-card-title",
                shiny::strong("Method comparison"),
                shiny::div(
                  class = "benchmark-legend",
                  shiny::span(class = "legend-recommended"), "Recommended",
                  shiny::span(class = "legend-active"), "Selected result"
                )
              ),
              bslib::nav_panel(
                "Silhouette",
                analysis_plot_output(
                  "silhouette_plot",
                  560
                ),
                model_metric_guide(
                  "Average silhouette",
                  paste0(
                    "For each profile, silhouette compares its average dissimilarity to ",
                    "its own cluster with its average dissimilarity to the nearest competing ",
                    "cluster. The chart displays the mean across assigned profiles."
                  ),
                  paste0(
                    "Values approach 1 for clear assignments, approach 0 at overlapping ",
                    "boundaries and become negative when another cluster is closer. Higher ",
                    "values are generally preferable among defensible candidate methods."
                  ),
                  paste0(
                    "A high value does not prove that clusters are stable, useful or physically ",
                    "meaningful. Simple synthetic profiles can produce values close to one."
                  )
                )
              ),
              bslib::nav_panel(
                "Stability",
                analysis_plot_output(
                  "stability_plot",
                  560
                ),
                model_metric_guide(
                  "Conditional subsample stability",
                  paste0(
                    "The method is refitted on repeated samples containing 80% of profiles. ",
                    "Adjusted Rand index measures whether profiles that reappear are grouped ",
                    "together consistently, irrespective of cluster label numbering."
                  ),
                  paste0(
                    "One indicates identical partitions, values near zero indicate chance-like ",
                    "agreement and negative values indicate systematic disagreement."
                  ),
                  paste0(
                    "Stability can reward a consistently coarse partition. Read it together ",
                    "with separation and the temporal meaning of the groups."
                  )
                )
              ),
              bslib::nav_panel(
                "Runtime",
                analysis_plot_output(
                  "runtime_plot",
                  560
                ),
                model_metric_guide(
                  "Elapsed computation time",
                  paste0(
                    "Seconds required to fit and validate each candidate under the current ",
                    "data size, parameter grid and hardware."
                  ),
                  paste0(
                    "Lower values indicate cheaper methods. Runtime can distinguish similarly ",
                    "credible candidates or show whether a method is practical at scale."
                  ),
                  paste0(
                    "Runtime is not clustering quality and changes with hardware, sample size, ",
                    "installed libraries and the number of stability repetitions."
                  )
                )
              ),
              bslib::nav_panel(
                "Cluster balance",
                analysis_plot_output(
                  "balance_plot",
                  560
                ),
                model_metric_guide(
                  "Cluster-size balance",
                  paste0(
                    "Divides the number of profiles in the smallest non-noise cluster by ",
                    "the number in the largest."
                  ),
                  paste0(
                    "One means equally sized clusters. Values near zero mean at least one group ",
                    "is much smaller than the dominant group and should be inspected."
                  ),
                  paste0(
                    "Electricity populations need not be balanced. A small cluster may represent ",
                    "a valid rare technology, tariff or operating pattern."
                  )
                )
              ),
              bslib::nav_panel(
                "Dunn index",
                analysis_plot_output(
                  "dunn_plot",
                  560
                ),
                model_metric_guide(
                  "Dunn index",
                  paste0(
                    "Divides the smallest distance between different clusters by the largest ",
                    "diameter inside any cluster. It rewards compact groups separated by a gap."
                  ),
                  paste0(
                    "Higher values are preferable. A low value can arise from overlapping groups ",
                    "or from one very dispersed cluster."
                  ),
                  paste0(
                    "Because Dunn uses extreme distances, one unusual profile can change it ",
                    "substantially. Compare only compatible distance definitions."
                  )
                )
              ),
              bslib::nav_panel(
                "Smallest cluster",
                analysis_plot_output(
                  "smallest_share_plot",
                  560
                ),
                model_metric_guide(
                  "Smallest-cluster share",
                  paste0(
                    "Percentage of accepted profiles contained in the smallest retained ",
                    "cluster. Noise profiles are not treated as a cluster."
                  ),
                  paste0(
                    "Larger values indicate that every group has reasonable sample support. ",
                    "Compare it with the minimum-cluster-share eligibility filter."
                  ),
                  paste0(
                    "This measures support, not usefulness. A legitimate rare group may fall ",
                    "below a generic threshold and still deserve inspection."
                  )
                )
              ),
              bslib::nav_panel(
                "Noise",
                analysis_plot_output(
                  "noise_share_plot",
                  560
                ),
                model_metric_guide(
                  "Unassigned or noise share",
                  paste0(
                    "Fraction of profiles that a density-based method does not place inside a ",
                    "sufficiently supported cluster."
                  ),
                  paste0(
                    "For HDBSCAN, some noise can be informative because unusual profiles are not ",
                    "forced into a group. Partitioning methods normally show zero because they ",
                    "assign every profile."
                  ),
                  paste0(
                    "Lower is not automatically better. A zero from K-means or PAM does not mean ",
                    "that every assignment is reliable."
                  )
                )
              ),
              bslib::nav_panel(
                "Results table",
                result_tab_guide(
                  "Compare the complete evidence for every filtered candidate",
                  paste0(
                    "Each row is one fitted method configuration. Columns describe its ",
                    "representation, distance, algorithm, group count, validation evidence ",
                    "and computational cost."
                  ),
                  paste0(
                    "Combine the filters above to restrict rows and use the variable panel to ",
                    "choose columns. Cell colours compare values within a numeric column; they ",
                    "do not imply that larger is always better."
                  )
                ),
                table_variable_selector("metrics_table_columns"),
                shiny::div(class = "results-table-shell", DT::DTOutput("metrics_table"))
              )
            )
          ),
          bslib::nav_spacer(),
          bslib::nav_item(build_results_model_dock()),
        )
      ),
    ),
    bslib::nav_panel(
      "Learn methods",
      value = "Learn",
      build_theory_center()
    ),
    bslib::nav_spacer(),
    bslib::nav_item(build_about_menu())
  )

  # Keep application styles independent of the directory used to launch Shiny.
  # This matters when app.R is sourced from the project root instead of runApp("app").
  shiny::tagList(
    shiny::tags$head(
      shiny::tags$link(
        rel = "icon",
        href = "load-clustering-assets/electricity-load-clustering-favicon.ico",
        sizes = "any"
      ),
      shiny::tags$link(
        rel = "apple-touch-icon",
        href = "load-clustering-assets/electricity-load-clustering-touch-icon.png"
      ),
      shiny::includeCSS(file.path(config$root, "app", "www", "styles.css")),
      shiny::tags$script(shiny::HTML(
        "$(document).on('shiny:inputchanged', function(event) {
          if (event.name !== 'visualization_mode') return;
          window.setTimeout(function() {
            document.querySelectorAll('.js-plotly-plot').forEach(function(plot) {
              if (window.Plotly && plot.offsetParent !== null) Plotly.Plots.resize(plot);
            });
            window.dispatchEvent(new Event('resize'));
          }, 300);
        });
        document.addEventListener('click', function(event) {
          var dock = document.querySelector('.results-model-dock[open]');
          if (dock && !dock.contains(event.target)) dock.removeAttribute('open');
          var about = document.querySelector('.about-menu[open]');
          if (about && !about.contains(event.target)) about.removeAttribute('open');
        });
        document.addEventListener('keydown', function(event) {
          if (event.key !== 'Escape') return;
          var dock = document.querySelector('.results-model-dock[open]');
          if (dock) dock.removeAttribute('open');
          var about = document.querySelector('.about-menu[open]');
          if (about) about.removeAttribute('open');
        });
        $(document).on('shiny:value', function(event) {
          var element = event.target;
          if (!element || !element.classList || !element.classList.contains('plotly')) return;
          var shell = element.closest('.interactive-chart-shell');
          if (shell) shell.classList.add('plotly-ready');
          window.setTimeout(function() {
            if (window.Plotly && element.offsetParent !== null) Plotly.Plots.resize(element);
          }, 0);
        });"
      ))
    ),
    page
  )
}
