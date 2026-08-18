#' Close annual curves to unit-sum compositions
#' @param matrix Series-by-hour load matrix.
#' @return Matrix whose rows sum to one.
close_annual_composition <- function(matrix) {
  totals <- rowSums(matrix)
  if (any(!is.finite(totals) | totals <= 0)) {
    stop("Unit-sum and CLR representations require a positive annual total per series.")
  }
  sweep(matrix, 1L, totals, "/")
}
