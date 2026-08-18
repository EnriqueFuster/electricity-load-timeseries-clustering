main_run_models <- function(data, config) {
  message("Running data quality checks, preprocessing and model benchmark...")

  analysis <- run_clustering_pipeline(
    data = data,
    config = config
  )

  message(
    "Model selected: ",
    analysis$recommended$algorithm,
    " + ",
    analysis$recommended$distance,
    " on ",
    analysis$recommended$representation,
    " with k = ",
    analysis$recommended$k
  )

  analysis
}
