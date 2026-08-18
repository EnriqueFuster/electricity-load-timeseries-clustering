# PROJECT -----------------------------------------------------------------

project_root <- if (dir.exists("R") && dir.exists("app")) "." else ".."
project_root <- normalizePath(project_root, winslash = "/", mustWork = TRUE)

source(file.path(project_root, "app", "bootstrap", "load_app.R"))
load_application(project_root)


# CONFIGURATION -----------------------------------------------------------

options(shiny.maxRequestSize = 50 * 1024^2)
app_config <- load_shiny_config(project_root)


# APPLICATION -------------------------------------------------------------

ui <- build_app_ui(app_config)
server <- build_app_server(app_config)

shiny::shinyApp(ui = ui, server = server)
