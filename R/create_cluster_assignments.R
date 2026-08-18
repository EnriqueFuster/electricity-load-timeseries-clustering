#' Build assignment and atypicality output
#' @param clusters Named cluster labels.
#' @param distances Named mean dissimilarities to peers in the assigned cluster.
#' @return Assignment data frame.
create_cluster_assignments <- function(clusters, distances) {
  percentile <- ave(distances, clusters, FUN = function(x) {
    rank(x,
      ties.method = "average"
    ) / length(x)
  })
  data.frame(
    series_id = names(clusters), cluster = as.integer(clusters),
    mean_within_cluster_dissimilarity = as.numeric(distances),
    atypicality_percentile = as.numeric(percentile), row.names = NULL
  )
}
