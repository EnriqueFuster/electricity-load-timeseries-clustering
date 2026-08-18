#' Select a model using transparent multi-criteria ranking
#' @param metrics Benchmark metrics.
#' @param min_cluster_share Minimum acceptable implied cluster share.
#' @param min_stability Minimum accepted subsample ARI.
#' @param min_silhouette Minimum accepted silhouette.
#' @param max_noise_share Maximum HDBSCAN noise share.
#' @param weights Named silhouette, stability and balance weights.
#' @return One metrics row with selection details.
select_recommended_model <- function(metrics, min_cluster_share = 0.05,
                                     min_stability = 0, min_silhouette = -1,
                                     max_noise_share = 0.2,
                                     weights = c(
                                       silhouette = .55, stability = .30,
                                       balance = .15
                                     )) {
  valid <- metrics[metrics$status == "ok" & !is.na(metrics$silhouette), ]
  if ("smallest_cluster_share" %in% names(valid)) {
    valid <- valid[valid$smallest_cluster_share >= min_cluster_share, , drop = FALSE]
  }
  valid$stability[is.na(valid$stability)] <- 0
  valid <- valid[valid$stability >= min_stability & valid$silhouette >= min_silhouette, ,
    drop = FALSE
  ]
  if ("noise_share" %in% names(valid)) {
    valid <- valid[is.na(valid$noise_share) | valid$noise_share <= max_noise_share, , drop = FALSE]
  }
  if (!nrow(valid)) stop("No successful model is available for selection.")
  weights <- weights / sum(weights)
  scale01 <- function(x) {
    if (diff(range(
      x,
      na.rm = TRUE
    )) == 0) {
      rep(
        1,
        length(x)
      )
    } else {
      (x - min(
        x,
        na.rm = TRUE
      )) / diff(range(
        x,
        na.rm = TRUE
      ))
    }
  }
  valid$selection_score <- weights[["silhouette"]] * scale01(valid$silhouette) +
    weights[["stability"]] * scale01(replace(valid$stability, is.na(valid$stability), 0)) +
    weights[["balance"]] * scale01(valid$cluster_balance) - 0.01 * valid$k
  valid <- valid[order(-valid$selection_score, valid$k, valid$runtime_seconds), ]
  valid$selection_reason <- paste0(
    "Highest weighted silhouette/subsample-stability/balance score among candidates with at least ",
    sprintf(
      "%.0f%%",
      100 * min_cluster_share
    ),
    " of meters in every cluster and the configured evidence thresholds; small complexity penalty"
  )
  valid[1, ]
}
