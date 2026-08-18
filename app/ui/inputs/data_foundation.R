upload_format_guide <- function() {
  shiny::tags$details(
    class = "upload-format-guide",
    shiny::tags$summary(
      bsicons::bs_icon("table"),
      shiny::span("Show required file structure"),
      bsicons::bs_icon("chevron-down")
    ),
    shiny::div(
      class = "upload-format-guide-body",
      shiny::conditionalPanel(
        "input.upload_format == 'long'",
        shiny::strong("Canonical long CSV · one file for all curves"),
        shiny::p("Each row is one hourly observation. The series ID groups rows into curves."),
        shiny::div(
          class = "upload-example-table",
          shiny::code("series_id"), shiny::code("timestamp"), shiny::code("value"),
          shiny::span("meter_001"), shiny::span("2024-01-01 00:00:00"), shiny::span("1.42"),
          shiny::span("meter_002"), shiny::span("2024-01-01 00:00:00"), shiny::span("0.87")
        ),
        shiny::p(class = "upload-guide-note", "Upload exactly one CSV file.")
      ),
      shiny::conditionalPanel(
        "input.upload_format == 'folder'",
        shiny::strong("One CSV per series · one file for each curve"),
        shiny::p("Each file contains one curve. Its filename becomes the series ID."),
        shiny::div(
          class = "upload-example-file",
          shiny::span("meter_001.csv"),
          shiny::div(
            class = "upload-example-table upload-example-table-two",
            shiny::code("timestamp"), shiny::code("value"),
            shiny::span("2024-01-01 00:00:00"), shiny::span("1.42"),
            shiny::span("2024-01-01 01:00:00"), shiny::span("1.31")
          )
        ),
        shiny::p(
          class = "upload-guide-note",
          "Upload one or more CSV files; no series-ID column is required."
        )
      )
    )
  )
}

build_data_foundation_panel <- function() {
  shiny::div(
    class = "workflow-page",
    shiny::div(
      class = "input-card-grid data-foundation-grid",
      shiny::tags$section(
        class = "input-card source-card",
        input_card_heading(
          "database",
          "Data source",
          "Start with the reproducible demo or provide complete hourly curves."
        ),
        shiny::radioButtons(
          "data_mode",
          help_label(
            "Source",
            "data_mode"
          ),
          c(
            "Bundled anonymized GoiEner sample" = "demo",
            "Upload curves" = "upload"
          )
        ),
        shiny::conditionalPanel(
          "input.data_mode == 'upload'",
          class = "upload-settings",
          shiny::radioButtons(
            "upload_format",
            help_label(
              "Upload layout",
              "upload_format"
            ),
            c(
              "Canonical long CSV" = "long",
              "One CSV per series" = "folder"
            )
          ),
          upload_format_guide(),
          shiny::fileInput("files", help_label("CSV files", "files"),
            multiple = TRUE,
            accept = c(".csv", "text/csv")
          ),
          shiny::div(
            class = "compact-input-grid upload-columns",
            shiny::textInput("timestamp_column", help_label(
              "Timestamp column",
              "timestamp_column"
            ), "timestamp"),
            shiny::textInput(
              "value_column", help_label("Consumption column", "value_column"),
              "value"
            ),
            shiny::conditionalPanel(
              "input.upload_format == 'long'",
              shiny::textInput(
                "series_id_column",
                help_label(
                  "Series ID column",
                  "series_id_column"
                ),
                "series_id"
              )
            ),
            shiny::selectInput(
              "delimiter",
              help_label(
                "Delimiter",
                "delimiter"
              ),
              c(
                "Comma" = ",",
                "Semicolon" = ";",
                "Tab" = "\t"
              )
            ),
            shiny::selectizeInput(
              "timezone",
              help_label("Common timezone", "timezone"),
              choices = c("UTC", setdiff(OlsonNames(), "UTC")),
              selected = "UTC",
              options = list(
                placeholder = "Search IANA timezones",
                maxOptions = 1000
              )
            )
          ),
          shiny::div(
            class = "timezone-contract-note",
            bsicons::bs_icon("globe2"),
            shiny::span(
              shiny::strong("One input timezone per dataset."),
              paste0(
                " All curves must use it. The current analytical calendar is standardized ",
                "to UTC after parsing."
              )
            )
          )
        )
      ),
      shiny::tags$section(
        class = "input-card privacy-card",
        input_card_heading(
          "shield-lock",
          "Identifier privacy",
          "Apply the policy once, before quality checks, modeling and exports."
        ),
        shiny::div(
          class = "privacy-settings",
          shiny::div(
            class = "privacy-toggle",
            shiny::checkboxInput("anonymize_ids", help_label(
              "Anonymize profile identifiers",
              "anonymize_ids"
            ), FALSE),
            shiny::p("The original-to-anonymous mapping is not stored.")
          ),
          shiny::conditionalPanel("input.anonymize_ids",
            class = "privacy-prefix",
            shiny::textInput(
              "id_prefix",
              help_label(
                "Anonymous ID prefix",
                "id_prefix"
              ),
              "profile"
            )
          )
        )
      )
    ),
    shiny::tags$section(
      class = "input-card quality-card",
      input_card_heading("clipboard2-check", "Annual quality gate", paste0(
        "Every accepted profile must provide a complete January–December hourly ",
        "window after the permitted repair."
      )),
      shiny::div(
        class = "quality-input-grid",
        shiny::sliderInput("complete_year_missing",
          help_label(
            "Missing hours in selected year (%)",
            "complete_year_missing"
          ),
          0,
          10,
          2,
          step = .5
        ),
        shiny::sliderInput("max_missing", help_label("Overall missingness (%)", "max_missing"), 1,
          40, 10,
          step = 1
        ),
        shiny::sliderInput("min_coverage",
          help_label(
            "Minimum coverage (days)",
            "min_coverage"
          ),
          365,
          730,
          365,
          step = 7
        )
      )
    )
  )
}
