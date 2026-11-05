# 02_clean_data.R
# Owner: Su (taken over from John)
# Turns the raw JSON files into two clean tables:
#   data/processed/cable_landings.csv   one row per (cable, landing point)
#   data/processed/landing_points.csv   one row per landing point, with country and coordinates
#
# Input:  data/raw/*.json and data/raw/cables/*.json (from 01_download_data.R)
# Output: the two csv files above
#
# Cleaning decisions are written down in docs/data_notes.md.

source("R/00_setup.R")

current_year <- as.integer(format(Sys.Date(), "%Y"))

# ---- Read raw files ---------------------------------------------------------
lp_geo <- st_read(file.path(dir_raw, "landing_point_geo.json"), quiet = TRUE)

cable_files <- list.files(file.path(dir_raw, "cables"), pattern = "\\.json$",
                          full.names = TRUE)
if (length(cable_files) == 0) stop("No files in data/raw/cables/. Run 01_download_data.R first.")

# ---- Cable to landing point table ------------------------------------------
# One row per (cable, landing point). The per cable files also give the
# country of each landing point, which is more reliable than splitting names.
read_cable <- function(f) {
  d  <- fromJSON(f)
  lp <- d$landing_points
  if (!is.data.frame(lp) || nrow(lp) == 0) return(NULL)
  tibble(
    cable_id   = d$id,
    cable_name = d$name,
    lp_id      = lp$id,
    lp_country = lp$country,
    rfs_year   = if (is.null(d$rfs_year)) NA_integer_ else as.integer(d$rfs_year),
    is_planned = isTRUE(d$is_planned)
  )
}

all_landings <- bind_rows(lapply(cable_files, read_cable)) |>
  distinct(cable_id, lp_id, .keep_all = TRUE)

# Planned cables: drop cables marked planned or with a ready for service year
# after the current year, because they cannot fail yet. A cable that is not
# planned but has no year is kept (there were none in the 2026-11-04 snapshot).
cable_landings <- all_landings |>
  filter(!is_planned, is.na(rfs_year) | rfs_year <= current_year) |>
  select(cable_id, cable_name, lp_id, rfs_year, is_planned) |>
  arrange(cable_id, lp_id)

# ---- Landing points ---------------------------------------------------------
# Country rule: use the country from the per cable files. Only if that is
# missing, fall back to the text after the last comma in the name. The
# fallback gets names like "Muanda, Congo, Dem. Rep." wrong, which is why it
# is only a fallback.
# Territories (Guam, Puerto Rico, Hong Kong, Greenland, ...) keep the label
# TeleGeography gives them, so they stay as their own nodes.
lp_country <- all_landings |>
  distinct(lp_id, lp_country)

if (any(duplicated(lp_country$lp_id))) {
  stop("Some landing points have more than one country in the cable files: ",
       paste(unique(lp_country$lp_id[duplicated(lp_country$lp_id)]), collapse = ", "))
}

coords <- st_coordinates(lp_geo)

landing_points <- lp_geo |>
  st_drop_geometry() |>
  transmute(lp_id = id, lp_name = name, lon = coords[, 1], lat = coords[, 2]) |>
  left_join(lp_country, by = "lp_id") |>
  mutate(
    name_country = str_trim(str_replace(lp_name, "^.*,", "")),
    used_fallback = is.na(lp_country) | lp_country == "",
    country = if_else(used_fallback, name_country, lp_country),
    # place is the name without ", <country>" at the end
    place = if_else(
      str_ends(lp_name, fixed(paste0(", ", country))),
      str_sub(lp_name, 1, -(nchar(country) + 3)),
      str_trim(str_replace(lp_name, ",[^,]*$", ""))
    )
  )

n_fallback <- sum(landing_points$used_fallback)

# Keep only landing points used by a cable that is in service, so a place
# that only has planned cables is not a node yet.
landing_points <- landing_points |>
  filter(lp_id %in% cable_landings$lp_id) |>
  select(lp_id, lp_name, place, country, lon, lat) |>
  arrange(lp_id)

# ---- Checks -----------------------------------------------------------------
if (any(is.na(landing_points$country) | landing_points$country == "")) {
  stop("Some landing points have no country: ",
       paste(landing_points$lp_id[is.na(landing_points$country) | landing_points$country == ""],
             collapse = ", "))
}

missing_lp <- setdiff(cable_landings$lp_id, landing_points$lp_id)
if (length(missing_lp) > 0) {
  stop("These lp_id values are in cable_landings but not in landing_points: ",
       paste(missing_lp, collapse = ", "))
}

if (any(is.na(landing_points$lon) | is.na(landing_points$lat))) {
  warning("Some landing points have no coordinates.")
}

# ---- Save -------------------------------------------------------------------
write_csv(landing_points, file.path(dir_processed, "landing_points.csv"))
write_csv(cable_landings, file.path(dir_processed, "cable_landings.csv"))

n_cables_all <- n_distinct(all_landings$cable_id)
n_cables_kept <- n_distinct(cable_landings$cable_id)

message("Cables: ", n_cables_all, " in raw data, ", n_cables_kept, " in service kept, ",
        n_cables_all - n_cables_kept, " planned or future dropped.")
message("cable_landings.csv: ", nrow(cable_landings), " rows")
message("landing_points.csv: ", nrow(landing_points), " rows")
message("Countries and territories: ", n_distinct(landing_points$country))
message("Landing points that needed the name split fallback: ", n_fallback)
