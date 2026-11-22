# 12_comparison_figures.R
# Owner: Su
# Comparison figures for the report, in the same style as the maps (report_theme()
# in helpers.R, 300 dpi).
#   figures/compare_giant_share.png   targeted failure curve with each corridor marked
#   figures/compare_scenarios.png     giant share and countries cut off per scenario
#   figures/compare_protection.png    top 10 new cable candidates
#
# Input:  results/targeted_failure.csv, results/targeted_cutoff.csv,
#         results/corridor_failure.csv, results/corridor_cutoff.csv,
#         results/targeted_vs_corridor.csv, results/protection.csv,
#         data/processed/landing_points.csv

source("R/00_setup.R")
source("R/helpers.R")

targeted     <- read_csv(file.path(dir_results, "targeted_failure.csv"), show_col_types = FALSE)
targeted_cut <- read_csv(file.path(dir_results, "targeted_cutoff.csv"), show_col_types = FALSE)
corridor     <- read_csv(file.path(dir_results, "corridor_failure.csv"), show_col_types = FALSE)
corridor_cut <- read_csv(file.path(dir_results, "corridor_cutoff.csv"), show_col_types = FALSE)
matched      <- read_csv(file.path(dir_results, "targeted_vs_corridor.csv"), show_col_types = FALSE)
protection   <- read_csv(file.path(dir_results, "protection.csv"), show_col_types = FALSE)
landing_points <- read_csv(file.path(dir_processed, "landing_points.csv"), show_col_types = FALSE)

scenario_labels <- c(red_sea = "Red Sea", taiwan = "Taiwan", tonga = "Tonga",
                     all_corridors = "All three corridors", targeted = "Targeted (10 removals)")
corridor_colours <- c("Red Sea" = "#BE4438", "Taiwan" = "#33869B", "Tonga" = "#E8B44D",
                      "All three corridors" = "#663A83")
source_note <- "Sources: TeleGeography Submarine Cable Map (snapshot 4 Nov 2026); project failure simulations."

# Targeted failure up to step 10 counts as one scenario, the same rule as 08.
targeted_limit <- 10

# ---- 1. Giant share: targeted curve with corridor points --------------------
# Each corridor is placed at the targeted step that removed the closest number
# of edges (from 07). If the corridor removed more edges than the last
# targeted step, that point sits at the end of the curve and is flagged.
max_targeted_edges <- max(matched$targeted_edges_removed)
points <- matched |>
  mutate(name = unname(scenario_labels[corridor]),
         beyond = edges_removed > max_targeted_edges,
         label = paste0(name, ": ", scales::comma(edges_removed), " edges",
                        if_else(beyond, ", more than any targeted step", "")))
legend_labels <- setNames(points$label, points$name)[names(corridor_colours)]
points$name <- factor(points$name, levels = names(corridor_colours))

p1 <- ggplot() +
  geom_line(data = targeted, aes(step, giant_share), colour = "#182B3A", linewidth = 0.8) +
  geom_point(data = targeted, aes(step, giant_share), colour = "#182B3A", size = 1.4) +
  geom_point(data = points, aes(targeted_step, corridor_giant_share, colour = name),
             size = 4, shape = 18) +
  scale_colour_manual(values = corridor_colours, labels = legend_labels, name = NULL) +
  guides(colour = guide_legend(ncol = 2)) +
  scale_y_continuous(labels = scales::percent, limits = c(0, 1)) +
  labs(title = "Targeted failure breaks the network far more than corridor failure",
       subtitle = "Line: share of countries in the giant component as the highest betweenness country is removed, one per step.\nDiamonds: each corridor scenario, placed at the targeted step with the closest number of removed edges.",
       x = "Countries removed (targeted failure step)", y = "Countries in the giant component",
       caption = source_note) +
  report_theme()

ggsave(file.path(dir_figures, "compare_giant_share.png"), p1, width = 10, height = 6, dpi = 300, bg = "white")

# ---- 2. Giant share and countries cut off per scenario ----------------------
targeted_row <- targeted |> filter(step == targeted_limit)
n_targeted_cut <- n_distinct(targeted_cut$country[targeted_cut$step >= 1 & targeted_cut$step <= targeted_limit])

scenarios <- bind_rows(
  corridor |> transmute(scenario = corridor, giant_share),
  tibble(scenario = "targeted", giant_share = targeted_row$giant_share)
) |>
  left_join(count(corridor_cut, corridor, name = "cut_off"), by = c("scenario" = "corridor")) |>
  mutate(cut_off = if_else(scenario == "targeted", n_targeted_cut, coalesce(cut_off, 0L)),
         scenario = factor(scenario_labels[scenario], levels = rev(scenario_labels)))

