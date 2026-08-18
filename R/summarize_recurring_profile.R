# Summarize repeated observations at the same recurring clock coordinate.
summarize_recurring_profile <- function(data, interval_column, probs) {
  groups <- split(data$value, data[[interval_column]])
  rows <- lapply(names(groups), function(interval) {
    values <- groups[[interval]]
    data.frame(
      interval = as.integer(interval),
      lower = stats::quantile(values, probs[1], na.rm = TRUE, names = FALSE),
      median = stats::median(values, na.rm = TRUE),
      upper = stats::quantile(values, probs[2], na.rm = TRUE, names = FALSE)
    )
  })
  output <- do.call(rbind, rows)
  output[order(output$interval), ]
}
