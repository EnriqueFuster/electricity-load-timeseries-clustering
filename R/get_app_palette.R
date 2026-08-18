#' Return the shared visual palette
#' @return Named colours for the application and analytical plots.
get_app_palette <- function() {
  list(
    ink = "#2E292F",
    muted = "#756E69",
    primary = "#51434D",
    accent = "#C56F4A",
    algorithms = c(
      kmeans = "#51434D", pam = "#C56F4A", dtw_dba = "#60786B",
      hierarchical = "#756E69", kshape = "#8A6573", som = "#B18A45",
      gmm = "#866A7E", hdbscan = "#6D7B72", soft_dtw = "#C19A55",
      deep_autoencoder = "#A65F5B"
    ),
    quality = c(pass = "#60786B", warning = "#B98A3D", exclude = "#B45D55"),
    clusters = c("#51434D", "#C56F4A", "#60786B", "#8A6573", "#B18A45", "#A65F5B"),
    heatmap = c("#FBF7F2", "#F0DDD0", "#DDB59D", "#C58263", "#88594C", "#3F3034")
  )
}
