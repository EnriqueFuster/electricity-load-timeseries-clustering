analysis_plot_output <- function(id, height) {
  shiny::div(
    class = "chart-output-container",
    `data-chart-height` = height,
    shiny::uiOutput(paste0(id, "_container"))
  )
}

summary_metric <- function(title, output_id, icon, accent_class, description) {
  shiny::div(
    class = paste("summary-metric", accent_class),
    shiny::div(class = "summary-metric-icon", bsicons::bs_icon(icon)),
    shiny::div(
      class = "summary-metric-copy",
      shiny::span(class = "summary-metric-label", title),
      shiny::div(class = "summary-metric-value", shiny::textOutput(output_id,
        container = shiny::span
      )),
      shiny::p(class = "summary-metric-description", description)
    )
  )
}

table_variable_selector <- function(id) {
  shiny::tags$details(
    class = "table-variable-panel",
    shiny::tags$summary(
      bsicons::bs_icon("layout-three-columns"),
      shiny::div(
        shiny::strong("Variables in table"),
        shiny::span("Remove a chip to hide a column; open the menu to restore hidden columns")
      ),
      bsicons::bs_icon("chevron-down")
    ),
    shiny::div(
      class = "table-variable-selector",
      shiny::selectizeInput(
        id, NULL,
        choices = NULL, multiple = TRUE, width = "100%",
        options = list(
          plugins = list("remove_button"),
          placeholder = "Add or remove columns",
          persist = FALSE,
          closeAfterSelect = FALSE,
          hideSelected = TRUE,
          dropdownParent = "body",
          dropdownClass = "selectize-dropdown table-variable-dropdown"
        )
      )
    )
  )
}

build_data_inspection_workspace <- function() {
  shiny::div(
    bslib::navset_card_tab(
      title = "Data inspection workspace",
      bslib::nav_panel(
        "Curve explorer",
        shiny::div(
          class = "data-explorer-toolbar",
          shiny::selectInput("series", help_label("Profile to inspect", "series"), choices = NULL),
          shiny::selectInput("series_view", help_label("Time horizon and view", "series_view"),
            choices = c(
              "Annual curve · 8,760 hourly values" = "annual",
              "Typical week · 168 hours" = "weekly",
              "Typical day · 24 hours" = "daily", "Annual heatmap · day × hour" = "heatmap"
            ), selected = "weekly"
          ),
          shiny::sliderInput("series_ribbon", help_label(
            "Recurring-profile ribbon",
            "series_ribbon"
          ),
          min = 1, max = 99, value = c(25, 75), step = 1
          ),
          shiny::conditionalPanel(
            condition = "input.series_view === 'daily' || input.series_view === 'weekly'",
            class = "jitter-control",
            shiny::checkboxInput(
              "series_jitter",
              help_label("Show hourly observations", "series_jitter"),
              value = FALSE
            )
          ),
          shiny::div(
            class = "toolbar-context", bsicons::bs_icon("info-circle"),
            paste0(
              "The percentile ribbon summarizes repeated weeks or days. Annual curve and ",
              "heatmap views contain one value per timestamp, so no repetition-based ",
              "ribbon is drawn."
            )
          )
        ),
        analysis_plot_output("series_view_plot", 720)
      ),
      bslib::nav_panel(
        "Quality records",
        shiny::div(
          class = "quality-tab-intro", shiny::strong("Quality gate and profile distribution"),
          shiny::span(paste0(
            "The table combines quality checks with minimum, Q1, mean, median, Q3 and ",
            "maximum observed consumption for every evaluated profile."
          ))
        ),
        table_variable_selector("quality_table_columns"),
        shiny::div(class = "quality-table-panel quality-table-full", DT::DTOutput("quality_table"))
      )
    )
  )
}

result_tab_guide <- function(title, purpose, interpretation) {
  shiny::div(
    class = "result-tab-guide",
    shiny::div(
      shiny::span("PURPOSE"),
      shiny::strong(title),
      shiny::p(purpose)
    ),
    shiny::div(
      shiny::span("HOW TO USE IT"),
      shiny::p(interpretation)
    )
  )
}

