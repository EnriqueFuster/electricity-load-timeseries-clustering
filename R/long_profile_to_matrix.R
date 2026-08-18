# Convert an equally spaced long profile into a series-by-interval matrix.
long_profile_to_matrix <- function(data, intervals) {
  ids <- sort(unique(data$series_id))
  output <- matrix(NA_real_, nrow = length(ids), ncol = intervals, dimnames = list(ids, NULL))
  output[cbind(match(data$series_id, ids), data$interval)] <- data$value
  if (any(!is.finite(output))) stop("The profile view contains incomplete hourly intervals.")
  output
}
