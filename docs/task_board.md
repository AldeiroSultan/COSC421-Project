# Task board

Every task has a fixed ID. To work on one, open Claude Code in this repo and type the ID, for example `MF-0005`. Claude reads the task below, makes the branch, writes the code and opens the pull request (see `CLAUDE.md`).

Owners and weeks are a starting point taken from `docs/team_plan.md`. If you want to swap, change the Owner column on one branch and agree on it in the group chat first. Progress is tracked by the pull requests on GitHub, not in this file.

MF-0001 (project skeleton) and MF-0002 (git conventions, CLAUDE.md, this board) are already used. For a fix or change that is not listed here, use the next free TI number (TI-0001, TI-0002, ...).

## Overview

| ID | Branch | Task | Owner | Week | Needs |
|---|---|---|---|---|---|
| MF-0003 | `MF-0003-download-cable-details` | Download per-cable detail files | John | 1 | none |
| MF-0004 | `MF-0004-clean-landing-data` | Clean landing points and cable landings | John | 1 | MF-0003 |
| MF-0005 | `MF-0005-build-country-network` | Build the country network | Su | 1 | MF-0004 |
| MF-0006 | `MF-0006-baseline-metrics` | Baseline metrics and random network comparison | Su | 1 | MF-0005 |
| MF-0007 | `MF-0007-targeted-failure` | Targeted failure simulation | Sultan | 1 | MF-0005 |
| MF-0008 | `MF-0008-run-all-script` | Script that runs the whole pipeline | Sultan | 1 | none |
| MF-0009 | `MF-0009-milestone-report` | Milestone report (due Nov 6) | All | 2 | MF-0006, MF-0007 |
| MF-0010 | `MF-0010-corridor-polygons` | Corridor polygons and cables in each corridor | John | 2 | MF-0004 |
| MF-0011 | `MF-0011-corridor-failure` | Corridor failure simulation | Sultan | 2 | MF-0007, MF-0010 |
| MF-0012 | `MF-0012-articulation-points` | Articulation points and countries cut off in several scenarios | Su | 2 | MF-0011 |
| MF-0013 | `MF-0013-red-sea-validation` | Check the Red Sea scenario against the 2024 cuts | John | 2 | MF-0011 |
| MF-0014 | `MF-0014-protection` | Test new cable connections | Su | 2 | MF-0012 |
| MF-0015 | `MF-0015-map-figures` | Map figures for the report | John | 2 | MF-0010, MF-0012 |
| MF-0016 | `MF-0016-comparison-figures` | Comparison figures for the report | Sultan | 2 | MF-0011, MF-0014 |
| MF-0017 | `MF-0017-final-report` | Final report and video script | All | 2 | everything above |

Week 1 is Oct 27 to Nov 2. Week 2 is Nov 3 to Nov 9.

Tasks in the same week with no arrow between them can run at the same time. If a task needs one that is not merged into `staging` yet, you can still write the code against a few rows of made up input. Do not commit the made up data.

## Shared file formats

Scripts written by different people have to fit together, so every script writes these exact columns. If you need to change one, open a TI task and tell the people whose scripts read it.

| File | Written by | Columns |
|---|---|---|
| `data/processed/landing_points.csv` | MF-0004 | `lp_id, lp_name, place, country, lon, lat` |
| `data/processed/cable_landings.csv` | MF-0004 | `cable_id, cable_name, lp_id, rfs_year, is_planned` |
| `data/processed/edges.csv` | MF-0005 | `from, to, cable_id` |
| `data/processed/nodes.csv` | MF-0005 | `country, n_landing_points, n_cables` |
| `data/processed/network.rds` | MF-0005 | igraph multigraph, vertex attribute `name`, edge attribute `cable_id` |
| `data/processed/corridor_cables.csv` | MF-0010 | `corridor, cable_id` |
| `results/targeted_failure.csv` | MF-0007 | `step, removed, nodes_left, giant, giant_share, n_components` |
| `results/targeted_cutoff.csv` | MF-0007 | `step, country` |
| `results/corridor_failure.csv` | MF-0011 | `corridor, cables_removed, edges_removed, giant, giant_share, n_components` |
| `results/corridor_cutoff.csv` | MF-0011 | `corridor, country` |
| `results/scenario_cutoff.csv` | MF-0012 | `country, n_scenarios, scenarios` |
| `results/vulnerable_countries.csv` | MF-0012 | `country, n_cables, is_articulation_point, n_scenarios` |
| `results/protection.csv` | MF-0014 | `from, to, corridor, giant_before, giant_after, countries_saved` |

