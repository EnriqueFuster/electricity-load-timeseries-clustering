#' Define chronologically defensible seasonal catch22 blocks
#'
#' Winter is treated as a cyclic December-to-February sequence. Starting the
#' block in December avoids the artificial February-to-December adjacency that
#' would result from filtering a January-to-December matrix without reordering.
#' @param month Integer month for each annual matrix column.
#' @return Named list of ordered column indices.
seasonal_catch22_blocks <- function(month) {
  list(
    winter = c(which(month == 12L), which(month %in% c(1L, 2L))),
    spring = which(month %in% 3:5),
    summer = which(month %in% 6:8),
    autumn = which(month %in% 9:11)
  )
}
