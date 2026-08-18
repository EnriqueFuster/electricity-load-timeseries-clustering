#' Source every project function
#' @param root Project root.
#' @return Invisibly, sourced file paths.
load_project_functions <- function(root = ".") {
  paths <- sort(list.files(file.path(root, "R"), pattern = "\\.R$", full.names = TRUE))
  paths <- paths[basename(paths) != "load_project_functions.R"]
  invisible(lapply(paths, sys.source, envir = .GlobalEnv))
}