Definitions used everywhere:

- `giant_share` is the giant component size divided by the number of countries in the original network, so targeted and corridor results can be compared.
- A country is cut off when it is still in the graph but not in the giant component. Countries removed in targeted failure are listed in `removed`, not as cut off.

---

## MF-0003 | Download per-cable detail files

- Owner: John. Week 1. Needs: none.
- File: `R/01_download_data.R`, `docs/data_notes.md`

What to do:

1. Check that the three URLs already in the script work. If the API path has changed, find the current one (or a GitHub mirror of the TeleGeography data) and update `base_url`.
2. Read `cable_all.json` and download `cable/<id>.json` for every cable into `data/raw/cables/<id>.json`. Skip files that already exist. Wait a little between requests (`Sys.sleep(0.2)`) and wrap each download in `tryCatch` so one bad id does not stop the loop. Print how many succeeded and failed at the end.
3. Fill in the Source section of `docs/data_notes.md`: download date, base URL, and which fields in the per-cable file we use (landing points, country, `rfs_year`, `is_planned`).

Done when: running the script on an empty `data/raw/` gives the three geo files plus one json per cable, and running it again downloads nothing.

## MF-0004 | Clean landing points and cable landings

- Owner: John. Week 1. Needs: MF-0003.
- File: `R/02_clean_data.R`, `docs/data_notes.md`

What to do:

1. Landing points: from `landing_point_geo.json` get `lp_id`, `lp_name`, `lon`, `lat`. Split the name into `place` and `country` using the last comma (so "City, State, United States" gives country "United States"). If the per-cable files have a `country` field for the landing point, prefer that and use the name split only as a fallback.
2. Cable landings: read every file in `data/raw/cables/` and build one row per (`cable_id`, `lp_id`), with `cable_name`, `rfs_year` and `is_planned`.
3. Territories: keep territories (Guam, Puerto Rico, Hong Kong, Greenland, ...) as their own nodes, as the proposal says. Write the rule down in `docs/data_notes.md`.
4. Planned cables: drop cables that are planned or have an `rfs_year` after the current year, because they cannot fail yet. Write this in `docs/data_notes.md`.
5. Checks that stop the script with an error: no missing `country`, no `lp_id` in `cable_landings` that is missing from `landing_points`.
6. Save the two csv files with the columns in the shared formats table. Print row counts and the number of countries.

Done when: both csv files exist with the right columns, the checks pass, and the cleaning decisions in `docs/data_notes.md` are filled in.

## MF-0005 | Build the country network

- Owner: Su. Week 1. Needs: MF-0004.
- File: `R/03_build_network.R`

What to do:

1. Fill in the edge list TODO: for each cable, make every pair of its countries an edge (`combn(countries, 2)` inside `group_by(cable_id)` and `reframe()`). A cable that lands in only one country gives no edge.
2. Keep multi-edges and `cable_id`. Do not simplify the saved graph.
3. Build `nodes` with `country`, `n_landing_points` (from `landing_points.csv`) and `n_cables` (number of distinct cables that land there).
4. Include countries with landing points but no international cable as isolated nodes, so they show up as cut off from the start.
5. Uncomment and keep the save lines. Print node count, edge count, number of components and the size of the giant component.

Done when: `edges.csv`, `nodes.csv` and `network.rds` are saved with the shared columns, and `E(g)$cable_id` has no missing values.

## MF-0006 | Baseline metrics and random network comparison

- Owner: Su. Week 1. Needs: MF-0005. Answers research question 1.
- File: `R/04_baseline_metrics.R`

What to do:

1. Keep the node and network metrics already there. Add `n_cables` from `nodes.csv` to `node_metrics`.
2. Random comparison: make 100 Erdos-Renyi graphs with `sample_gnm()` using the same node and edge counts as `g_simple`. For each, record average degree, average path length (on the giant component) and global clustering (`transitivity(type = "global")`). Save the mean and standard deviation next to the real values in `results/random_comparison.csv` with columns `metric, real, random_mean, random_sd`.
3. Save `results/baseline_node_metrics.csv` and `results/baseline_summary.csv`.
4. Plot the degree distribution (histogram or log-log), save to `figures/degree_distribution.png`.
5. Print the top 10 countries by degree and by betweenness.

Done when: the three csv files and the plot exist and the top 10 tables print.

## MF-0007 | Targeted failure simulation

- Owner: Sultan. Week 1. Needs: MF-0005. Half of research question 2.
- File: `R/05_targeted_failure.R`

What to do:

