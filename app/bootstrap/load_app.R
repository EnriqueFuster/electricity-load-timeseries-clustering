# Application dependencies ------------------------------------------------

application_packages <- function() {
  c(
    "shiny",
    "bslib",
    "ggplot2",
    "plotly",
    "DT"
  )
}

load_application_packages <- function(packages = application_packages()) {
  available <- vapply(
    packages,
    requireNamespace,
    quietly = TRUE,
    FUN.VALUE = logical(1)
  )
  missing <- packages[!available]

  if (length(missing)) {
    stop(
      "Missing application packages: ",
      paste(missing, collapse = ", "),
      ". Run renv::restore() before starting the app."
    )
  }

  invisible(lapply(packages, function(package) {
    suppressPackageStartupMessages(
      library(package, character.only = TRUE)
    )
  }))
}


# Static application resources -------------------------------------------

register_application_resources <- function(root) {
  prefix <- "load-clustering-assets"
  directory <- normalizePath(
    file.path(root, "app", "www"),
    winslash = "/",
    mustWork = TRUE
  )
  registered <- shiny::resourcePaths()

  if (prefix %in% names(registered)) {
    shiny::removeResourcePath(prefix)
  }

  shiny::addResourcePath(prefix, directory)
  invisible(prefix)
}


# Application modules -----------------------------------------------------

application_modules <- function() {
  list(
    configuration = c(
      file.path("config", "app_config.R"),
      file.path("ui", "help_content.R")
    ),
    learning_centre = file.path(
      "theory",
      c(
        "foundations.R",
        "representations.R",
        "similarity.R",
        "algorithms.R",
        "validation.R",
        "catalog.R",
        "taxonomy.R",
        "academic.R",
        "start_here.R",
        "glossary.R",
        "browser.R"
      )
    ),
    input_workspace = c(
      file.path(
        "ui",
        "inputs",
        c(
          "data_foundation.R",
          "benchmark.R",
          "method_parameters.R"
        )
      ),
      file.path("ui", "input_workspace.R")
    ),
    interface = c(
      file.path("ui", "components.R"),
      file.path("ui", "app_ui.R")
    ),
    server = file.path("server", "app_server.R")
  )
}

load_application_modules <- function(root, modules = application_modules()) {
  relative_paths <- unname(unlist(modules, use.names = FALSE))
  module_paths <- file.path(root, "app", relative_paths)
  missing <- module_paths[!file.exists(module_paths)]

  if (length(missing)) {
    stop(
      "Application modules could not be found: ",
      paste(basename(missing), collapse = ", ")
    )
  }

  invisible(lapply(module_paths, sys.source, envir = .GlobalEnv))
}


# Complete application preload -------------------------------------------

load_application <- function(root) {
  load_application_packages()
  register_application_resources(root)

  source(file.path(root, "R", "load_project_functions.R"))
  load_project_functions(root)
  load_application_modules(root)

  invisible(root)
}
