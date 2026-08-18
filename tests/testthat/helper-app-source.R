app_source_files <- function(component) {
  app_directory <- test_path("..", "..", "app")

  switch(
    component,
    ui = list.files(
      file.path(app_directory, "ui"),
      pattern = "[.]R$",
      recursive = TRUE,
      full.names = TRUE
    ),
    server = list.files(
      file.path(app_directory, "server"),
      pattern = "[.]R$",
      full.names = TRUE
    ),
    theory = list.files(
      file.path(app_directory, "theory"),
      pattern = "[.]R$",
      full.names = TRUE
    ),
    stop("Unknown app component: ", component)
  )
}

read_app_source <- function(component, collapse = TRUE) {
  source_lines <- unlist(
    lapply(
      app_source_files(component),
      readLines,
      warn = FALSE,
      encoding = "UTF-8"
    ),
    use.names = FALSE
  )

  if (collapse) {
    paste(source_lines, collapse = "\n")
  } else {
    source_lines
  }
}