1. Fill in the loop: each step, recalculate betweenness on `g_work`, remove the country with the highest value (break ties by degree, then by name so results do not change between runs), and add a row with the shared columns.
2. After each removal, record every country that is still in the graph but not in the giant component in `results/targeted_cutoff.csv` (`step, country`).
3. Save `results/targeted_failure.csv`.
4. Line plot of `giant_share` against step, save to `figures/targeted_failure_giant.png`.
5. Wrap the removal and the cut off check in two small functions (`giant_size()` is already there, add `cut_off_countries(graph, giant_only)`) so MF-0011 can reuse them. Put the reused helpers in `R/helpers.R` and source it after `00_setup.R`.

Done when: both csv files and the plot exist, and running the script twice gives the same results.

## MF-0008 | Script that runs the whole pipeline

- Owner: Sultan. Week 1. Needs: none.
- File: `R/run_all.R`, `README.md` (How to run section only)

What to do:

1. Write `R/run_all.R` that sources every numbered script in `R/` in order (find them with `list.files("R", pattern = "^[0-9]{2}_.*\\.R$")`), prints the name and time taken for each, and stops at the first error.
2. Each script runs in its own environment (`sys.source(f, envir = new.env())`) so scripts cannot depend on leftover variables.
3. Update the How to run section of `README.md` to mention `run_all.R`.

Done when: `source("R/run_all.R")` runs every script that exists and reports where it stopped if one fails.

## MF-0009 | Milestone report (due Nov 6)

- Owner: All. Week 2. Needs: MF-0006, MF-0007.
- File: `reports/milestone.Rmd`

What to do:

1. Make an R Markdown file that renders to PDF or HTML. It reads results from `results/` and figures from `figures/`. It does not rerun the analysis.
2. Sections: problem and objectives (from the proposal), data and cleaning decisions (from `docs/data_notes.md`), network definition, baseline results (research question 1 tables and degree plot), first targeted failure results, what is left for week 2.
3. Leave clearly marked `TODO:` lines where the team needs to write their own discussion. Claude should write the structure, tables and captions, not the team's conclusions.

Done when: the file renders with the current results and every section has a heading and the right table or figure.

## MF-0010 | Corridor polygons and cables in each corridor

- Owner: John. Week 2. Needs: MF-0004.
- File: `R/06_corridors.R`

What to do:

1. Define the three corridors as polygons in one small table, so they are easy to change. Starting boxes (lon/lat, check them on a map):
   - `red_sea`: southern Red Sea and Bab el-Mandeb, about lon 41 to 45, lat 11 to 16
   - `taiwan`: Luzon Strait, south of Taiwan, about lon 119 to 122.5, lat 19 to 22.5
   - `tonga`: around Tongatapu and the Hunga Tonga volcano, about lon -177 to -173, lat -23 to -19
2. Read `data/raw/cable_geo.json` with `sf`, use CRS 4326, and find every cable whose route intersects each polygon (`st_intersects`). Turn off s2 (`sf_use_s2(FALSE)`) if lines that cross the 180 degree line cause errors, and say so in a comment.
3. Keep only cables that are in `cable_landings.csv` (so planned cables stay out).
4. Save `data/processed/corridor_cables.csv` and a quick map of the polygons and the cables they hit to `figures/corridors_map.png`.
5. Print the number of cables per corridor and their names. For the Red Sea, check that cables reported cut in 2024 (for example AAE-1, Seacom, EIG) appear. Note the result in `docs/data_notes.md`.

Done when: `corridor_cables.csv` has rows for all three corridors and the map is saved.

## MF-0011 | Corridor failure simulation

- Owner: Sultan. Week 2. Needs: MF-0007, MF-0010. Second half of research question 2.
- File: `R/07_corridor_failure.R`

What to do:

1. For each corridor, delete every edge whose `cable_id` is in that corridor (use the multigraph from `network.rds`, not the simplified one, so a country pair stays linked if another cable still joins them).
2. Record the shared columns in `results/corridor_failure.csv` and the cut off countries in `results/corridor_cutoff.csv`. Reuse the helpers from `R/helpers.R`.
3. Also run all three corridors at once as a fourth row, `all_corridors`.
4. Comparison: for each corridor, find the targeted failure step with the closest number of removed edges and put both `giant_share` values side by side in `results/targeted_vs_corridor.csv`.

Done when: the three csv files exist and the script prints a short table of giant share per scenario.

## MF-0012 | Articulation points and countries cut off in several scenarios

- Owner: Su. Week 2. Needs: MF-0011. Research question 3.
- File: `R/08_articulation_points.R`

