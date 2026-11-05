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

Done in `R/02_clean_data.R`.

- Country of each landing point: taken from the `country` field in the per cable files. Every landing point had one, and none had two. Splitting the name at the last comma is only a fallback, because it gets names like "Muanda, Congo, Dem. Rep." wrong (11 landing points in this snapshot). `place` is the name with ", <country>" removed from the end.
- Territories (Guam, Puerto Rico, Hong Kong, Greenland, and so on): kept as their own nodes, using the label TeleGeography gives them, as the proposal says.
- Cables with a missing or unclear landing point: every landing point id in the cable files exists in `landing_point_geo.json`, so none were dropped. 44 landing points are marked `is_tbd` (location not final); they are kept if their cable is in service.
- Planned or not yet in service cables: dropped. A cable is dropped if `is_planned` is true or `rfs_year` is after the current year, because it cannot fail yet. This drops 105 of 713 cables.
- Landing points that are only used by planned cables are dropped too, so they do not become nodes. In this snapshot that removes one country: Tuvalu, whose only cables are planned.

## Shared snapshot

Everyone uses the same data. Su downloaded it once on 2026-11-04 and committed the two cleaned files in `data/processed/`. Start from `03_build_network.R` and do not rerun `01` or `02` unless the group agrees to refresh the data. The raw folder is shared as a zip in the group chat, which week 2 needs for `cable_geo.json`. Unzip it into `data/raw/`.

Expected output of `02_clean_data.R` on this snapshot: 608 cables kept, 2761 rows in `cable_landings.csv`, 1792 rows in `landing_points.csv`, 185 countries and territories.

## Known problems

- (add anything odd you find)

## Validation sources (week 2)

- Cloudflare Radar outage reports
- IODA (Internet Outage Detection and Analysis)