build_model_selection_filters <- function() {
  shiny::tags$details(
    class = "model-selection-filter-panel",
    shiny::tags$summary(
      bsicons::bs_icon("funnel"),
      shiny::div(
        shiny::strong("Filter compared methods"),
        shiny::span("Combine filters; an empty selector means all available values")
      ),
      bsicons::bs_icon("chevron-down")
    ),
    shiny::div(
      class = "model-selection-filter-grid",
      shiny::selectizeInput(
        "comparison_representation",
        "Representation",
        choices = NULL,
        multiple = TRUE,
        options = list(
          placeholder = "All representations",
          dropdownParent = "body",
          dropdownClass = "selectize-dropdown model-filter-dropdown"
        )
      ),
      shiny::selectizeInput(
        "comparison_algorithm",
        "Algorithm family",
        choices = NULL,
        multiple = TRUE,
        options = list(
          placeholder = "All algorithms",
          dropdownParent = "body",
          dropdownClass = "selectize-dropdown model-filter-dropdown"
        )
      ),
      shiny::selectizeInput(
        "comparison_distance",
        "Distance / similarity",
        choices = NULL,
        multiple = TRUE,
        options = list(
          placeholder = "All distances",
          dropdownParent = "body",
          dropdownClass = "selectize-dropdown model-filter-dropdown"
        )
      ),
      shiny::selectizeInput(
        "comparison_k",
        "Number of clusters",
        choices = NULL,
        multiple = TRUE,
        options = list(
          placeholder = "All values of k",
          dropdownParent = "body",
          dropdownClass = "selectize-dropdown model-filter-dropdown"
        )
      ),
      shiny::selectizeInput(
        "comparison_status",
        "Fit status",
        choices = c(
          "Successful" = "ok",
          "Failed" = "error"
        ),
        multiple = TRUE,
        options = list(
          placeholder = "All fit statuses",
          dropdownParent = "body",
          dropdownClass = "selectize-dropdown model-filter-dropdown"
        )
      ),
      shiny::selectInput(
        "comparison_scope",
        "Candidate emphasis",
        choices = c(
          "All matching candidates" = "all",
          "Recommended and selected" = "highlighted",
          "Recommended only" = "recommended",
          "Selected result only" = "active"
        ),
        selected = "all"
      )
    ),
    shiny::div(
      class = "model-selection-filter-note",
      bsicons::bs_icon("info-circle"),
      shiny::span(
        paste0(
          "The same filters are applied to every comparison chart and the results table. ",
          "They only change what is displayed; fitted results and the recommendation remain ",
          "unchanged."
        )
      )
    )
  )
}

diagnostic_reading_note <- function(title, text) {
  shiny::div(
    class = "diagnostic-reading-note",
    bsicons::bs_icon("book"),
    shiny::p(
      shiny::strong(title),
      text
    )
  )
}

model_metric_guide <- function(title, definition, reading, caution) {
  shiny::div(
    class = "model-metric-guide",
    shiny::div(
      shiny::span("WHAT IT MEASURES"),
      shiny::strong(title),
      shiny::p(definition)
    ),
    shiny::div(
      shiny::span("HOW TO READ THE CHART"),
      shiny::p(reading)
    ),
    shiny::div(
      shiny::span("LIMITATION"),
      shiny::p(caution)
    )
  )
}

