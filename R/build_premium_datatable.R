#' Build a consistently formatted DT table for the Shiny application
#' @param data Data frame to display.
#' @param labels Named character vector mapping source columns to display labels.
#' @param page_length Rows shown per page.
#' @param digits Maximum decimal places for non-integer numeric columns.
#' @return A DT htmlwidget.
build_premium_datatable <- function(data, labels = character(), page_length = -1L,
                                    digits = 3L) {
  if (!requireNamespace("DT", quietly = TRUE)) stop("Package 'DT' is required.")
  data <- as.data.frame(data, stringsAsFactors = FALSE)

  timestamp_columns <- names(data)[vapply(data, inherits, logical(1), what = "POSIXt")]
  data[timestamp_columns] <- lapply(data[timestamp_columns], format, "%Y-%m-%d %H:%M")
  logical_columns <- names(data)[vapply(data, is.logical, logical(1))]
  data[logical_columns] <- lapply(data[logical_columns], function(values) {
    ifelse(is.na(values), "—", ifelse(values, "Yes", "No"))
  })

  numeric_columns <- names(data)[vapply(data, is.numeric, logical(1))]
  integer_like <- numeric_columns[vapply(data[numeric_columns], function(values) {
    finite <- values[is.finite(values)]
    !length(finite) || all(abs(finite - round(finite)) < 1e-10)
  }, logical(1))]
  decimal_columns <- setdiff(numeric_columns, integer_like)
  data[decimal_columns] <- lapply(data[decimal_columns], round, digits = digits)

  matched <- intersect(names(labels), names(data))
  names(data)[match(matched, names(data))] <- unname(labels[matched])
  numeric_display <- unname(ifelse(numeric_columns %in% matched,
    labels[numeric_columns], numeric_columns
  ))
  decimal_display <- unname(ifelse(decimal_columns %in% matched, labels[decimal_columns],
    decimal_columns
  ))

  widget <- DT::datatable(
    data,
    rownames = FALSE,
    filter = "top",
    class = "stripe hover compact premium-table",
    options = list(
      pageLength = as.integer(page_length),
      autoWidth = TRUE,
      scrollX = TRUE,
      fixedHeader = TRUE,
      dom = "t<'premium-table-footer'i<'premium-table-controls'lp>>",
      lengthMenu = list(
        c(10L, 25L, 50L, 100L, -1L),
        c("10", "25", "50", "100", "All")
      ),
      language = list(
        info = "Showing _START_–_END_ of _TOTAL_ records",
        infoEmpty = "No records",
        zeroRecords = "No matching records",
        lengthMenu = "Rows per page: _MENU_",
        paginate = list(previous = "Previous", `next` = "Next")
      )
    )
  )
  if (length(decimal_display)) widget <- DT::formatRound(widget, decimal_display, digits = digits)
  heat_colors <- c("#f8f3ef", "#eee3dd", "#dfccc2", "#cba38f", "#a96f58")
  for (column in numeric_display) {
    values <- data[[column]]
    finite <- values[is.finite(values)]
    if (!length(finite) || length(unique(finite)) < 2L) next
    cuts <- stats::quantile(
      finite,
      probs = seq(.2, .8, by = .2),
      na.rm = TRUE,
      names = FALSE
    )
    cuts <- unique(as.numeric(cuts))
    if (!length(cuts)) next
    palette <- heat_colors[round(seq(1, length(heat_colors), length.out = length(cuts) + 1L))]
    widget <- DT::formatStyle(
      widget, column,
      backgroundColor = DT::styleInterval(cuts, palette),
      color = "#3f343a",
      fontWeight = "600"
    )
  }
  widget
}
