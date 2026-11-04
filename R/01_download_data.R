# 01_download_data.R
# Owner: Su (taken over from John)
# Downloads the TeleGeography Submarine Cable Map data into data/raw/.
# Raw files are not committed to Git. Anyone can rebuild them by running this script.
#
# Files:
#   data/raw/cable_geo.json            cable routes (lines), used for corridors in week 2
#   data/raw/landing_point_geo.json    landing points (points) with coordinates
#   data/raw/cable_all.json            list of every cable id and name
#   data/raw/cables/<id>.json          one file per cable, lists its landing points
#                                      with country, rfs_year and is_planned
#
# Running it again skips files that already exist, so it only downloads what is missing.

source("R/00_setup.R")

base_url <- "https://www.submarinecablemap.com/api/v3"

files <- c(
  cable_geo         = "cable/cable-geo.json",                  # cable routes (lines)
  landing_point_geo = "landing-point/landing-point-geo.json",  # landing points (points)
  cable_all         = "cable/all.json"                         # cable id and name list
)

# ---- Main files -------------------------------------------------------------
for (nm in names(files)) {
  url  <- paste0(base_url, "/", files[[nm]])
  dest <- file.path(dir_raw, paste0(nm, ".json"))
  if (file.exists(dest)) {
    message("Already have ", basename(dest), ", skipping.")
    next
  }
  message("Downloading ", url)
  # Stop here if a main file fails, because nothing after this works without them.
  tryCatch(
    download.file(url, dest, mode = "wb", quiet = TRUE),
    error = function(e) {
      if (file.exists(dest)) file.remove(dest)
      stop("Could not download ", url, ". The API path may have changed. Error: ",
           conditionMessage(e))
    }
  )
}

# ---- Per cable files --------------------------------------------------------
# The geo files do not say which landing points each cable uses, so we need
# cable/<id>.json for every cable in cable_all.json.
dir_cables <- file.path(dir_raw, "cables")
dir.create(dir_cables, recursive = TRUE, showWarnings = FALSE)

cable_all <- fromJSON(file.path(dir_raw, "cable_all.json"))
cable_ids <- unique(cable_all$id)
message("Cables listed in cable_all.json: ", length(cable_ids))

n_ok <- 0; n_skip <- 0; failed <- character()

for (id in cable_ids) {
  dest <- file.path(dir_cables, paste0(id, ".json"))
  if (file.exists(dest)) {
    n_skip <- n_skip + 1
    next
  }
  url <- paste0(base_url, "/cable/", id, ".json")
  ok <- tryCatch({
    download.file(url, dest, mode = "wb", quiet = TRUE)
    TRUE
  }, error = function(e) {
    if (file.exists(dest)) file.remove(dest)   # do not keep half written files
    FALSE
  })
  if (ok) n_ok <- n_ok + 1 else failed <- c(failed, id)
  Sys.sleep(0.2)   # be polite to the server
}

message("Per cable files: ", n_ok, " downloaded, ", n_skip, " already there, ",
        length(failed), " failed.")
if (length(failed) > 0) {
  message("Failed ids (run the script again to retry): ", paste(failed, collapse = ", "))
}

message("Done. Raw files are in: ", dir_raw)
