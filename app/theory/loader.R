# Compatibility loader for scripts that previously sourced this file directly.
theory_content_directories <- c(
  file.path(getwd(), "app", "theory"),
  file.path(getwd(), "theory"),
  file.path(getwd(), "..", "app", "theory"),
  file.path(getwd(), "..", "..", "app", "theory")
)
theory_content_directory <- theory_content_directories[
  dir.exists(theory_content_directories)
][1]

if (is.na(theory_content_directory)) {
  stop("Could not locate the app/theory module directory.")
}
theory_content_modules <- c(
  "foundations",
  "representations",
  "similarity",
  "algorithms",
  "validation",
  "catalog",
  "taxonomy",
  "academic",
  "start_here",
  "glossary",
  "browser"
)

for (theory_content_module in theory_content_modules) {
  sys.source(
    file.path(
      theory_content_directory,
      paste0(theory_content_module, ".R")
    ),
    envir = environment()
  )
}

rm(
  theory_content_directory,
  theory_content_directories,
  theory_content_module,
  theory_content_modules
)
