# 04_baseline_metrics.R
# Owner: Su
# Answers research question 1: highest degree and betweenness, and how the
# average degree compares to a random network.
#
# Input:  data/processed/network.rds
# Output: results/baseline_node_metrics.csv, results/baseline_summary.csv,
#         figures/degree_distribution.png

source("R/00_setup.R")

g <- readRDS(file.path(dir_processed, "network.rds"))

# ---- Node metrics -----------------------------------------------------------
g_simple <- simplify(g)

node_metrics <- tibble(
  country     = V(g_simple)$name,
  degree      = degree(g_simple),
  betweenness = betweenness(g_simple, normalized = TRUE)
) |>
  arrange(desc(betweenness))

# ---- Network level metrics --------------------------------------------------
comps <- components(g_simple)

baseline_summary <- tibble(
  nodes            = vcount(g_simple),
  edges            = ecount(g_simple),
  avg_degree       = mean(degree(g_simple)),
  density          = edge_density(g_simple),
  n_components     = comps$no,
  giant_size       = max(comps$csize),
  giant_share      = max(comps$csize) / vcount(g_simple)
)

# ---- Random network comparison ---------------------------------------------
# TODO (Su): build an Erdos-Renyi graph with the same number of nodes and edges
# (sample_gnm), repeat 100 times, and compare average degree, average path
# length, and clustering with the real network.

# ---- Save -------------------------------------------------------------------
# write_csv(node_metrics, file.path(dir_results, "baseline_node_metrics.csv"))
# write_csv(baseline_summary, file.path(dir_results, "baseline_summary.csv"))

# TODO (Su): degree distribution plot with ggplot2, save to figures/degree_distribution.png
