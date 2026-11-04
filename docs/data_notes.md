# Data notes

Owner: Su (taken over from John). Fill this in as you work on `01_download_data.R` and `02_clean_data.R`.

## Source

- TeleGeography Submarine Cable Map: https://www.submarinecablemap.com
- Download date: 2026-11-04
- Snapshot size: 713 cables (105 marked planned), 1928 landing points, 3219 cable to landing point links
- Base URL: https://www.submarinecablemap.com/api/v3
- Files used and how we got them: all downloaded by `R/01_download_data.R` into `data/raw/` (not committed).
  - `cable/cable-geo.json` saved as `cable_geo.json`: cable routes as lines, used for corridors.
  - `landing-point/landing-point-geo.json` saved as `landing_point_geo.json`: landing point ids, names and coordinates.
  - `cable/all.json` saved as `cable_all.json`: list of every cable id and name.
  - `cable/<id>.json` saved in `cables/`: one file per cable.
- Fields we use from the per cable files: `landing_points` (each with `id`, `name` and `country`), `rfs_year` and `is_planned`.

## Cleaning decisions

- How landing point names are split into place and country: (fill in)
- How territories are treated (Guam, Puerto Rico, Hong Kong, Greenland, and so on): (fill in)
- Cables with a missing or unclear landing point: (fill in)
- Planned or not yet in service cables: keep or drop? (fill in)

## Known problems

- (add anything odd you find)

## Validation sources (week 2)

- Cloudflare Radar outage reports
- IODA (Internet Outage Detection and Analysis)
