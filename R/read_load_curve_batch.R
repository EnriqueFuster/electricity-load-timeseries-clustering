#' Read a folder of load-curve files
#' @param input_dir Input folder.
#' @param config Input configuration.
#' @return A list with data and file-level errors.
read_load_curve_batch <- function(input_dir, config) {
  if (!dir.exists(input_dir)) stop("Input directory not found: ", input_dir)
  files <- list.files(input_dir, pattern = config$pattern %||% "\\.csv$", full.names = TRUE)
  if (!length(files)) stop("No matching files found in: ", input_dir)
  errors <- character()
  pieces <- lapply(files, function(path) {
    tryCatch(read_load_curve_file(path, config), error = function(e) {
      errors <<- c(errors, paste(basename(path), conditionMessage(e), sep = ": "))
      NULL
    })
  })
  pieces <- Filter(Negate(is.null), pieces)
  if (!length(pieces)) stop("No readable load curves. ", paste(errors, collapse = "; "))
  list(data = do.call(rbind, pieces), errors = errors)
}
