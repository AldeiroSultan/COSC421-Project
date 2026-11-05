# 04_baseline_metrics.R
# Owner: Su
# Answers research question 1: highest degree and betweenness, and how the
# average degree compares to a random network.
#
# Input:  data/processed/network.rds, data/processed/nodes.csv
# Output: results/baseline_node_metrics.csv, results/baseline_summary.csv,
#         results/random_comparison.csv, figures/degree_distribution.png

source("R/00_setup.R")

g     <- readRDS(file.path(dir_processed, "network.rds"))
nodes <- read_csv(file.path(dir_processed, "nodes.csv"), show_col_types = FALSE)

# Giant component of a graph, used for average path length because distances
# between separate components are infinite.
giant_component <- function(graph) {
  comps <- components(graph)
  induced_subgraph(graph, which(comps$membership == which.max(comps$csize)))
}

# ---- Node metrics -----------------------------------------------------------
# Degree and betweenness use the simplified graph: two countries joined by
# five cables count as one neighbour. n_cables keeps the cable count.
g_simple <- simplify(g)

node_metrics <- tibble(
  country     = V(g_simple)$name,
  degree      = degree(g_simple),
  betweenness = betweenness(g_simple, normalized = TRUE)
) |>
  left_join(select(nodes, country, n_cables), by = "country") |>
  arrange(desc(betweenness))

# ---- Network level metrics --------------------------------------------------
comps <- components(g_simple)
g_giant <- giant_component(g_simple)

baseline_summary <- tibble(
  nodes            = vcount(g_simple),
  edges            = ecount(g_simple),
  cable_edges      = ecount(g),
  avg_degree       = mean(degree(g_simple)),
  density          = edge_density(g_simple),
  n_components     = comps$no,
  giant_size       = max(comps$csize),
  giant_share      = max(comps$csize) / vcount(g_simple),
  avg_path_length  = mean_distance(g_giant),
  clustering       = transitivity(g_simple, type = "global")
)

# ---- Random network comparison ---------------------------------------------
# 100 Erdos-Renyi graphs with the same number of nodes and edges as g_simple.
# Average degree is the same in every random graph by construction (2m / n),
# so the interesting differences are path length, clustering and the shape of
# the degree distribution. The seed is set in 00_setup.R.
n_random <- 100

random_metrics <- bind_rows(lapply(seq_len(n_random), function(i) {
  gr <- sample_gnm(vcount(g_simple), ecount(g_simple))
  tibble(
    avg_degree      = mean(degree(gr)),
    avg_path_length = mean_distance(giant_component(gr)),
    clustering      = transitivity(gr, type = "global"),
    max_degree      = max(degree(gr))
  )
}))

real_values <- c(
  avg_degree      = baseline_summary$avg_degree,
  avg_path_length = baseline_summary$avg_path_length,
  clustering      = baseline_summary$clustering,
  max_degree      = max(node_metrics$degree)
)

random_comparison <- tibble(
  metric      = names(real_values),
  real        = unname(real_values),
  random_mean = sapply(names(real_values), function(m) mean(random_metrics[[m]])),
  random_sd   = sapply(names(real_values), function(m) sd(random_metrics[[m]]))
)

# ---- Save -------------------------------------------------------------------
write_csv(node_metrics, file.path(dir_results, "baseline_node_metrics.csv"))
write_csv(baseline_summary, file.path(dir_results, "baseline_summary.csv"))
write_csv(random_comparison, file.path(dir_results, "random_comparison.csv"))

# ---- Degree distribution plot -----------------------------------------------
# Histogram of the real degrees, with the average degree of a random graph of
# the same size as a dashed line for reference.
p <- ggplot(node_metrics, aes(x = degree)) +
  geom_histogram(binwidth = 2, boundary = 0, fill = "steelblue", colour = "white") +
  geom_vline(xintercept = baseline_summary$avg_degree, linetype = "dashed") +
  labs(
    title = "Degree distribution of the country network",
    subtitle = paste0("Dashed line: average degree (", round(baseline_summary$avg_degree, 1),
                      "), the same as a random network of this size"),
    x = "Degree (number of countries directly linked by cable)",
    y = "Number of countries"
  ) +
  theme_minimal()

ggsave(file.path(dir_figures, "degree_distribution.png"), p, width = 7, height = 4.5, dpi = 300)

# ---- Print ------------------------------------------------------------------
message("Top 10 countries by degree:")
print(node_metrics |> arrange(desc(degree), country) |> head(10), n = 10)

message("Top 10 countries by betweenness:")
print(node_metrics |> arrange(desc(betweenness), country) |> head(10), n = 10)

message("Real network vs ", n_random, " random networks:")
print(random_comparison)
