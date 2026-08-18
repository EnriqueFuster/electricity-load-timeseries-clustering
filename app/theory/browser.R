theory_explorer_ui <- function(section, label) {
  prefix <- paste0("learn_", section)
  bslib::nav_panel(
    label,
    shiny::div(
      class = "theory-explorer",
      shiny::tags$aside(
        class = "theory-browser",
        shiny::div(
          class = "theory-browser-heading", shiny::span("CATALOGUE"),
          shiny::strong(label)
        ),
        shiny::textInput(paste0(prefix, "_search"), NULL, placeholder = "Search concepts..."),
        shiny::selectInput(paste0(prefix, "_filter"), NULL, choices = "All categories"),
        shiny::uiOutput(paste0(prefix, "_options"), class = "theory-option-scroll")
      ),
      shiny::tags$main(class = "theory-detail-pane", shiny::uiOutput(paste0(prefix, "_detail")))
    )
  )
}

build_theory_center <- function() {
  shiny::div(
    class = "theory-center",
    app_section_header(
      "LEARNING CENTRE", "Understand the clustering workflow",
      paste0(
        "Learn each modelling decision in the same order used to construct an ",
        "experiment, from the temporal basis to validation and interpretation."
      )
    ),
    bslib::navset_card_tab(
      theory_start_here_ui(),
      theory_explorer_ui("temporal", "1 · Temporal representation"),
      theory_explorer_ui("aggregation", "2 · Hourly aggregation"),
      theory_explorer_ui("normalization", "3 · Normalization & objective"),
      theory_explorer_ui("transformation", "4 · Representation & reduction"),
      theory_explorer_ui("algorithms", "5 · Clustering algorithm"),
      theory_explorer_ui("distance", "6 · Distance & similarity"),
      theory_explorer_ui("validation", "Validation & interpretation"),
      theory_glossary_ui()
    )
  )
}

