#' Extract interpretable meter-level consumption features
#' @param data Clean hourly observations.
#' @return Series-by-feature matrix scaled feature by feature.
build_behavioral_feature_matrix <- function(data) {
  groups <- split(data, data$series_id)

  features <- lapply(groups, function(series) {
    calendar <- as.POSIXlt(series$timestamp, tz = "UTC")
    hour <- calendar$hour
    weekday <- (calendar$wday + 6L) %% 7L + 1L
    month <- calendar$mon + 1L
    season <- ifelse(month %in% c(12L, 1L, 2L), "winter",
      ifelse(month %in% 3:5, "spring", ifelse(month %in% 6:8, "summer", "autumn"))
    )
    value <- series$value
    daily_energy <- tapply(value, as.Date(series$timestamp), sum, na.rm = TRUE)
    hourly_mean <- tapply(value, hour, mean, na.rm = TRUE)
    period_share <- function(from, to) {
      sum(value[hour >= from & hour < to],
        na.rm = TRUE
      ) / sum(value, na.rm = TRUE)
    }
    conditioned_mean <- function(index, level) mean(value[index == level], na.rm = TRUE)

    output <- c(
      mean_hourly_kwh = mean(value, na.rm = TRUE),
      median_daily_kwh = stats::median(daily_energy, na.rm = TRUE),
      p95_daily_kwh = unname(stats::quantile(daily_energy, .95, na.rm = TRUE)),
      load_factor = mean(value, na.rm = TRUE) / max(value, na.rm = TRUE),
      hourly_variability = stats::sd(value, na.rm = TRUE) / mean(value, na.rm = TRUE),
      daily_variability = stats::sd(daily_energy, na.rm = TRUE) / mean(daily_energy, na.rm = TRUE),
      peak_hour_sin = sin(2 * pi * as.numeric(names(hourly_mean)[which.max(hourly_mean)]) / 24),
      peak_hour_cos = cos(2 * pi * as.numeric(names(hourly_mean)[which.max(hourly_mean)]) / 24),
      night_share = period_share(0, 7),
      morning_share = period_share(7, 11),
      daytime_share = period_share(11, 17),
      evening_share = period_share(17, 22),
      late_night_share = period_share(22, 24),
      weekday_mean = conditioned_mean(ifelse(weekday <= 5L, "weekday", "weekend"), "weekday"),
      weekend_mean = conditioned_mean(ifelse(weekday <= 5L, "weekday", "weekend"), "weekend")
    )
    seasonal <- vapply(
      c("winter", "spring", "summer", "autumn"),
      function(x) conditioned_mean(season, x), numeric(1)
    )
    c(output, stats::setNames(seasonal, paste0(names(seasonal), "_mean")))
  })

  matrix <- do.call(rbind, features)
  matrix <- matrix[, colSums(is.finite(matrix)) > 0L, drop = FALSE]
  for (column in seq_len(ncol(matrix))) {
    missing <- !is.finite(matrix[, column])
    if (any(missing)) matrix[missing, column] <- stats::median(matrix[, column], na.rm = TRUE)
  }
  keep <- vapply(seq_len(ncol(matrix)), function(column) {
    deviation <- stats::sd(matrix[, column])
    is.finite(deviation) && deviation > .Machine$double.eps^0.5
  }, logical(1))
  matrix <- matrix[, keep, drop = FALSE]
  scale(matrix)
}
