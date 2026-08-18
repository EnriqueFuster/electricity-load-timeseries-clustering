#' Create deterministic plain-language pipeline conclusions
#' @param result Output from run_clustering_pipeline().
#' @return Character vector of conclusion lines.
summarize_pipeline_results <- function(result) {
  rec <- result$recommended[1, ]
  accepted <- sum(result$quality$quality_status != "exclude")
  excluded <- sum(result$quality$quality_status == "exclude")
  sizes <- sort(table(result$assignments$cluster), decreasing = TRUE)
  most_atypical <- result$assignments[which.max(result$assignments$atypicality_percentile), ]
  representation <- rec$representation %||% "typical_week"
  c(
    sprintf("Data quality: %d series accepted and %d excluded.", accepted, excluded),
    sprintf(
      paste0(
        "Recommendation: %s + %s on %s with k = %d (silhouette %.3f, conditional subsample ",
        "stability %.3f, balance %.3f)."
      ),
      rec$algorithm,
      rec$distance %||% "euclidean",
      representation,
      rec$k,
      rec$silhouette,
      rec$stability,
      rec$cluster_balance
    ),
    sprintf("Cluster sizes: %s.", paste(sprintf("C%s=%s", names(sizes), as.integer(sizes)),
      collapse = ", "
    )),
    sprintf(
      "Most atypical profile within its assigned cluster: %s (cluster %d, percentile %.2f).",
      most_atypical$series_id, most_atypical$cluster, most_atypical$atypicality_percentile
    ),
    paste0(
      "Interpretation: these are internally supported segments, not supervised ",
      "classes or causal customer types."
    )
  )
}
