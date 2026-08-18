#' Calculate the adjusted Rand index
#' @param x First partition.
#' @param y Second partition.
#' @return Adjusted Rand index.
calculate_adjusted_rand <- function(x, y) {
  tab <- table(x, y)
  choose2 <- function(z) z * (z - 1) / 2
  a <- sum(choose2(tab))
  row_pairs <- sum(choose2(rowSums(tab)))
  col_pairs <- sum(choose2(colSums(tab)))
  total <- choose2(sum(tab))
  expected <- row_pairs * col_pairs / total
  maximum <- (row_pairs + col_pairs) / 2
  if (maximum == expected) {
    return(1)
  }
  (a - expected) / (maximum - expected)
}
