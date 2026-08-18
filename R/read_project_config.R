#' Read and validate a YAML project configuration
#' @param path YAML configuration path.
#' @return A nested list.
read_project_config <- function(path) {
  if (!requireNamespace("yaml", quietly = TRUE)) stop("Package 'yaml' is required.")
  if (!file.exists(path)) stop("Configuration not found: ", path)
  config <- yaml::read_yaml(path)
  required <- c("input", "quality", "preprocessing", "modeling", "output")
  missing <- setdiff(required, names(config))
  if (length(missing)) stop("Missing config sections: ", paste(missing, collapse = ", "))
  config
}
