# 09_validation_red_sea.R
# Owner: Su (taken over from John)
# Research question 4: does our Red Sea scenario match the countries affected
# by the February to March 2024 cuts?
#
# The reported list is made by hand in data/manual/red_sea_2024_reported.csv
# (country, source, url, note). Reports mostly show slowdowns and rerouting,
# while our model only shows countries that lose all access, so we compare
# the reported list with three model results:
#   model_cut_off       cut off in the red_sea corridor scenario (from 07)
#   model_lost_a_cable  has a landing point on at least one red_sea corridor cable
#   model_2024_cut_off  cut off when only the cables actually damaged in 2024
#                       fail, instead of every cable in the corridor box
#
# Input:  data/manual/red_sea_2024_reported.csv, results/corridor_cutoff.csv,
#         data/processed/corridor_cables.csv, data/processed/cable_landings.csv,
#         data/processed/landing_points.csv, data/processed/network.rds
# Output: results/red_sea_validation.csv

source("R/00_setup.R")
source("R/helpers.R")

reported <- read_csv(here("data", "manual", "red_sea_2024_reported.csv"), show_col_types = FALSE) |>
  filter(country != "EXAMPLE")
cutoff         <- read_csv(file.path(dir_results, "corridor_cutoff.csv"), show_col_types = FALSE)
corridors      <- read_csv(file.path(dir_processed, "corridor_cables.csv"), show_col_types = FALSE)
cable_landings <- read_csv(file.path(dir_processed, "cable_landings.csv"), show_col_types = FALSE)
landing_points <- read_csv(file.path(dir_processed, "landing_points.csv"), show_col_types = FALSE)
g              <- readRDS(file.path(dir_processed, "network.rds"))

unknown <- setdiff(reported$country, V(g)$name)
if (length(unknown) > 0) {
  stop("These reported countries are not spelled like the network: ",
       paste(unknown, collapse = ", "), call. = FALSE)
}

# ---- Model results ----------------------------------------------------------
red_sea_ids <- unique(corridors$cable_id[corridors$corridor == "red_sea"])

model_cut_off <- unique(cutoff$country[cutoff$corridor == "red_sea"])

model_lost_a_cable <- cable_landings |>
  filter(cable_id %in% red_sea_ids) |>
  left_join(select(landing_points, lp_id, country), by = "lp_id") |>
  distinct(country) |>
  pull(country)

# Cables reported damaged in 2024: Seacom, AAE-1 and EIG (Kentik, Cloudflare),
# and TGN-Gulf (named by HGC). Same failure rule as 07.
cables_2024 <- c("seacomtata-tgn-eurasia", "asia-africa-europe-1-aae-1",
                 "europe-india-gateway-eig", "tata-tgn-gulf")
missing_2024 <- setdiff(cables_2024, cable_landings$cable_id)
if (length(missing_2024) > 0) warning("Not in the snapshot: ", paste(missing_2024, collapse = ", "))

baseline_outside <- cut_off_countries(g)
g_2024 <- delete_edges(g, which(E(g)$cable_id %in% cables_2024))
model_2024_cut_off <- cut_off_countries(g_2024, ignore = baseline_outside)

# ---- Compare ----------------------------------------------------------------
validation <- tibble(country = sort(unique(c(reported$country, model_cut_off,
                                              model_lost_a_cable, model_2024_cut_off)))) |>
  mutate(
    reported           = country %in% reported$country,
    model_cut_off      = country %in% model_cut_off,
    model_lost_a_cable = country %in% model_lost_a_cable,
    model_2024_cut_off = country %in% model_2024_cut_off
  )

write_csv(validation, file.path(dir_results, "red_sea_validation.csv"))

compare <- function(col, label) {
  pred <- validation[[col]]
  rep  <- validation$reported
  list_or_none <- function(x) if (length(x) == 0) "none" else paste(x, collapse = ", ")
  message("---- ", label, " ----")
  message("Matches (", sum(pred & rep), "): ", list_or_none(validation$country[pred & rep]))
  message("Misses (", sum(!pred & rep), "): ", list_or_none(validation$country[!pred & rep]))
  message("False alarms (", sum(pred & !rep), "): ", list_or_none(validation$country[pred & !rep]))
}

message("Reported countries: ", nrow(reported), "  Red Sea corridor cables: ", length(red_sea_ids),
        "  Cables damaged in 2024: ", length(cables_2024))
compare("model_cut_off", "Cut off, whole corridor")
compare("model_lost_a_cable", "Lost at least one cable, whole corridor")
compare("model_2024_cut_off", "Cut off, only the 2024 cables")
