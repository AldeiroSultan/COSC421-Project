# 01_download_data.R
# Owner: John
# Downloads the TeleGeography Submarine Cable Map data into data/raw/.
# Raw files are not committed to Git. Anyone can rebuild them by running this script.
#
# NOTE: confirm the URLs below against https://www.submarinecablemap.com
# (or the GitHub mirror your team picks) before running. Endpoints can change.

source("R/00_setup.R")

base_url <- "https://www.submarinecablemap.com/api/v3"

files <- c(
  cable_geo         = "cable/cable-geo.json",          # cable routes (lines)
  landing_point_geo = "landing-point/landing-point-geo.json",  # landing points (points)
  cable_all         = "cable/all.json"                 # cable id and name list
)

for (nm in names(files)) {
  url  <- file.path(base_url, files[[nm]])
  dest <- file.path(dir_raw, paste0(nm, ".json"))
  if (file.exists(dest)) {
    message("Already have ", basename(dest), ", skipping.")
    next
  }
  message("Downloading ", url)
  download.file(url, dest, mode = "wb", quiet = TRUE)
}

# TODO (John): the geo files do not list which landing points each cable uses.
# Download the per-cable detail files (cable/<id>.json) for every id in
# cable_all.json and save them in data/raw/cables/. These list the landing
# points for each cable, which is what we need to build edges.

# TODO (John): write down the download date and source in docs/data_notes.md.

message("Done. Raw files are in: ", dir_raw)
