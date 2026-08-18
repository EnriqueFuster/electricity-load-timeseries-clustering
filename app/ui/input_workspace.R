input_card_heading <- function(icon, title, description) {
  shiny::div(
    class = "input-card-heading",
    bsicons::bs_icon(icon),
    shiny::div(shiny::h4(title), shiny::p(description))
  )
}

build_input_workspace <- function() {
  shiny::div(
    class = "configuration-page input-workspace",
    build_data_foundation_panel(),
    shiny::div(
      class = "workflow-footnote",
      bsicons::bs_icon("info-circle"),
      paste0(
        "These settings are applied when an experiment is run; completed results ",
        "remain available until then."
      )
    )
  )
}

build_model_design_workspace <- function() {
  shiny::div(
    class = "configuration-page input-workspace model-design-workspace primary-workspace",
    app_section_header(
      "EXPERIMENTS", "Design and compare clustering experiments",
      paste0(
        "Choose how the annual profiles are summarized, normalized and compared; ",
        "then select compatible clustering methods and validation settings."
      )
    ),
    shiny::div(
      class = "model-design-surface",
      build_benchmark_panel(),
      shiny::div(
        class = "workflow-footnote", bsicons::bs_icon("info-circle"),
        paste0(
          "Only queued experiments are fitted. Previously completed results remain ",
          "available until a new run finishes."
        )
      )
    )
  )
}
