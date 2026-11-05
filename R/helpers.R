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
