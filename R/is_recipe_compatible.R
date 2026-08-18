#' Check whether a recipe can operate on a representation family
#' @param recipe_row One catalog row.
#' @param representation_name Representation identifier.
#' @param representation_family Representation family.
#' @return Logical scalar.
is_recipe_compatible <- function(recipe_row, representation_name, representation_family) {
  scope <- recipe_row$representation_scope
  if (identical(scope, "all")) {
    return(TRUE)
  }
  if (identical(scope, "whole-series")) {
    return(identical(representation_name, "typical_week"))
  }
  if (identical(scope, "reduced")) {
    return(representation_family != "whole-series")
  }
  FALSE
}
