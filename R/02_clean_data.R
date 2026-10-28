# 02_clean_data.R
# Owner: John
# Turns the raw JSON files into two clean tables:
#   data/processed/cable_landings.csv   one row per (cable, landing point)
#   data/processed/landing_points.csv   one row per landing point, with country and coordinates
#
# Input:  data/raw/*.json (from 01_download_data.R)
# Output: the two csv files above

source("R/00_setup.R")

# ---- Read raw files ---------------------------------------------------------
cable_all <- fromJSON(file.path(dir_raw, "cable_all.json"))
lp_geo    <- st_read(file.path(dir_raw, "landing_point_geo.json"), quiet = TRUE)

# ---- Landing points ---------------------------------------------------------
# TODO (John): split the landing point name into place and country.
# Names look like "Place, Country". Watch for names with extra commas
# (for example "City, State, United States").
landing_points <- lp_geo |>
  mutate(
    lp_id   = id,
    lp_name = name
    # country = ...
  )

# ---- Cable to landing point table ------------------------------------------
# TODO (John): read each file in data/raw/cables/ and build one row per
# (cable_id, lp_id).
cable_landings <- tibble(cable_id = character(), lp_id = character())

# ---- Checks -----------------------------------------------------------------
# TODO (John): confirm no landing point has a missing country, and decide how
# to treat territories (for example Guam, Puerto Rico, Hong Kong).
# Write the decision in docs/data_notes.md.

# ---- Save -------------------------------------------------------------------
# write_csv(st_drop_geometry(landing_points), file.path(dir_processed, "landing_points.csv"))
# write_csv(cable_landings, file.path(dir_processed, "cable_landings.csv"))
