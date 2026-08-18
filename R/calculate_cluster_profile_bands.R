#' Calculate cluster profile quantile bands
#' @param matrix Series-by-hour normalized profile matrix.
#' @param clusters Cluster assignment vector aligned with matrix rows.
#' @param probs Three probabilities for lower, median and upper profiles.
#' @return Long data frame with cluster profile bands.
calculate_cluster_profile_bands <- function(matrix, clusters, probs = c(0.25, 0.5, 0.75)) {
  if (length(probs) != 3L || any(probs < 0 | probs > 1) || is.unsorted(probs)) {
    stop("probs must contain three ordered probabilities between 0 and 1.")
  }
  if (length(clusters) != nrow(matrix)) stop("clusters must align with matrix rows.")
  groups <- split(seq_len(nrow(matrix)), clusters)
  rows <- lapply(names(groups), function(cluster_id) {
    values <- matrix[groups[[cluster_id]], , drop = FALSE]
    quantiles <- apply(values, 2, stats::quantile, probs = probs, na.rm = TRUE)
    data.frame(
      cluster = as.integer(cluster_id),
      hour_of_week = seq_len(ncol(matrix)),
      lower = quantiles[1, ],
      median = quantiles[2, ],
      upper = quantiles[3, ]
    )
  })
  do.call(rbind, rows)
}
