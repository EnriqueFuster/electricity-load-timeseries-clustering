#!/usr/bin/env Rscript

# The deployable demo is synthetic so the app remains small and does not
# redistribute a multi-gigabyte source archive. Every profile covers 2023.
set.seed(4107)
timestamp <- seq(
  as.POSIXct("2023-01-01 00:00:00", tz = "UTC"),
  as.POSIXct("2023-12-31 23:00:00", tz = "UTC"),
  by = "hour"
)
calendar <- as.POSIXlt(timestamp, tz = "UTC")
hour <- calendar$hour
weekday <- (calendar$wday + 6L) %% 7L + 1L
day_of_year <- calendar$yday + 1L

gaussian_peak <- function(center, width) exp(-0.5 * ((hour - center) / width)^2)
seasonal_wave <- cos(2 * pi * (day_of_year - 15) / 365)

build_profile <- function(index) {
  archetype <- (index - 1L) %% 4L + 1L
  amplitude <- 0.75 + 0.08 * index
  weekend <- weekday > 5L

  shape <- switch(archetype,
    0.22 + 0.55 * gaussian_peak(7.5, 1.7) + 0.95 * gaussian_peak(20, 2.3),
    0.28 + 1.10 * gaussian_peak(13, 3.2) + 0.25 * weekend,
    0.50 + 0.35 * gaussian_peak(8, 2) + 0.40 * gaussian_peak(18, 2.8),
    0.18 + 0.85 * gaussian_peak(1, 2.2) + 0.45 * gaussian_peak(23, 1.6)
  )
  seasonal_effect <- switch(archetype,
    1 + 0.28 * seasonal_wave,
    1 - 0.22 * seasonal_wave,
    1 + 0.10 * seasonal_wave,
    1 + 0.35 * seasonal_wave
  )
  noise <- stats::rnorm(length(timestamp), sd = 0.045 + index / 1500)
  value <- pmax(0.01, amplitude * shape * seasonal_effect + noise)

  data.frame(
    series_id = sprintf("synthetic_%02d", index),
    timestamp = timestamp,
    value = round(value, 4),
    imputed = 0L
  )
}

demo <- do.call(rbind, lapply(seq_len(24L), build_profile))
dir.create("data/demo", recursive = TRUE, showWarnings = FALSE)
utils::write.csv(demo, "data/demo/synthetic_load_curves.csv", row.names = FALSE)
message("Wrote 24 optional synthetic profiles with 8,760 hours each.")
