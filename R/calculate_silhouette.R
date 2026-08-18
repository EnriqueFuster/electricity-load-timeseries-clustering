#' Calculate average silhouette width
#' @param clusters Cluster labels.
#' @param distances A dist object.
#' @return Mean silhouette width.
calculate_silhouette <- function(clusters, distances) {
  if (length(unique(clusters)) < 2L) {
    return(NA_real_)
  }
  mean(cluster::silhouette(as.integer(factor(clusters)), distances)[, "sil_width"])
}
