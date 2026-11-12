# 07_corridor_failure.R
# Owner: Sultan
# Remove whole cables, retaining countries and surviving parallel edges.
source("R/00_setup.R")
source("R/helpers.R")

# Kept as a function so protection experiments can use the same failure rule.
simulate_corridor <- function(graph, cable_ids, baseline_outside = cut_off_countries(graph)) {
  failed_edges <- which(E(graph)$cable_id %in% unique(cable_ids))
  remaining <- delete_edges(graph, failed_edges)
  list(graph = remaining, edges_removed = length(failed_edges),
       cut_off = cut_off_countries(remaining, ignore = baseline_outside))
}

run_corridor_failure <- function() {
  inputs <- c(file.path(dir_processed, "network.rds"),
              file.path(dir_processed, "corridor_cables.csv"),
              file.path(dir_results, "targeted_failure.csv"))
  if (any(!file.exists(inputs))) stop(paste("Missing input:", paste(inputs[!file.exists(inputs)], collapse = ", "),
                                          "Run scripts 03, 05 and 06 first."), call. = FALSE)
  g <- readRDS(inputs[1])
  corridors <- read_csv(inputs[2], show_col_types = FALSE)
  targeted <- read_csv(inputs[3], show_col_types = FALSE) |> arrange(step)
  if (!all(c("corridor", "cable_id") %in% names(corridors)) ||
      !all(c("step", "removed", "nodes_left", "giant", "giant_share", "n_components") %in% names(targeted))) {
    stop("Input columns do not match the task board.", call. = FALSE)
  }
  if (vcount(g) == 0 || is_directed(g) || anyNA(V(g)$name) || anyDuplicated(V(g)$name) ||
      is.null(E(g)$cable_id) || anyNA(E(g)$cable_id)) stop("Expected a nonempty undirected country graph with names and cable IDs.", call. = FALSE)
  scenario_names <- c("red_sea", "taiwan", "tonga")
  if (anyNA(corridors) || any(!nzchar(corridors$cable_id)) ||
      !setequal(unique(corridors$corridor), scenario_names)) stop("Expected cable lists for red_sea, taiwan and tonga.", call. = FALSE)
  active <- read_csv(file.path(dir_processed, "cable_landings.csv"), show_col_types = FALSE)
  if (any(!corridors$cable_id %in% active$cable_id)) stop("Corridor list contains cables outside the cleaned snapshot.", call. = FALSE)
  # Domestic-only cables can appear in a corridor but contribute no graph edges.
  # cables_removed counts selected active cables, including those domestic cables.
  baseline_outside <- cut_off_countries(g)
  n_start <- vcount(g)
  if (nrow(targeted) == 0 || !identical(as.integer(targeted$step), seq.int(0L, nrow(targeted) - 1L))) {
    stop("Targeted steps must start at zero and be consecutive.", call. = FALSE)
  }

  # Replay the recorded removals on the multigraph. Count cumulative lost edges
  # on the same basis as corridor failure, rather than simplified country links.
  work <- g
  targeted_edges <- integer(nrow(targeted))
  for (i in seq_len(nrow(targeted))) {
    if (i > 1) {
      country <- targeted$removed[i]
      if (is.na(country) || !country %in% V(work)$name) stop("Invalid targeted removal sequence.", call. = FALSE)
      work <- delete_vertices(work, country)
    }
    if (anyNA(targeted[i, c("nodes_left", "giant", "giant_share", "n_components")]) ||
        targeted$nodes_left[i] != vcount(work) || targeted$giant[i] != giant_size(work) ||
        targeted$n_components[i] != components(work)$no ||
        abs(targeted$giant_share[i] - giant_size(work) / n_start) > 1e-10) {
      stop("Targeted results do not match network.rds. Rerun script 05.", call. = FALSE)
    }
    targeted_edges[i] <- ecount(g) - ecount(work)
  }

  summaries <- list()
  cutoffs <- list()
  comparisons <- list()
  for (scenario in c(scenario_names, "all_corridors")) {
    ids <- if (scenario == "all_corridors") unique(corridors$cable_id) else
      unique(corridors$cable_id[corridors$corridor == scenario])
    result <- simulate_corridor(g, ids, baseline_outside)
    giant <- giant_size(result$graph)
    summaries[[scenario]] <- tibble(corridor = scenario, cables_removed = length(ids),
      edges_removed = result$edges_removed, giant = giant, giant_share = giant / n_start,
      n_components = components(result$graph)$no)
    cutoffs[[scenario]] <- tibble(corridor = rep(scenario, length(result$cut_off)), country = result$cut_off)
    # Closest cumulative edge count; ties go to the earlier targeted step.
    # Retain the gap because matching is approximate and can select step zero.
    match <- which.min(abs(targeted_edges - result$edges_removed))
    comparisons[[scenario]] <- tibble(corridor = scenario,
      edges_removed = result$edges_removed, targeted_step = targeted$step[match],
      targeted_edges_removed = targeted_edges[match],
      edge_difference = targeted_edges[match] - result$edges_removed,
      corridor_giant_share = giant / n_start, targeted_giant_share = targeted$giant_share[match])
  }
  summary <- bind_rows(summaries)
  cutoff <- bind_rows(cutoffs)
  comparison <- bind_rows(comparisons)
  write_csv(summary, file.path(dir_results, "corridor_failure.csv"))
  write_csv(cutoff, file.path(dir_results, "corridor_cutoff.csv"))
  write_csv(comparison, file.path(dir_results, "targeted_vs_corridor.csv"))
  print(summary, width = Inf)
  print(comparison, width = Inf)
  invisible(list(summary = summary, cutoff = cutoff, comparison = comparison))
}

corridor_failure_results <- run_corridor_failure()
