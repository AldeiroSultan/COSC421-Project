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
# TODO (Su): for each cable, make every pair of its countries an edge.
# Hint: combn(countries, 2) inside group_by(cable_id) / reframe().
edges <- tibble(from = character(), to = character(), cable_id = character())

# ---- Graph ------------------------------------------------------------------
# Multi-edges are kept on purpose (two cables between the same countries are
# two edges). Use simplify() only when a metric needs a simple graph.
nodes <- tibble(country = sort(unique(c(edges$from, edges$to))))
g <- graph_from_data_frame(edges, directed = FALSE, vertices = nodes)

# ---- Save -------------------------------------------------------------------
# write_csv(edges, file.path(dir_processed, "edges.csv"))
# write_csv(nodes, file.path(dir_processed, "nodes.csv"))
# saveRDS(g, file.path(dir_processed, "network.rds"))

message("Nodes: ", vcount(g), "  Edges: ", ecount(g))
