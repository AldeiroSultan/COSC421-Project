# 08_articulation_points.R
# Owner: Sultan
# Baseline structural weaknesses and repeated failure exposure.
source("R/00_setup.R")

analyse_vulnerability <- function(g, targeted, corridor) {
  if (is_directed(g) || vcount(g) == 0 || is.null(V(g)$name) ||
      anyNA(V(g)$name) || anyDuplicated(V(g)$name) ||
      is.null(E(g)$cable_id) || anyNA(E(g)$cable_id)) {
    stop("Expected an undirected multigraph with country names and cable IDs.", call. = FALSE)
  }
  if (!all(c("step", "country") %in% names(targeted)) ||
      !all(c("corridor", "country") %in% names(corridor))) {
    stop("Cutoff input columns do not match the task board.", call. = FALSE)
  }
  if (anyNA(targeted) || anyNA(corridor) ||
      any(!c(targeted$country, corridor$country) %in% V(g)$name) ||
      !is.numeric(targeted$step) || any(targeted$step < 0 | targeted$step != floor(targeted$step)) ||
      any(!corridor$corridor %in% c("red_sea", "taiwan", "tonga", "all_corridors"))) {
    stop("Cutoff inputs contain invalid steps, scenarios or countries.", call. = FALSE)
  }
  simple <- simplify(g)
  articulation <- sort(as_ids(articulation_points(simple)))
  bridge_ends <- ends(simple, bridges(simple), names = TRUE)
  # These are bridges between country pairs in the simplified graph, not
  # necessarily individual cable failures: parallel cables may join the pair.
  bridge_table <- tibble(from = bridge_ends[, 1], to = bridge_ends[, 2]) |>
    arrange(from, to)

  # Count each incident cable once, even when it joins several other countries.
  # This is international cable redundancy in the multigraph; unlike nodes.csv,
  # domestic-only cables are absent. Keep isolated countries with zero cables.
  cable_counts <- vapply(V(g)$name, function(country) {
    length(unique(E(g)$cable_id[as.integer(incident(g, country, mode = "all"))]))
  }, integer(1))

  # All targeted removals through step 10 are ONE scenario, not ten scenarios.
  # Step zero is baseline, and all_corridors is excluded to avoid counting the
  # combined experiment as a fourth independent corridor.
  exposure <- bind_rows(
    targeted |> filter(step >= 1, step <= 10) |> transmute(country, scenario = "targeted"),
    corridor |> filter(corridor != "all_corridors") |> transmute(country, scenario = corridor)
  ) |> distinct(country, scenario) |> arrange(country, scenario)
  totals <- exposure |> group_by(country) |>
    summarise(n_scenarios = n(), scenarios = paste(scenario, collapse = ","), .groups = "drop")
  # Include all countries so maps can distinguish zero exposure from missing data.
  scenario_cutoff <- tibble(country = sort(V(g)$name)) |>
    left_join(totals, by = "country") |>
    mutate(n_scenarios = coalesce(n_scenarios, 0L), scenarios = coalesce(scenarios, "")) |>
    arrange(desc(n_scenarios), country)
  vulnerable <- tibble(country = V(g)$name, n_cables = unname(cable_counts),
                       is_articulation_point = V(g)$name %in% articulation) |>
    left_join(select(scenario_cutoff, country, n_scenarios), by = "country") |>
    arrange(desc(n_scenarios), n_cables, country)
  # Print the low-redundancy flag without changing the shared CSV columns.
  low_redundancy <- vulnerable |> filter(n_cables %in% c(1L, 2L)) |>
    mutate(has_one_or_two_cables = TRUE)
  list(scenario_cutoff = scenario_cutoff, vulnerable = vulnerable,
       articulation = articulation, bridges = bridge_table, low_redundancy = low_redundancy)
}

run_vulnerability <- function() {
  inputs <- c(file.path(dir_processed, "network.rds"),
              file.path(dir_results, "targeted_cutoff.csv"),
              file.path(dir_results, "corridor_cutoff.csv"))
  if (any(!file.exists(inputs))) stop(paste("Missing input:", paste(inputs[!file.exists(inputs)], collapse = ", "),
                                          "Run scripts 03, 05 and 07 first."), call. = FALSE)
  result <- analyse_vulnerability(readRDS(inputs[1]),
    read_csv(inputs[2], col_types = cols(step = col_integer(), country = col_character())),
    read_csv(inputs[3], col_types = cols(corridor = col_character(), country = col_character())))
  write_csv(result$scenario_cutoff, file.path(dir_results, "scenario_cutoff.csv"))
  write_csv(result$vulnerable, file.path(dir_results, "vulnerable_countries.csv"))
  message("Baseline articulation countries: ", paste(result$articulation, collapse = ", "))
  message("Bridges in the simplified country graph (not individual cable bridges):")
  print(result$bridges, n = Inf)
  message("Countries with one or two international cables:")
  print(result$low_redundancy, n = Inf)
  message("Countries cut off in two or more scenarios:")
  print(filter(result$scenario_cutoff, n_scenarios >= 2), n = Inf, width = Inf)
  invisible(result)
}

vulnerability_results <- run_vulnerability()
