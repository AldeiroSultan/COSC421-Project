# 03_build_network.R
# Owner: Su
# Builds the country level network.
#   Node: a country or territory with at least one landing point.
#   Edge: a cable that connects two countries.
#
# A cable that lands in 3 or more countries connects every pair of those countries.
# We keep the cable id on each edge so corridor failure (week 2) can remove
# edges by cable.
#
# Input:  data/processed/cable_landings.csv, data/processed/landing_points.csv
# Output: data/processed/edges.csv, data/processed/nodes.csv, data/processed/network.rds

source("R/00_setup.R")

cable_landings <- read_csv(file.path(dir_processed, "cable_landings.csv"), show_col_types = FALSE)
landing_points <- read_csv(file.path(dir_processed, "landing_points.csv"), show_col_types = FALSE)

# ---- Cable to country table -------------------------------------------------
cable_countries <- cable_landings |>
  left_join(select(landing_points, lp_id, country), by = "lp_id") |>
  distinct(cable_id, country) |>
  filter(!is.na(country))

# ---- Edge list --------------------------------------------------------------
# For each cable, every pair of its countries is an edge. Countries are sorted
# first so "from" always comes before "to" alphabetically. A cable that lands in
# only one country (a domestic cable) gives no edge.
edges <- cable_countries |>
  arrange(cable_id, country) |>
  group_by(cable_id) |>
  filter(n() >= 2) |>
  reframe({
    pairs <- combn(country, 2)
    tibble(from = pairs[1, ], to = pairs[2, ])
  }) |>
  select(from, to, cable_id)

# ---- Nodes ------------------------------------------------------------------
# Every country with a landing point is a node, including countries with no
# international cable. Those become isolated nodes, so they show up as cut off
# from the start.
# n_cables counts every distinct cable that lands in the country, domestic
# cables included.
nodes <- landing_points |>
  count(country, name = "n_landing_points") |>
  left_join(count(cable_countries, country, name = "n_cables"), by = "country") |>
  mutate(n_cables = coalesce(n_cables, 0L)) |>
  arrange(country)

# ---- Graph ------------------------------------------------------------------
# Multi-edges are kept on purpose (two cables between the same countries are
# two edges). Use simplify() only when a metric needs a simple graph.
g <- graph_from_data_frame(edges, directed = FALSE, vertices = nodes)

if (any(is.na(E(g)$cable_id))) stop("Some edges have no cable_id.")

# ---- Save -------------------------------------------------------------------
write_csv(edges, file.path(dir_processed, "edges.csv"))
write_csv(nodes, file.path(dir_processed, "nodes.csv"))
saveRDS(g, file.path(dir_processed, "network.rds"))

comps <- components(g)
message("Nodes: ", vcount(g), "  Edges: ", ecount(g),
        "  (", ecount(simplify(g)), " distinct country pairs)")
message("Components: ", comps$no, "  Giant component: ", max(comps$csize), " countries")
outside <- names(comps$membership)[comps$membership != which.max(comps$csize)]
message("Not in the giant component: ", paste(sort(outside), collapse = ", "))
