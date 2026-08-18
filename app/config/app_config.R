load_shiny_config <- function(root) {
  palette <- get_app_palette()

  list(
    root = root,
    palette = palette,
    theme = bslib::bs_theme(
      version = 5,
      bg = "#F4F1EC",
      fg = palette$ink,
      primary = palette$primary,
      secondary = palette$muted,
      base_font = bslib::font_google("Inter"),
      heading_font = bslib::font_google("Inter")
    ),
    web_limits = list(rows = 750000L, series = 80L)
  )
}
