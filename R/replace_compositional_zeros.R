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
    if (!any(zero)) return(values)
    positive <- values[values > 0]
    if (!length(positive)) stop("CLR cannot transform an all-zero series.")
    values[zero] <- min(positive) * fraction
    values / sum(values)
  }
  replaced <- t(apply(composition, 1L, replace_row))
  dimnames(replaced) <- dimnames(composition)
  replaced
}
