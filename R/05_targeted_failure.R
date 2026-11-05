# 05_targeted_failure.R
# Owner: Sultan
# Targeted failure: remove the highest betweenness country, recalculate
# betweenness on what is left, then remove the next one. Repeat.
#
# Input:  data/processed/network.rds
# Output: results/targeted_failure.csv, results/targeted_cutoff.csv,
#         figures/targeted_failure_giant.png

source("R/00_setup.R")
source("R/helpers.R")

g <- simplify(readRDS(file.path(dir_processed, "network.rds")))

# Countries already outside the giant component before anything is removed.
# They are not counted as cut off by the failure.
baseline_outside <- cut_off_countries(g)
n_start <- vcount(g)

# ---- Removal loop -----------------------------------------------------------
n_remove <- 20   # how many countries to remove, change if needed

summarise_step <- function(graph, step, removed) {
  tibble(step = step, removed = removed,
         nodes_left = vcount(graph),
         giant = giant_size(graph),
         giant_share = giant_size(graph) / n_start,
         n_components = components(graph)$no)
}

results <- summarise_step(g, 0, NA_character_)
cutoff  <- tibble(step = integer(), country = character())

g_work <- g
for (i in seq_len(n_remove)) {
  # Betweenness is recalculated on what is left at every step.
  target <- top_betweenness_country(g_work)
  g_work <- delete_vertices(g_work, target)
  results <- bind_rows(results, summarise_step(g_work, i, target))

  # ---- Countries cut off ----------------------------------------------------
  # Still in the graph, but no longer in the giant component.
  lost <- cut_off_countries(g_work, ignore = baseline_outside)
  if (length(lost) > 0) {
    cutoff <- bind_rows(cutoff, tibble(step = i, country = lost))
  }
}

# ---- Save -------------------------------------------------------------------
write_csv(results, file.path(dir_results, "targeted_failure.csv"))
write_csv(cutoff, file.path(dir_results, "targeted_cutoff.csv"))

p <- ggplot(results, aes(x = step, y = giant_share)) +
  geom_line() +
  geom_point() +
  scale_y_continuous(limits = c(0, 1)) +
  labs(x = "Countries removed (highest betweenness first)",
       y = "Giant component, share of original countries",
       title = "Targeted failure") +
  theme_minimal()
ggsave(file.path(dir_figures, "targeted_failure_giant.png"), p,
       width = 7, height = 4.5, dpi = 300)

message("Removed in order: ", paste(na.omit(results$removed), collapse = ", "))
message("Giant share after ", n_remove, " removals: ",
        round(tail(results$giant_share, 1), 3))
message("Countries cut off at some step: ", n_distinct(cutoff$country))
