#' Normalize representation rows
#' @param matrix Numeric matrix.
#' @param method zscore, unit_sum, or none.
#' @return Normalized matrix.
normalize_load_curve <- function(matrix, method = "zscore") {
  if (method == "none") {
    return(matrix)
  }
  if (method == "unit_sum") {
    return(matrix / rowSums(matrix))
  }
  if (method != "zscore") stop("Unknown normalization method: ", method)
  means <- rowMeans(matrix)
  sds <- apply(matrix, 1, stats::sd)
  if (any(sds < .Machine$double.eps^0.5)) stop("Cannot z-normalize a constant profile.")
  sweep(sweep(matrix, 1, means, "-"), 1, sds, "/")
}
