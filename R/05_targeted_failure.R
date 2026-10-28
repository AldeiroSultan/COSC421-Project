# 05_targeted_failure.R
# Owner: Sultan
# Targeted failure: remove the highest betweenness country, recalculate
# betweenness on what is left, then remove the next one. Repeat.
#
# Input:  data/processed/network.rds
# Output: results/targeted_failure.csv, figures/targeted_failure_giant.png

source("R/00_setup.R")

g <- simplify(readRDS(file.path(dir_processed, "network.rds")))

# ---- Helper: size of the giant component -----------------------------------
giant_size <- function(graph) {
  if (vcount(graph) == 0) return(0)
  max(components(graph)$csize)
}

# ---- Removal loop -----------------------------------------------------------
n_remove <- 20   # how many countries to remove, change if needed

results <- tibble(step = 0, removed = NA_character_,
                  nodes_left = vcount(g), giant = giant_size(g))

g_work <- g
for (i in seq_len(n_remove)) {
  # TODO (Sultan): pick the node with the highest betweenness in g_work,
  # delete it, and add a row to results. Betweenness must be recalculated
  # every step.
}

# ---- Countries cut off ------------------------------------------------------
# TODO (Sultan): after each removal, record which countries are no longer in
# the giant component. Week 2 uses this to find countries cut off in more than
# one scenario.

# ---- Save -------------------------------------------------------------------
# write_csv(results, file.path(dir_results, "targeted_failure.csv"))

# TODO (Sultan): line plot of giant component size vs. number removed,
# save to figures/targeted_failure_giant.png
