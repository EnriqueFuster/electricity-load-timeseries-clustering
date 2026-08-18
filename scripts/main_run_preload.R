main_preload <- function(config_file) {
  source("R/load_project_functions.R")
  load_project_functions(".")

  config <- read_project_config(config_file)

  if (identical(config$modeling$k_mode %||% "auto", "manual")) {
    config$modeling$k_min <- as.integer(config$modeling$fixed_k)
    config$modeling$k_max <- as.integer(config$modeling$fixed_k)
  }

  message("Configuration loaded from ", config_file)
  config
}
