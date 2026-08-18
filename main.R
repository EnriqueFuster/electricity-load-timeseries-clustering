############################
#### - RUN PARAMETERS - ####

config_file <- "config/demo.yml"
input_mode <- "long" # 'long' or 'folder'
input_path <- "data/demo/load_curves.csv"
output_path <- "results/main"

show_plots <- interactive()
save_plots <- TRUE


########################
##### - PRELOAD - ######

source("scripts/main_run_preload.R")
config <- main_preload(config_file)


###########################
##### - INPUT DATA - ######

source("scripts/main_run_input.R")
input_data <- main_read_input(
  input_path = input_path,
  input_mode = input_mode,
  config = config
)


########################
##### - MODELING - #####

source("scripts/main_run_models.R")
analysis <- main_run_models(
  data = input_data$data,
  config = config
)


############################
##### - REVIEW RESULTS - ####

source("scripts/main_review_results.R")
analysis <- main_review_results(
  analysis = analysis,
  show_plots = show_plots
)


############################
##### - SAVE RESULTS - #####

source("scripts/main_save_results.R")
main_save_results(
  analysis = analysis,
  config = config,
  output_path = output_path,
  save_plots = save_plots
)
