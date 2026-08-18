theory_entry <- function(
  id,
  title,
  family,
  summary,
  mechanics,
  use_when,
  limitations,
  compatibility,
  parameters = "No method-specific parameter.",
  interpretation = paste(
    "Interpret together with the original curves",
    "and validation results."
  )
) {
  list(
    id = id,
    title = title,
    family = family,
    lead = summary,
    sections = list(
      mechanics = mechanics,
      use_when = use_when,
      limitations = limitations,
      compatibility = compatibility,
      interpretation = interpretation
    ),
    summary = summary,
    mechanics = mechanics,
    use_when = use_when,
    limitations = limitations,
    compatibility = compatibility,
    parameters = parameters,
    interpretation = interpretation
  )
}

get_theory_catalog <- function() {
  entry <- theory_entry

  list(
    foundations = theory_foundations(entry),
    representations = theory_representations(entry),
    similarity = theory_similarity(entry),
    algorithms = theory_algorithms(entry),
    validation = theory_validation(entry)
  )
}

# Arrange the teaching catalogue in the same order as the experiment builder.
