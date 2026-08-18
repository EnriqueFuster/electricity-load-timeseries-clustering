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

#' Replace zeros before applying a log-ratio transform
#' @param composition Positive or zero unit-sum rows.
#' @param fraction Replacement as a fraction of the smallest positive row value.
#' @return Reclosed strictly positive composition.
replace_compositional_zeros <- function(composition, fraction = 0.5) {
  if (!is.numeric(fraction) || fraction <= 0 || fraction >= 1) {
    stop("The CLR zero-replacement fraction must be in (0, 1).")
  }

  replace_row <- function(values) {
    zero <- values <= 0
    if (!any(zero)) {
      return(values)
    }
    positive <- values[values > 0]
    if (!length(positive)) stop("CLR cannot transform an all-zero series.")
    values[zero] <- min(positive) * fraction
    values / sum(values)
  }
  replaced <- t(apply(composition, 1L, replace_row))
  dimnames(replaced) <- dimnames(composition)
  replaced
}

#' Apply the centred log-ratio transform row by row
#' @param composition Strictly positive compositional matrix.
#' @return CLR coordinates with a zero row mean (up to numerical precision).
apply_clr_transform <- function(composition) {
  if (any(!is.finite(composition) | composition <= 0)) {
    stop("CLR requires strictly positive, finite values.")
  }
  logged <- log(composition)
  sweep(logged, 1L, rowMeans(logged), "-")
}
