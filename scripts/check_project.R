#!/usr/bin/env Rscript

source("R/load_project_functions.R")
load_project_functions(".")
files <- list.files("R", pattern = "\\.R$", full.names = TRUE)
parsed <- lapply(files, parse)
function_counts <- vapply(parsed, function(expr) {
  sum(vapply(as.list(expr), function(x) {
    is.call(x) && identical(x[[1]], as.name("<-")) && is.call(x[[3]]) && identical(
      x[[3]][[1]],
      as.name("function")
    )
  }, logical(1)))
}, integer(1))
if (any(function_counts != 1L)) {
  stop(
    "One-function-per-file rule failed: ",
    paste(basename(files)[function_counts != 1L],
      collapse = ", "
    )
  )
}
cat("Parsed", length(files), "R function files; one-function-per-file check passed.\n")

if (!requireNamespace("lintr", quietly = TRUE)) {
  stop("Package 'lintr' is required. Install it with renv::install('lintr').")
}

lints <- lintr::lint_dir(".")
if (length(lints)) {
  print(lints)
  stop("lintr found ", length(lints), " code-quality issue(s).")
}
cat("lintr check passed with no issues.\n")
