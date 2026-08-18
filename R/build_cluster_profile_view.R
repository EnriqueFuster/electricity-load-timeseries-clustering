#' Prepare cluster curves for a selected time horizon
#'
#' The clustering result is not refitted here. This function only changes the
#' time scale used to inspect the members of the active clusters.
#' @param result Output from run_clustering_pipeline().
#' @param horizon One of daily, weekly, or annual.
#' @param probs Lower and upper probabilities used for the profile ribbon.
#' @return A list with member curves, hourly summaries and axis metadata.
build_cluster_profile_view <- function(result, horizon = "weekly", probs = c(0.25, 0.75)) {
  horizon <- match.arg(horizon, c("daily", "weekly", "annual"))
  invalid_probabilities <- length(probs) != 2L ||
    any(!is.finite(probs)) ||
    any(probs < 0 | probs > 1) ||
    probs[1] >= probs[2]

  if (invalid_probabilities) {
    stop("probs must contain two increasing probabilities between 0 and 1.")
  }
  normalization <- result$config$preprocessing$normalization

  if (horizon == "daily") {
    daily <- result$clean
    daily$interval <- as.integer(format(daily$timestamp, "%H", tz = "UTC")) + 1L
    daily <- stats::aggregate(value ~ series_id + interval, daily, stats::median, na.rm = TRUE)
    matrix <- long_profile_to_matrix(daily, 24L)
    axis <- list(
      label = "Hour of day", breaks = c(1, 4, 8, 12, 16, 20, 24),
      labels = c("00", "03", "07", "11", "15", "19", "23")
    )
  } else if (horizon == "weekly") {
    matrix <- result$weekly_matrix
    axis <- list(
      label = "Hour of week", breaks = seq(1, 168, 24),
      labels = c("Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun")
    )
  } else {
    matrix <- normalize_load_curve(build_annual_hourly_matrix(result$clean), normalization)
    axis <- list(label = "Month", breaks = c(
      1, 745, 1417, 2161, 2881, 3625,
      4345, 5089, 5833, 6553, 7297, 8017
    ), labels = month.abb)
  }

  if (horizon == "daily") matrix <- normalize_load_curve(matrix, normalization)
  assignments <- result$assignments[c("series_id", "cluster")]
  members <- data.frame(
    series_id = rep(rownames(matrix), each = ncol(matrix)),
    interval = rep(seq_len(ncol(matrix)), nrow(matrix)),
    normalized_value = as.vector(t(matrix)),
    stringsAsFactors = FALSE
  )
  members <- merge(members, assignments, by = "series_id", sort = FALSE)
  members <- members[order(members$cluster, members$series_id, members$interval), ]

  ribbon_observations <- if (horizon %in% c("daily", "weekly")) {
    build_cluster_ribbon_observations(result, horizon, normalization)
  } else {
    members
  }
  summaries <- do.call(rbind, lapply(split(
    ribbon_observations,
    list(ribbon_observations$cluster, ribbon_observations$interval)
  ), function(values) {
    data.frame(
      cluster = values$cluster[1], interval = values$interval[1],
      lower = stats::quantile(values$normalized_value, probs[1], na.rm = TRUE, names = FALSE),
      median = stats::median(values$normalized_value, na.rm = TRUE),
      upper = stats::quantile(values$normalized_value, probs[2], na.rm = TRUE, names = FALSE)
    )
  }))

  widths <- summaries$upper - summaries$lower
  list(
    members = members,
    observations = ribbon_observations,
    summaries = summaries,
    axis = axis,
    horizon = horizon,
    probs = probs,
    ribbon_basis = if (horizon %in% c(
      "daily",
      "weekly"
    )) {
      "source observations"
    } else {
      "member profiles"
    },
    ribbon_width = list(
      median = stats::median(widths, na.rm = TRUE),
      maximum = max(widths, na.rm = TRUE),
      positive_share = mean(widths > sqrt(.Machine$double.eps), na.rm = TRUE)
    )
  )
}
