#!/usr/bin/env Rscript

if (!requireNamespace("styler", quietly = TRUE)) {
  stop("Package 'styler' is required. Install it with renv::install('styler').")
}

source_directories <- c("R", "app", "cli", "scripts", "tests")
source_files <- c(
  "main.R",
  "tests/testthat.R",
  unlist(lapply(source_directories, function(directory) {
    list.files(directory,
      pattern = "[.]R$",
      full.names = TRUE,
      recursive = TRUE
    )
  }))
)

styler::style_file(
  unique(source_files),
  transformers = styler::tidyverse_style(
    indent_by = 2,
    strict = TRUE
  )
)
