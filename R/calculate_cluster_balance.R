#' Calculate smallest-to-largest cluster size ratio
#' @param clusters Cluster labels.
#' @return Ratio in [0, 1].
calculate_cluster_balance <- function(clusters) {
  sizes <- table(clusters)
  as.numeric(min(sizes) / max(sizes))
}
