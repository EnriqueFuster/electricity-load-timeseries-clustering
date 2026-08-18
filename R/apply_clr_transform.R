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