render_representation_feature_details <- function(entry) {
  feature_table <- function(rows) {
    shiny::tags$div(
      class = "theory-feature-table-wrap",
      shiny::tags$table(
        class = "theory-feature-table",
        shiny::tags$thead(shiny::tags$tr(
          shiny::tags$th("Feature"), shiny::tags$th("How it is calculated"),
          shiny::tags$th("Practical meaning")
        )),
        shiny::tags$tbody(lapply(rows, function(row) {
          shiny::tags$tr(
            shiny::tags$td(shiny::code(row[[1]])), shiny::tags$td(row[[2]]),
            shiny::tags$td(row[[3]])
          )
        }))
      )
    )
  }

  if (entry$id %in% c("seasonal_basis", "seasonal_daypart")) {
    return(shiny::tags$section(
      class = "theory-feature-details",
      shiny::div(
        class = "theory-detail-block-title",
        bsicons::bs_icon("grid-3x3-gap"),
        "Features produced in this application"
      ),
      shiny::p(paste0(
        "Every hourly reading is assigned to one cell formed by three calendar ",
        "labels. The application then calculates the configured mean or median ",
        "separately for every meter and cell."
      )),
      shiny::tags$ol(
        class = "theory-process-list",
        shiny::tags$li(
          shiny::strong("Season: "),
          paste0(
            "winter (December–February), spring (March–May), summer (June–August) or ",
            "autumn (September–November)."
          )
        ),
        shiny::tags$li(shiny::strong("Day type: "), paste0(
          "weekday for Monday–Friday or weekend for Saturday–Sunday. Public holidays ",
          "are not identified separately."
        )),
        shiny::tags$li(
          shiny::strong("Four-hour block: "),
          paste0(
            "00:00–03:59, 04:00–07:59, 08:00–11:59, 12:00–15:59, ",
            "16:00–19:59 or 20:00–23:59."
          )
        )
      ),
      shiny::div(
        class = "theory-feature-equation",
        shiny::code(paste0(
          "feature(i,s,d,b) = median or mean of x(i,t) for all hours t in season s, ",
          "day type d and block b"
        ))
      ),
      shiny::p(
        shiny::strong("Output: "),
        "4 seasons × 2 day types × 6 blocks = 48 columns per meter. A name such as ",
        shiny::code("winter__weekday__h08_12"),
        " means the typical consumption from 08:00 to 11:59 on winter weekdays."
      ),
      shiny::p(shiny::strong("What reaches clustering: "), paste0(
        "the 48-column row is subsequently normalized according to the selected ",
        "comparison objective. It is a feature vector, not a 48-step chronological ",
        "series."
      )),
      shiny::p(shiny::strong("What is lost: "), paste0(
        "individual dates, differences between weekdays, public-holiday effects and ",
        "peaks occurring within the same four-hour block."
      ))
    ))
  }

  if (entry$id %in% c("behavioural_basis", "behavioral")) {
    rows <- list(
      c("mean_hourly_kwh", "Mean of all hourly readings.", "Average demand level."),
      c(
        "median_daily_kwh",
        "Median of daily totals after summing the 24 hourly readings of each day.",
        "Consumption on a typical day."
      ),
      c(
        "p95_daily_kwh",
        "95th percentile of daily totals.",
        "Demand on a high-consumption day without relying on the single maximum."
      ),
      c(
        "load_factor",
        "Hourly mean divided by the maximum hourly reading.",
        "How flat the load is relative to its peak; values nearer one are flatter."
      ),
      c(
        "hourly_variability",
        "Standard deviation of hourly readings divided by their mean.",
        "Relative short-term variability."
      ),
      c(
        "daily_variability",
        "Standard deviation of daily totals divided by their mean.",
        "Relative variation between days."
      ),
      c(
        "peak_hour_sin / peak_hour_cos",
        "Sine and cosine encoding of the hour with the highest mean consumption.",
        "Typical peak timing without making 23:00 artificially distant from 00:00."
      ),
      c(
        "night_share", "Share of annual consumption recorded from 00:00 to 06:59.",
        "Importance of overnight demand."
      ),
      c("morning_share", "Share recorded from 07:00 to 10:59.", "Importance of morning demand."),
      c("daytime_share", "Share recorded from 11:00 to 16:59.", "Importance of daytime demand."),
      c("evening_share", "Share recorded from 17:00 to 21:59.", "Importance of evening demand."),
      c(
        "late_night_share", "Share recorded from 22:00 to 23:59.",
        "Importance of late-night demand."
      ),
      c(
        "weekday_mean / weekend_mean",
        "Separate hourly means for Monday–Friday and Saturday–Sunday.",
        "Difference between working-week and weekend consumption levels."
      ),
      c(
        "winter_mean / spring_mean / summer_mean / autumn_mean",
        "Separate hourly means for the four meteorological seasons.",
        "Seasonal demand level and dominant season."
      )
    )
    return(shiny::tags$section(
      class = "theory-feature-details",
      shiny::div(
        class = "theory-detail-block-title",
        bsicons::bs_icon("list-check"),
        "Features produced in this application"
      ),
      shiny::p(paste0(
        "This representation does not divide the year into identical calendar cells. ",
        "It calculates 19 indicators with different formulas, each describing a ",
        "recognizable aspect of consumption behaviour."
      )),
      feature_table(rows),
      shiny::p(shiny::strong("Preparation before clustering: "), paste0(
        "non-finite values are replaced with the median of that feature across ",
        "meters; constant features are removed; every remaining column is centred ",
        "and divided by its standard deviation. This prevents kWh variables from ",
        "numerically overwhelming shares or ratios."
      )),
      shiny::p(shiny::strong("What is lost: "), paste0(
        "the original chronological curve cannot be reconstructed from these ",
        "indicators. Two meters can obtain similar summaries even when their ",
        "detailed hourly sequences differ."
      )),
      shiny::p(shiny::strong("Key distinction: "), paste0(
        "season × day type × time block asks where in the calendar consumption ",
        "occurs using one repeated aggregation rule. Behavioral summary combines ",
        "level, variability, timing and energy-share indicators calculated with ",
        "several different rules."
      ))
    ))
  }

  NULL
}