scenarios_long <- bind_rows(
  scenarios |> transmute(scenario, measure = "Share of countries in the giant component",
                         value = giant_share, label = scales::percent(giant_share, accuracy = 0.1)),
  scenarios |> transmute(scenario, measure = "Countries cut off",
                         value = cut_off, label = as.character(cut_off))
) |>
  mutate(measure = factor(measure, levels = c("Share of countries in the giant component", "Countries cut off")))

p2 <- ggplot(scenarios_long, aes(value, scenario)) +
  geom_col(fill = "#33869B", width = 0.65) +
  geom_text(aes(label = label), hjust = -0.15, size = 3.3, colour = "#182B3A") +
  facet_wrap(~measure, scales = "free_x") +
  # The share panel stops its axis at 100%, the count panel uses normal breaks.
  scale_x_continuous(expand = expansion(mult = c(0, 0.25)),
                     breaks = function(lims) if (lims[2] <= 1.5) seq(0, 1, 0.25) else scales::extended_breaks()(lims),
                     labels = function(x) if (all(x <= 1, na.rm = TRUE)) scales::percent(x) else x) +
  labs(title = "Each scenario: how much of the network stays connected",
       subtitle = paste0("Targeted counts every country cut off in steps 1 to ", targeted_limit,
                         ". Corridors remove every cable through the box.\n",
                         "Countries outside the giant component before any failure are not counted."),
       x = NULL, y = NULL, caption = source_note) +
  report_theme() +
  theme(panel.grid.major.y = element_blank(), strip.text = element_text(face = "bold"))

ggsave(file.path(dir_figures, "compare_scenarios.png"), p2, width = 11, height = 5.5, dpi = 300, bg = "white")

# ---- 3. Top 10 protection candidates ----------------------------------------
# Ranked by total countries saved across corridors. Ties are broken by the
# shorter cable (cheaper to build), the same order 10_protection.R prints.
# Distance is the shortest great circle distance between the two countries'
# landing points, the same rule as 10_protection.R.
haversine_km <- function(lon1, lat1, lon2, lat2) {
  to_rad <- pi / 180
  a <- sin((lat2 - lat1) * to_rad / 2)^2 +
    cos(lat1 * to_rad) * cos(lat2 * to_rad) * sin((lon2 - lon1) * to_rad / 2)^2
  6371 * 2 * asin(pmin(1, sqrt(a)))
}
country_km <- function(a, b) {
  pa <- landing_points[landing_points$country == a, ]
  pb <- landing_points[landing_points$country == b, ]
  min(outer(seq_len(nrow(pa)), seq_len(nrow(pb)),
            function(i, j) haversine_km(pa$lon[i], pa$lat[i], pb$lon[j], pb$lat[j])))
}

top10 <- protection |>
  group_by(from, to) |>
  summarise(total_saved = sum(countries_saved), .groups = "drop") |>
  filter(total_saved > 0) |>
  mutate(km = mapply(country_km, from, to)) |>
  arrange(desc(total_saved), km, from, to) |>
  slice_head(n = 10) |>
  mutate(cable = paste0(from, " to ", to, " (", scales::comma(round(km)), " km)"))

top10_long <- protection |>
  semi_join(top10, by = c("from", "to")) |>
  filter(countries_saved > 0) |>
  left_join(select(top10, from, to, cable), by = c("from", "to")) |>
  mutate(cable = factor(cable, levels = rev(top10$cable)),
         corridor = factor(scenario_labels[corridor], levels = names(corridor_colours)))

p3 <- ggplot(top10_long, aes(countries_saved, cable, fill = corridor)) +
  geom_col(width = 0.65) +
  scale_fill_manual(values = corridor_colours, name = "Scenario where countries are saved", drop = TRUE) +
  scale_x_continuous(breaks = 0:max(top10$total_saved), expand = expansion(mult = c(0, 0.05))) +
  labs(title = "Which single new cable keeps the most countries connected",
       subtitle = "Countries no longer cut off when the cable is added, summed over the Red Sea, Taiwan and Tonga scenarios.\nCandidates link each vulnerable country to its 3 nearest unlinked countries and its nearest top 10 hub. Ties: shorter cable first.",
       x = "Countries saved", y = NULL, caption = source_note) +
  report_theme() +
  theme(panel.grid.major.y = element_blank())

ggsave(file.path(dir_figures, "compare_protection.png"), p3, width = 10, height = 6, dpi = 300, bg = "white")

message("Saved compare_giant_share.png, compare_scenarios.png and compare_protection.png at 300 dpi.")
