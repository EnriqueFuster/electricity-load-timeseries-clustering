#' Build exact, method-consistent diagnostics for an active partition
#' @param result Materialized pipeline result returned by select_pipeline_model().
#' @return Named list of diagnostic data frames and the exact distance matrix.
build_common_diagnostic_data <- function(result) {
  matrix <- result$matrix
  fit <- result$fit
  clusters <- fit$cluster[rownames(matrix)]
  window_size <- result$config$modeling$dtw_window_size %||% 12L

  distance <- fit$distance_matrix
  if (is.null(distance)) {
    distance <- calculate_distance_matrix(matrix, fit$distance %||% "euclidean", window_size)
  }
  distance_matrix <- as.matrix(distance)
  rownames(distance_matrix) <- colnames(distance_matrix) <- rownames(matrix)

  non_noise <- clusters != 0L
  silhouette_rows <- data.frame(
    series_id = names(clusters), cluster = as.integer(clusters),
    silhouette = NA_real_, stringsAsFactors = FALSE
  )
  evaluable_clusters <- clusters[non_noise]
  if (sum(non_noise) >= 3L && length(unique(evaluable_clusters)) >= 2L) {
    evaluated_distance <- stats::as.dist(distance_matrix[non_noise, non_noise, drop = FALSE])
    widths <- cluster::silhouette(as.integer(factor(evaluable_clusters)), evaluated_distance)
    silhouette_rows$silhouette[non_noise] <- widths[, "sil_width"]
  }
  silhouette_rows <- silhouette_rows[order(silhouette_rows$cluster, silhouette_rows$silhouette), ]
  silhouette_rows$order <- seq_len(nrow(silhouette_rows))

  peer_distance <- vapply(seq_len(nrow(distance_matrix)), function(index) {
    peers <- which(clusters == clusters[index] & seq_along(clusters) != index)
    if (!length(peers)) {
      return(0)
    }
    mean(distance_matrix[index, peers])
  }, numeric(1))

  nearest_cluster <- rep(NA_integer_, nrow(distance_matrix))
  nearest_cluster_distance <- rep(NA_real_, nrow(distance_matrix))
  non_noise_clusters <- sort(unique(clusters[non_noise]))
  for (index in which(non_noise)) {
    alternatives <- setdiff(non_noise_clusters, clusters[index])
    if (!length(alternatives)) {
      next
    }

    alternative_distances <- vapply(alternatives, function(cluster_id) {
      mean(distance_matrix[index, clusters == cluster_id])
    }, numeric(1))
    nearest <- which.min(alternative_distances)
    nearest_cluster[index] <- alternatives[nearest]
    nearest_cluster_distance[index] <- alternative_distances[nearest]
  }

  distance_rows <- data.frame(
    series_id = names(clusters), cluster = as.integer(clusters),
    mean_peer_distance = peer_distance,
    nearest_cluster = nearest_cluster,
    nearest_cluster_distance = nearest_cluster_distance,
    separation_margin = nearest_cluster_distance - peer_distance,
    stringsAsFactors = FALSE
  )

  ordering <- order(clusters, names(clusters))
  ordered_ids <- names(clusters)[ordering]
  heatmap <- expand.grid(
    row = seq_along(ordered_ids), column = seq_along(ordered_ids),
    KEEP.OUT.ATTRS = FALSE
  )
  heatmap$distance <- as.vector(distance_matrix[ordered_ids, ordered_ids, drop = FALSE])
  heatmap$row_profile <- ordered_ids[heatmap$row]
  heatmap$column_profile <- ordered_ids[heatmap$column]
  heatmap$row_cluster <- as.integer(clusters[heatmap$row_profile])
  heatmap$column_cluster <- as.integer(clusters[heatmap$column_profile])

  list(
    distance_matrix = distance_matrix,
    silhouette = silhouette_rows,
    peer_distance = distance_rows,
    dissimilarity_heatmap = heatmap
  )
}