render_theory_detail <- function(entry) {
  academic <- get_theory_academic_profile(entry)
  io_catalog <- list(
    typical_week = c("8,760 hourly values", "168 ordered weekly values"),
    pca_week = c("168 weekly values", "q PCA scores"),
    annual_unit_pca = c("8,760 annual kWh values", "q PCA scores of annual shares"),
    annual_clr_pca = c("8,760 annual shares", "CLR", "q PCA scores"),
    annual_z_pca = c("8,760 annual values", "row z-score", "q PCA scores"),
    seasonal_daypart = c("8,760 hourly values", "48 named calendar features"),
    behavioral = c("8,760 hourly values", "19 behavioural indicators"),
    catch22_global = c("8,760 hourly values", "22 standardized features"),
    catch22_seasonal = c("ordered seasonal subsequences", "up to 88 features"),
    catch24_seasonal = c("ordered seasonal subsequences", "up to 96 features")
  )
  section <- function(title, text, class = "theory-prose-section", icon = "book") {
    shiny::tags$section(
      class = class,
      shiny::div(class = "theory-detail-block-title", bsicons::bs_icon(icon), title),
      shiny::p(text)
    )
  }
  io_strip <- if (entry$id %in% names(io_catalog)) {
    values <- io_catalog[[entry$id]]
    shiny::div(
      class = "theory-io-strip",
      lapply(seq_along(values), function(index) {
        shiny::tagList(
          if (index > 1L) shiny::span(class = "theory-io-arrow", "→"),
          shiny::code(values[index])
        )
      })
    )
  }
  formula <- if (!startsWith(academic$equation, "This is a design")) {
    shiny::tags$section(
      class = "theory-formula-block",
      shiny::div(
        class = "theory-detail-block-title", bsicons::bs_icon("braces"),
        "Technical formulation"
      ),
      shiny::code(academic$equation)
    )
  }

  shiny::tags$article(
    class = "theory-detail",
    shiny::div(
      class = "theory-detail-header",
      shiny::span(class = "theory-tag", entry$family),
      shiny::h2(entry$title), shiny::p(entry$summary), io_strip
    ),
    section("What this choice changes", entry$mechanics, icon = "sliders"),
    render_representation_feature_details(entry),
    section("When it answers the question", entry$use_when, icon = "check2-circle"),
    section("Scientific limitation", entry$limitations, "theory-warning", "exclamation-triangle"),
    section(
      "In this app",
      paste(entry$compatibility, entry$interpretation),
      "theory-note",
      "journal-check"
    ),
    formula,
    if (!identical(entry$parameters, "No method-specific parameter.")) {
      section("Parameters", entry$parameters, "theory-parameters", "sliders")
    },
    shiny::div(
      class = "theory-reference",
      shiny::div(
        class = "theory-detail-block-title",
        bsicons::bs_icon("journal-code"),
        "R implementation and further reading"
      ),
      shiny::p(academic$implementation),
      shiny::tags$ul(lapply(academic$references, function(reference) {
        shiny::tags$li(shiny::tags$a(reference[[1]],
          href = reference[[2]],
          target = "_blank",
          rel = "noopener noreferrer"
        ))
      }))
    )
  )
}

register_theory_explorers <- function(input, output, session) {
  catalog <- get_learning_taxonomy()

  explorer_sections <- setdiff(names(catalog), "foundations")

  for (section_name in explorer_sections) {
    local({
      section <- section_name
      entries <- catalog[[section]]
      prefix <- paste0("learn_", section)
      families <- sort(unique(vapply(entries, `[[`, character(1), "family")))

      shiny::updateSelectInput(session, paste0(prefix, "_filter"),
        choices = c("All categories", families), selected = "All categories"
      )

      filtered_entries <- shiny::reactive({
        query <- tolower(trimws(input[[paste0(prefix, "_search")]] %||% ""))
        family <- input[[paste0(prefix, "_filter")]] %||% "All categories"
        keep <- vapply(entries, function(entry) {
          searchable <- tolower(paste(entry$title, entry$family, entry$summary))
          (family == "All categories" || entry$family == family) &&
            (!nzchar(query) || grepl(query, searchable, fixed = TRUE))
        }, logical(1))
        entries[keep]
      })

      output[[paste0(prefix, "_options")]] <- shiny::renderUI({
        visible <- filtered_entries()
        if (!length(visible)) {
          return(shiny::div(class = "theory-empty", "No catalogue entries match these filters."))
        }
        ids <- vapply(visible, `[[`, character(1), "id")
        labels <- vapply(
          visible, function(entry) paste(entry$title, "—", entry$family),
          character(1)
        )
        current <- input[[paste0(prefix, "_item")]]
        selected <- if (!is.null(current) && current %in% ids) current else ids[1]
        shiny::radioButtons(paste0(prefix, "_item"), NULL,
          choices = stats::setNames(ids, labels), selected = selected
        )
      })

      output[[paste0(prefix, "_detail")]] <- shiny::renderUI({
        visible <- filtered_entries()
        shiny::req(length(visible))
        selected <- input[[paste0(prefix, "_item")]] %||% visible[[1]]$id
        matches <- vapply(entries, function(entry) identical(entry$id, selected), logical(1))
        entry <- if (any(matches)) entries[[which(matches)[1]]] else visible[[1]]
        render_theory_detail(entry)
      })
    })
  }
}
