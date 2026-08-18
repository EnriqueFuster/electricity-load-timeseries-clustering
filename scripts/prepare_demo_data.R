#!/usr/bin/env Rscript

# The local source path is supplied at runtime; it is never embedded in public code.
args <- commandArgs(trailingOnly = TRUE)
source_root <- if (length(args)) args[1] else Sys.getenv("GOIENER_DATA_ROOT")
output_file <- if (length(args) >= 2L) args[2] else "data/processed/goiener_complete_year.csv"
if (!nzchar(source_root) || !dir.exists(source_root)) {
  stop("Pass the GoiEnergy root or set GOIENER_DATA_ROOT.")
}
source(file.path("R", "find_complete_natural_years.R"))

metadata <- utils::read.csv(file.path(source_root, "metadata.csv"), stringsAsFactors = FALSE)
eligible <- metadata[metadata$length_days >= 365 & metadata$missing_samples_pct <= 1, ]
eligible <- eligible[order(eligible$user), ]
folders <- c("goi4_pre", "goi4_in", "goi4_pst")
available <- unlist(lapply(folders, function(folder) {
  list.files(file.path(source_root, folder),
    pattern = "\\.csv$", recursive = TRUE,
    full.names = TRUE
  )
}), use.names = FALSE)
available_by_user <- split(available, tools::file_path_sans_ext(basename(available)))

selected <- list()
for (user in eligible$user) {
  candidates <- available_by_user[[user]]
  if (!length(candidates)) next
  x <- utils::read.csv(candidates[1], stringsAsFactors = FALSE)
  x$timestamp <- as.POSIXct(x$timestamp, tz = "UTC")
  x <- x[order(x$timestamp), ]
  annual <- find_complete_natural_years(x, max_missing_pct = 1)
  complete_years <- annual$year[annual$complete]
  if (!length(complete_years)) next
  selected_year <- max(complete_years)
  demo <- x[as.integer(format(x$timestamp, "%Y", tz = "UTC")) == selected_year, ]
  expected <- if (selected_year %% 4L == 0L) 8784L else 8760L
  if (nrow(demo) != expected || anyNA(demo$kWh)) next
  demo$series_id <- sprintf("meter_%02d", length(selected) + 1L)
  selected[[length(selected) + 1L]] <- demo[c("series_id", "timestamp", "kWh", "imputed")]
  if (length(selected) == 24L) break
}
if (length(selected) < 12L) stop("Could not find enough complete natural-year series.")
out <- do.call(rbind, selected)
names(out)[names(out) == "kWh"] <- "value"
dir.create(dirname(output_file), recursive = TRUE, showWarnings = FALSE)
utils::write.csv(out, output_file, row.names = FALSE)
cat("Wrote", length(unique(out$series_id)), "series and", nrow(out), "rows to", output_file, "\n")
