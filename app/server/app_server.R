build_app_server <- function(config) {
  force(config)

  function(input, output, session) {
    server_environment <- environment()
    server_sections <- c(
      "bootstrap",
      "experiment_design",
      "benchmark_execution",
      "model_context",
      "plots",
      "tables_and_exports"
    )

    for (section in server_sections) {
      section_file <- file.path(
        config$root,
        "app",
        "server",
        paste0(section, ".R")
      )
      sys.source(section_file, envir = server_environment)
    }
  }
}
