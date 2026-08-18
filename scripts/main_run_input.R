main_read_input <- function(input_path, input_mode, config) {
  if (input_mode == "long") {
    data <- read_load_curve_long(
      path = input_path,
      timezone = config$input$timezone
    )
    read_errors <- character()
  } else if (input_mode == "folder") {
    batch <- read_load_curve_batch(
      input_dir = input_path,
      config = config$input
    )
    data <- batch$data
    read_errors <- batch$errors
  } else {
    stop("input_mode must be 'long' or 'folder'.")
  }

  message(
    "Input loaded: ",
    format(nrow(data), big.mark = ","), " rows from ",
    length(unique(data$series_id)), " series"
  )

  if (length(read_errors) > 0) {
    warning(paste(read_errors, collapse = "\n"), call. = FALSE)
  }

  list(
    data = data,
    read_errors = read_errors
  )
}