build_selected_model_analysis <- function() {
  bslib::nav_panel(
    "Selected model analysis",
    shiny::uiOutput("diagnostics_context"),
    bslib::navset_card_tab(
      title = "Selected clustering result",
      selected = "Executive summary",
      bslib::nav_panel(
        "Executive summary",
        result_tab_guide(
          "Initial assessment of the selected clustering result",
          paste0(
            "Brings together the principal diagnostics for one fitted method: group ",
            "count, separation, stability, smallest-cluster share and unassigned profiles."
          ),
          paste0(
            "Use it to identify the main strengths and warnings before opening the ",
            "detailed tabs. No single metric establishes that the groups are useful."
          )
        ),
        shiny::div(
          class = "summary-metric-grid summary-metric-grid-nine",
          summary_metric(
            "Algorithm", "active_algorithm", "diagram-3", "metric-blue",
            "Method used for the selected result."
          ),
          summary_metric(
            "Clusters", "active_clusters", "collection", "metric-coral",
            "Number of groups, excluding noise."
          ),
          summary_metric(
            "Silhouette", "recommended_silhouette", "activity", "metric-indigo",
            "Mean cohesion and separation, from -1 to 1."
          ),
          summary_metric(
            "Stability", "recommended_stability", "repeat", "metric-violet",
            "Agreement across conditional subsamples."
          ),
          summary_metric(
            "Smallest cluster", "active_smallest_cluster", "pie-chart", "metric-blue",
            "Share assigned to the least common group."
          ),
          summary_metric(
            "Noise", "active_noise", "exclamation-circle", "metric-coral",
            "Share left unassigned by the method."
          ),
          summary_metric(
            "Separation", "active_separation", "arrows-angle-expand", "metric-indigo",
            "Mean silhouette for the selected partition."
          ),
          summary_metric(
            "Repeatability", "active_repeatability", "arrow-repeat", "metric-violet",
            "Conditional subsample stability score."
          ),
          summary_metric(
            "Concentration", "active_concentration", "bar-chart", "metric-coral",
            "Share assigned to the largest cluster."
          )
        ),
        bslib::card(
          class = "executive-conclusion-card",
          bslib::card_header(help_header("Result interpretation", paste0(
            "Counts, cluster distribution and the profile with the highest ",
            "within-cluster atypicality percentile."
          ))),
          shiny::uiOutput("conclusions")
        )
      ),
      bslib::nav_panel(
        "Temporal patterns",
        result_tab_guide(
          "Translate numerical clusters into hourly load behaviour",
          paste0(
            "Shows the median daily, weekly or annual profile of each cluster, its ",
            "between-profile uncertainty and its calendar distribution."
          ),
          paste0(
            "Use these views to decide whether the numerical groups correspond to ",
            "recognisable and operationally meaningful consumption patterns."
          )
        ),
        shiny::div(class = "temporal-view-switcher", bslib::navset_tab(
          id = "temporal_patterns_view",
          selected = "Profiles & ribbons",
          bslib::nav_panel(
            "Profiles & ribbons",
            bslib::card(
              full_screen = TRUE,
              bslib::card_header(
                class = "profile-card-header profile-card-header-integrated",
                help_header("Synthetic profiles and uncertainty ribbons", paste0(
                  "The strong line is the cluster median and the shaded band is the selected ",
                  "percentile interval. Associated member curves remain available for ",
                  "download."
                )),
                shiny::div(
                  class = "profile-card-controls",
                  shiny::selectInput("profile_horizon", "Time horizon",
                    choices = c(
                      "Daily · 24 hours" = "daily",
                      "Weekly · 168 hours" = "weekly",
                      "Annual · 8,760 hours" = "annual"
                    ),
                    selected = "weekly", width = "220px"
                  ),
                  shiny::sliderInput("profile_band", help_label(
                    "Ribbon percentile limits",
                    "profile_band"
                  ),
                  min = 1, max = 99, value = c(25, 75), step = 1, width = "330px"
                  ),
                  shiny::conditionalPanel(
                    condition = paste0(
                      "input.profile_horizon === 'daily' || ",
                      "input.profile_horizon === 'weekly'"
                    ),
                    class = "jitter-control",
                    shiny::checkboxInput(
                      "profile_jitter",
                      help_label("Show hourly observations", "profile_jitter"),
                      value = FALSE
                    )
                  )
                )
              ),
              shiny::uiOutput("profile_ribbon_context"),
              analysis_plot_output("cluster_members_plot", 820),
              bslib::card_footer(
                help_action(
                  shiny::downloadButton("download_profiles",
                    "Synthetic profiles",
                    class = "download-button compact-download"
                  ),
                  "Download the median and displayed percentile interval."
                ),
                help_action(
                  shiny::downloadButton("download_members",
                    "Associated curves",
                    class = "download-button compact-download"
                  ),
                  "Download every normalized member curve for the displayed horizon."
                )
              )
            )
          ),
          bslib::nav_panel(
            "Annual calendar",
            shiny::div(
              class = "diagnostic-panel", help_header("Annual calendar intensity", paste0(
                "Cluster-relative mean consumption by day-of-year and hour for the active ",
                "model. Grey means absent, not zero."
              )),
              analysis_plot_output("cluster_heatmap_plot", 860),
              shiny::div(
                class = "diagnostic-actions", shiny::uiOutput("heatmap_coverage"),
                help_action(
                  shiny::downloadButton("download_heatmap",
                    "Heatmap data",
                    class = "download-button compact-download"
                  ),
                  "Download day-of-year × hour intensity values."
                )
              )
            )
          )
        ))
      ),
      bslib::nav_panel(
        "Cluster map & sizes",
        result_tab_guide(
          "Inspect global geometry and cluster prevalence",
          paste0(
            "The PCA map compresses the selected method's numerical input into two ",
            "display axes. The size chart counts profiles assigned to each cluster."
          ),
          paste0(
            "Look for broad overlap, isolated profiles and very small groups. PCA is a ",
            "visual diagnostic only: overlap in two dimensions does not prove overlap in ",
            "the full model space."
          )
        ),
        bslib::layout_columns(
          shiny::div(class = "diagnostic-panel", help_header("PCA projection", paste0(
            "PCA rotates the selected method's input variables into orthogonal directions ",
            "of decreasing variance. The chart shows only PC1 and PC2 because a scatter ",
            "plot has two axes. Its title reports their combined explained variance and ",
            "the total number of components required to reach 95%. Clustering still uses ",
            "the declared model space, not this two-dimensional display."
          )), analysis_plot_output("pca_plot", 700)),
          shiny::div(class = "diagnostic-panel", help_header("Cluster sizes", paste0(
            "Number of accepted profiles assigned to each group by the selected method; ",
            "cluster 0 is HDBSCAN noise."
          )), analysis_plot_output("size_plot", 700)),
          col_widths = c(8, 4)
        )
      ),
      bslib::nav_panel(
        "Cohesion & separation",
        result_tab_guide(
          "Assess cluster cohesion and separation from the same distance evidence",
          paste0(
            "Silhouette compares each profile's cohesion with its own cluster against ",
            "its separation from the nearest alternative cluster. Peer distance measures ",
            "dispersion inside the assigned cluster, while the matrix exposes every ",
            "pairwise comparison."
          ),
          paste0(
            "Strong results combine positive silhouettes with low and reasonably compact ",
            "peer distances, pale diagonal blocks and darker off-diagonal blocks. Inspect ",
            "the distributions and matrix structure, not only the benchmark average."
          )
        ),
        bslib::layout_columns(
          shiny::div(
            class = "diagnostic-panel",
            help_header(
              "Profile silhouette",
              paste0(
                "For profile i, silhouette is (b(i) - a(i)) / max(a(i), b(i)): a(i) is ",
                "mean dissimilarity to its own cluster and b(i) is the lowest mean ",
                "dissimilarity to another cluster. Values near 1 indicate clear ",
                "assignment, near 0 indicate a boundary and below 0 suggest another ",
                "cluster may be closer. Noise profiles are excluded."
              )
            ),
            analysis_plot_output(
              "silhouette_detail_plot",
              720
            ),
            diagnostic_reading_note(
              "Reading the bars. ",
              paste0(
                "Each bar is one profile and each panel is one cluster. Bars close to ",
                "one support a clear assignment; bars near zero require inspection; ",
                "negative bars indicate that another cluster is closer on average."
              )
            )
          ),
          shiny::div(
            class = "diagnostic-panel",
            help_header(
              "Within-cluster distance",
              paste0(
                "Mean dissimilarity from each profile to the other profiles assigned ",
                "to the same cluster. Lower and tighter distributions indicate more ",
                "internally cohesive groups. Values are meaningful only relative to ",
                "other results using the same representation, scaling and distance."
              )
            ),
            analysis_plot_output(
              "peer_distance_plot",
              720
            ),
            diagnostic_reading_note(
              "Reading the distribution. ",
              paste0(
                "Each point is one profile. The box covers the middle half of profiles ",
                "and its central line is the median. A high point is less similar to its ",
                "cluster peers; a tall box indicates an internally diverse cluster."
              )
            )
          ),
          col_widths = c(7, 5)
        ),
        bslib::layout_columns(
          shiny::div(
            class = "diagnostic-panel separation-matrix-panel",
            help_header(
              "Pairwise dissimilarity matrix",
              paste0(
                "Rows and columns contain the same profiles ordered by cluster. Every cell ",
                "uses the distance declared by the selected method. The diagonal is zero; ",
                "pale colours indicate smaller dissimilarity and dark colours larger ",
                "dissimilarity. Hover a cell to identify both profiles, their clusters and ",
                "their exact dissimilarity."
              )
            ),
            analysis_plot_output("dissimilarity_plot", 800),
            diagnostic_reading_note(
              "Reading the blocks. ",
              paste0(
                "Pale squares on the diagonal represent cohesive clusters. Darker areas ",
                "between those squares support separation. Dark streaks inside a square ",
                "identify profiles unlike many members of their assigned cluster."
              )
            )
          ),
          shiny::div(
            class = "diagnostic-panel separation-matrix-panel",
            help_header(
              "Within-cluster atypicality",
              paste0(
                "Each profile is ranked inside its own cluster using its mean ",
                "dissimilarity to the other members. A percentile of 0.95 means it is ",
                "more distant than roughly 95% of that cluster."
              )
            ),
            analysis_plot_output("atypicality_plot", 800),
            diagnostic_reading_note(
              "Reading the ranking. ",
              paste0(
                "Points near one deserve review first. They may represent valid rare ",
                "behaviour, a transition between groups or a data-quality problem; the ",
                "percentile is not an anomaly probability."
              )
            )
          ),
          col_widths = c(8, 4)
        )
      ),
      bslib::nav_panel(
        "Assignments",
        result_tab_guide(
          "Trace the result back to individual load profiles",
          paste0(
            "Provides one auditable record per accepted profile: its assigned cluster, ",
            "cluster prevalence, individual separation and within-cluster position. ",
            "Method-specific evidence is added when the selected algorithm provides it."
          ),
          paste0(
            "Use the column selector to focus the table, filters to locate profiles and ",
            "cell colours to compare numerical values within a column. Interpret every ",
            "metric together with the plots above."
          )
        ),
        shiny::div(
          class = "assignment-field-guide",
          shiny::div(
            shiny::strong("Cluster context"),
            shiny::span("Cluster size and share describe how common the assigned group is.")
          ),
          shiny::div(
            shiny::strong("Cohesion"),
            shiny::span("Mean peer dissimilarity and atypicality describe fit within the group.")
          ),
          shiny::div(
            shiny::strong("Separation"),
            shiny::span("Silhouette, nearest alternative and margin describe competing groups.")
          ),
          shiny::div(
            shiny::strong("Method evidence"),
            shiny::span("Probabilities, outlier scores or errors appear only when available.")
          )
        ),
        shiny::div(
          class = "diagnostic-panel assignment-panel assignment-panel-full",
          help_header(
            "Cluster assignments",
            paste0(
              "One row per accepted profile. Cluster share gives group prevalence; ",
              "silhouette compares the assigned and nearest alternative clusters; ",
              "separation margin is alternative-cluster dissimilarity minus mean peer ",
              "dissimilarity. Positive larger margins support clearer assignments. ",
              "Optional columns expose evidence available only for the active algorithm."
            )
          ),
          help_action(
            shiny::downloadButton("download_assignments",
              "Assignments",
              class = "download-button compact-download"
            ),
            "Download assignments from the selected clustering result."
          ),
          table_variable_selector("assignments_table_columns"),
          DT::DTOutput("assignments_table")
        )
      ),
      bslib::nav_panel(
        "Algorithm-specific",
        result_tab_guide(
          "Inspect evidence that is meaningful only for this algorithm family",
          paste0(
            "These diagnostics expose the internal structure of the selected method, ",
            "such as a hierarchy, density persistence, mixture uncertainty or SOM map."
          ),
          paste0(
            "Use them alongside the common diagnostics. They explain how this algorithm ",
            "formed its groups but should not be used to compare unrelated algorithms ",
            "unless the statistic has the same definition."
          )
        ),
        shiny::uiOutput("algorithm_diagnostic_header"),
        shiny::uiOutput("algorithm_diagnostic_workspace")
      )
    )
  )
}

build_results_model_dock <- function() {
  shiny::tags$details(
    class = "results-model-dock",
    shiny::tags$summary(
      bsicons::bs_icon("diagram-3"),
      shiny::span(class = "model-dock-label", "Selected result"),
      shiny::textOutput("active_model_dock", container = shiny::span),
      bsicons::bs_icon("chevron-up")
    ),
    shiny::div(
      class = "results-model-popover",
      shiny::div(
        class = "model-popover-heading",
        shiny::span("RESULTS CONTEXT"), shiny::strong("Selected clustering result")
      ),
      shiny::uiOutput("active_model_status"),
      shiny::selectizeInput("model_choice",
        help_label(
          "Clustering result used across all views",
          "model_choice"
        ),
        choices = NULL
      ),
      shiny::uiOutput("run_context"),
      shiny::p(
        class = "model-popover-note",
        "This selection is shared by every chart, metric and table in Selected model analysis."
      ),
      shiny::div(class = "internal-input", shiny::selectInput("visualization_mode", NULL,
        choices = c("Interactive · Plotly" = "interactive"), selected = "interactive"
      ))
    )
  )
}