What to do:

1. Find articulation points on the simplified baseline network (`articulation_points()`), and bridges (edges whose removal splits the graph, use `bridges()` on the simplified graph).
2. Count `n_cables` per country from the multigraph and flag countries with 1 or 2 cables.
3. Combine `targeted_cutoff.csv` (count a country if it was cut off at any step up to 10, and say this limit in a comment) with `corridor_cutoff.csv` (each corridor is one scenario, skip `all_corridors`). Save `results/scenario_cutoff.csv` with `n_scenarios` and a comma separated `scenarios` column.
4. Save `results/vulnerable_countries.csv` with the shared columns, sorted by `n_scenarios` then `n_cables`.

Done when: both csv files exist and the script prints countries cut off in 2 or more scenarios.

## MF-0013 | Check the Red Sea scenario against the 2024 cuts

- Owner: John. Week 2. Needs: MF-0011. Research question 4.
- File: `R/09_validation_red_sea.R`, `data/manual/red_sea_2024_reported.csv`

What to do:

1. Make `data/manual/red_sea_2024_reported.csv` with columns `country, source, url, note`. This list is filled in by hand from Cloudflare Radar and IODA reports on the February to March 2024 cuts. Claude creates the file with headers and an example row marked `EXAMPLE`. John fills in the real rows. `data/manual/` is committed, unlike `data/raw/`.
2. The script compares the reported countries with the `red_sea` rows of `corridor_cutoff.csv`. Our model only shows countries that lose all access, while reports often show slowdowns, so also compare with countries that lost at least one cable in the Red Sea corridor (from `corridor_cables.csv` and `cable_landings.csv`).
3. Save `results/red_sea_validation.csv` with `country, reported, model_cut_off, model_lost_a_cable` and print matches, misses and false alarms for both comparisons.

Done when: the script runs on the hand made list and the csv is saved. The written explanation goes in the report, not here.

## MF-0014 | Test new cable connections

- Owner: Su. Week 2. Needs: MF-0012. Research question 5.
- File: `R/10_protection.R`

What to do:

1. Candidates: for each country in `vulnerable_countries.csv` with `n_scenarios >= 1`, propose a new cable to each of its 3 nearest countries (by distance between landing points from `landing_points.csv`) that it is not already linked to, plus a link to the nearest country with the top 10 betweenness. Keep the rule simple and explain it in a comment.
2. For each candidate, add the edge (with `cable_id = "new_<from>_<to>"`), rerun every corridor scenario using the code from MF-0011, and record how many countries are no longer cut off.
3. Save `results/protection.csv` with the shared columns and print the top 10 candidates by total `countries_saved` across corridors.

Done when: the csv exists and the top 10 prints.

## MF-0015 | Map figures for the report

- Owner: John. Week 2. Needs: MF-0010, MF-0012.
- File: `R/11_map_figures.R`

What to do:

1. World map of countries coloured by `n_scenarios` from `scenario_cutoff.csv`, with the corridor polygons drawn on top. Use `rnaturalearth` if it is easy to add to `00_setup.R`, otherwise plot landing points from `landing_points.csv`.
2. One map per corridor showing the cut cables in red and the cut off countries.
3. Save to `figures/map_*.png` at 300 dpi with a consistent theme.

Done when: the maps are saved and readable in a printed report.

## MF-0016 | Comparison figures for the report

- Owner: Sultan. Week 2. Needs: MF-0011, MF-0014.
- File: `R/12_comparison_figures.R`

What to do:

1. Giant share under targeted failure (line) with each corridor scenario marked as a point at its matching step (from `targeted_vs_corridor.csv`).
2. Bar chart of giant share and number of cut off countries per scenario.
3. Bar chart of the top 10 protection candidates.
4. Save to `figures/compare_*.png` at 300 dpi, same theme as MF-0015 (put the shared theme in `R/helpers.R`).

Done when: all three figures are saved.

## MF-0017 | Final report and video script

- Owner: All. Week 2. Needs: everything above.
- File: `reports/final_report.Rmd`, `reports/video_script.md`

What to do:

1. Start from `reports/milestone.Rmd`. Add sections for corridor failure, cut off countries across scenarios, validation, protection, limitations and conclusion. One subsection per research question.
2. Pull every number from `results/`, never type numbers by hand.
3. `reports/video_script.md`: an outline with one part per research question, who presents each part, and which figure to show.
4. Leave `TODO:` lines for the team's own discussion and conclusions.

Done when: the report renders from a clean run of `R/run_all.R`.
