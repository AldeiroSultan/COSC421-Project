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

## Corridor analysis (MF-0010)

- Implemented in R/06_corridors.R by Sultan. The three approximate longitude/latitude boxes are red_sea (41 to 45, 11 to 16), taiwan (119 to 122.5, 19 to 22.5), and tonga (-177 to -173, -23 to -19). These are study scenarios, not exact historical outage footprints.
- The shared raw ZIP was unavailable. With Sultan's approval, only cable_geo.json was downloaded from https://www.submarinecablemap.com/api/v3/cable/cable-geo.json on 2026-11-12. The committed cleaned snapshot from 2026-11-04 was not refreshed. Route geometry and cleaned cable membership therefore have different snapshot dates; route changes between dates are a limitation.
- Raw route SHA-256: 58f732985b065f582326e6d67a858a4c26725e61ef05ac3d78a842792ebaac32
- To reproduce, use this exact route file (share it with teammates outside Git), put it in data/raw/cable_geo.json, then run source("R/06_corridors.R"). A future download from the same URL may differ. Raw files remain ignored by Git; the resulting corridor CSV and map are committed.
- Routes are filtered to cable IDs in cable_landings.csv. Planned cables excluded by the cleaned snapshot stay excluded. Multiple features for a cable produce only one row per corridor. Touching a polygon boundary counts as an intersection.
- Routes are split at the date line before planar longitude/latitude intersections, to avoid treating Pacific routes as crossing the world. The script temporarily disables s2 and restores its previous setting on exit.
- Output: data/processed/corridor_cables.csv with exactly corridor,cable_id, and figures/corridors_map.png with one local panel per corridor.
- Actual run: red_sea 14 cables, taiwan 11 cables, tonga 3 cables (28 corridor/cable pairs). The Red Sea selection contains all three task-board reference cables: Asia Africa Europe-1 (AAE-1), SEACOM/Tata TGN-Eurasia, and Europe India Gateway (EIG). This confirms membership only; historical outage validation remains MF-0013.
- Synthetic checks cover duplicate cable features, excluded planned cables, outside routes, date-line crossings, boundary contact, stable CSV output, and restoration of s2 settings. Synthetic data and figures are not project results and are not committed.
