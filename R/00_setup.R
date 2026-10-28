# 00_setup.R
# Owner: Sultan
# Installs (if missing) and loads every package the project uses.
# Other scripts start with: source("R/00_setup.R")

pkgs <- c("jsonlite", "dplyr", "tidyr", "tibble", "readr", "stringr",
          "igraph", "ggplot2", "sf", "here")

missing_pkgs <- pkgs[!pkgs %in% rownames(installed.packages())]
if (length(missing_pkgs) > 0) install.packages(missing_pkgs)

invisible(lapply(pkgs, library, character.only = TRUE))

# Shared folder paths
dir_raw       <- here("data", "raw")
dir_processed <- here("data", "processed")
dir_results   <- here("results")
dir_figures   <- here("figures")

for (d in c(dir_raw, dir_processed, dir_results, dir_figures)) {
  dir.create(d, recursive = TRUE, showWarnings = FALSE)
}

# Fixed seed so random network comparisons can be reproduced
set.seed(421)
