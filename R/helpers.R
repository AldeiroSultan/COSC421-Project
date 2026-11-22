# helpers.R
# Owner: Sultan
# Small functions shared by the failure scripts (05 and, later, 07).
# Scripts source this right after 00_setup.R:
#   source("R/00_setup.R")
#   source("R/helpers.R")

# Size of the giant component (0 for an empty graph).
giant_size <- function(graph) {
  if (vcount(graph) == 0) return(0)
  max(components(graph)$csize)
}

# Countries that are still in the graph but not in the giant component.
# `ignore` is for countries that were already outside the giant component
# before anything failed (pass the baseline list), so they are not counted as
# cut off by the failure.
cut_off_countries <- function(graph, ignore = character()) {
  if (vcount(graph) == 0) return(character())
  comps  <- components(graph)
  outside <- names(comps$membership)[comps$membership != which.max(comps$csize)]
  sort(setdiff(outside, ignore))
}

# The country with the highest betweenness. Ties are broken by degree, then by
# name, so the result is the same every run.
top_betweenness_country <- function(graph) {
  scores <- tibble(
    country     = V(graph)$name,
    betweenness = round(betweenness(graph), 8),  # rounding hides float noise
    degree      = degree(graph)
  ) |>
    arrange(desc(betweenness), desc(degree), country)
  scores$country[1]
}
# Shared report styling. Use the platform's standard sans-serif font.
report_theme <- function(base_size = 11) {
  theme_minimal(base_size = base_size, base_family = "sans") +
    theme(plot.title = element_text(size = 18, face = "bold", colour = "#182B3A"),
          plot.subtitle = element_text(size = 11, colour = "#425563", margin = margin(b = 12)),
          plot.caption = element_text(size = 9, colour = "#52616B", hjust = 0, margin = margin(t = 12)),
          plot.title.position = "plot", plot.caption.position = "plot",
          panel.grid.major = element_line(colour = "#E5E9EC", linewidth = 0.25),
          panel.grid.minor = element_blank(),
          legend.position = "bottom", legend.title = element_text(face = "bold"),
          plot.background = element_rect(fill = "white", colour = NA),
          plot.margin = margin(16, 18, 12, 18))
}

# Shared corridor boundaries for selection (06) and report maps (11).
study_corridors <- function() {
  bounds <- tibble::tribble(
    ~corridor, ~xmin, ~xmax, ~ymin, ~ymax,
    "red_sea", 41, 45, 11, 16,
    "taiwan", 119, 122.5, 19, 22.5,
    "tonga", -177, -173, -23, -19
  )
  polygons <- lapply(seq_len(nrow(bounds)), function(i) {
    b <- bounds[i, ]
    sf::st_polygon(list(matrix(c(b$xmin, b$ymin, b$xmax, b$ymin,
      b$xmax, b$ymax, b$xmin, b$ymax, b$xmin, b$ymin), ncol = 2, byrow = TRUE)))
  })
  sf::st_sf(bounds, geometry = sf::st_sfc(polygons, crs = 4326))
}

