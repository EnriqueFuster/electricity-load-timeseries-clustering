#' Null-coalescing operator
#' @param x Candidate value.
#' @param y Fallback value.
#' @return `x` unless it is NULL.
`%||%` <- function(x, y) if (is.null(x)) y else x
