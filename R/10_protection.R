# 10_protection.R
# Owner: Su
# Research question 5: which new cable connection keeps the most vulnerable
# countries connected?
#
# Candidate rule (kept simple on purpose):
#   For every country in vulnerable_countries.csv with n_scenarios >= 1,
#   propose a new cable to
#     1. each of its 3 nearest countries it is not already linked to, and
#     2. the nearest of the top 10 betweenness countries it is not already linked to.
#   Distance between two countries is the shortest great circle distance
#   between any of their landing points.
#
# Each candidate is added as one new edge (cable_id "new_<from>_<to>") and every
# corridor scenario is rerun with the same failure rule as 07_corridor_failure.R.
# The new cable is assumed to avoid the corridors, so it never fails.
#
# Input:  data/processed/network.rds, data/processed/landing_points.csv,
#         data/processed/corridor_cables.csv, results/vulnerable_countries.csv,
#         results/baseline_node_metrics.csv
# Output: results/protection.csv

source("R/00_setup.R")
source("R/helpers.R")

g              <- readRDS(file.path(dir_processed, "network.rds"))
landing_points <- read_csv(file.path(dir_processed, "landing_points.csv"), show_col_types = FALSE)
corridors      <- read_csv(file.path(dir_processed, "corridor_cables.csv"), show_col_types = FALSE)
vulnerable     <- read_csv(file.path(dir_results, "vulnerable_countries.csv"), show_col_types = FALSE)
node_metrics   <- read_csv(file.path(dir_results, "baseline_node_metrics.csv"), show_col_types = FALSE)

g_simple <- simplify(g)

# all_corridors is left out, like in 08, so the three corridors are the scenarios.
scenario_names <- c("red_sea", "taiwan", "tonga")
corridor_ids <- lapply(setNames(scenario_names, scenario_names),
                       function(s) unique(corridors$cable_id[corridors$corridor == s]))

# Countries outside the giant component before anything fails (for example
# Azerbaijan and Kazakhstan) are not counted as cut off, same as in 07.
baseline_outside <- cut_off_countries(g)

# Same failure rule as simulate_corridor() in 07: delete every edge whose cable
# is in the corridor, keep all countries and any parallel cables.
run_corridor <- function(graph, cable_ids) {
  remaining <- delete_edges(graph, which(E(graph)$cable_id %in% cable_ids))
  list(giant = giant_size(remaining),
       cut_off = cut_off_countries(remaining, ignore = baseline_outside))
}

# ---- Distances between countries -------------------------------------------
haversine_km <- function(lon1, lat1, lon2, lat2) {
  to_rad <- pi / 180
  dlat <- (lat2 - lat1) * to_rad
  dlon <- (lon2 - lon1) * to_rad
  a <- sin(dlat / 2)^2 + cos(lat1 * to_rad) * cos(lat2 * to_rad) * sin(dlon / 2)^2
  6371 * 2 * asin(pmin(1, sqrt(a)))
}

# Shortest distance from any landing point of `ctry` to each other country.
distances_from <- function(ctry) {
  own <- landing_points[landing_points$country == ctry, ]
  d <- vapply(seq_len(nrow(own)), function(i) {
    haversine_km(own$lon[i], own$lat[i], landing_points$lon, landing_points$lat)
  }, numeric(nrow(landing_points)))
  d <- matrix(d, nrow = nrow(landing_points))
  tibble(country = landing_points$country, km = apply(d, 1, min)) |>
    filter(country != ctry) |>
    group_by(country) |>
    summarise(km = min(km), .groups = "drop") |>
    arrange(km, country)
}

# ---- Candidate cables -------------------------------------------------------
top_hubs <- node_metrics |>
  arrange(desc(betweenness), country) |>
  slice_head(n = 10) |>
  pull(country)

targets <- vulnerable |>
  filter(n_scenarios >= 1) |>
  pull(country)

candidates <- bind_rows(lapply(targets, function(ctry) {
  linked <- as_ids(neighbors(g_simple, ctry))
  free <- distances_from(ctry) |> filter(!country %in% linked)
  bind_rows(
    free |> slice_head(n = 3) |> mutate(rule = "nearest"),
    free |> filter(country %in% top_hubs) |> slice_head(n = 1) |> mutate(rule = "nearest_hub")
  ) |>
    transmute(from = ctry, to = country, km = round(km), rule)
})) |>
  # The same pair can come up twice (from both ends, or as nearest and hub).
  mutate(pair = paste(pmin(from, to), pmax(from, to), sep = " | ")) |>
  distinct(pair, .keep_all = TRUE) |>
  select(-pair)

message("Vulnerable countries: ", length(targets), "  Candidate cables: ", nrow(candidates))

# ---- Rerun every corridor with each candidate -------------------------------
before <- lapply(corridor_ids, function(ids) run_corridor(g, ids))

results <- bind_rows(lapply(seq_len(nrow(candidates)), function(i) {
  cand <- candidates[i, ]
  g_new <- add_edges(g, c(cand$from, cand$to),
                     attr = list(cable_id = paste0("new_", cand$from, "_", cand$to)))
  bind_rows(lapply(scenario_names, function(s) {
    after <- run_corridor(g_new, corridor_ids[[s]])
    saved <- setdiff(before[[s]]$cut_off, after$cut_off)
    tibble(from = cand$from, to = cand$to, corridor = s,
           giant_before = before[[s]]$giant, giant_after = after$giant,
           countries_saved = length(saved),
           saved_names = paste(saved, collapse = ", "))
  }))
}))

# ---- Save -------------------------------------------------------------------
protection <- results |> select(from, to, corridor, giant_before, giant_after, countries_saved)
write_csv(protection, file.path(dir_results, "protection.csv"))

# ---- Print ------------------------------------------------------------------
# Ties are broken by the shorter cable, since a shorter cable is cheaper to build.
top10 <- results |>
  group_by(from, to) |>
  summarise(total_saved = sum(countries_saved),
            saved = paste(saved_names[saved_names != ""], collapse = ", "),
            .groups = "drop") |>
  left_join(select(candidates, from, to, km, rule), by = c("from", "to")) |>
  arrange(desc(total_saved), km, from, to) |>
  slice_head(n = 10)

message("Cut off in each corridor before any new cable:")
for (s in scenario_names) {
  message("  ", s, ": ", if (length(before[[s]]$cut_off) == 0) "none" else
    paste(before[[s]]$cut_off, collapse = ", "))
}
message("Top 10 candidate cables by countries saved across corridors:")
print(top10, n = 10, width = Inf)
