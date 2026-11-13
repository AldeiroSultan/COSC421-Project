# 11_map_figures.R
# Owner: Sultan
# Landing-point maps retain small islands and territories without a country-name
# join to a polygon dataset. Each point inherits its country's analysis result.
source("R/00_setup.R")
source("R/helpers.R")

run_map_figures <- function() {
  inputs <- c(file.path(dir_raw, "cable_geo.json"),
    file.path(dir_processed, "landing_points.csv"),
    file.path(dir_processed, "corridor_cables.csv"),
    file.path(dir_results, "scenario_cutoff.csv"),
    file.path(dir_results, "corridor_cutoff.csv"),
    file.path(dir_results, "corridor_failure.csv"))
  if (any(!file.exists(inputs))) stop(paste("Missing map input:", paste(inputs[!file.exists(inputs)], collapse = ", "),
    "Restore the documented raw route snapshot and run scripts 06, 07 and 08."), call. = FALSE)
  landings <- read_csv(inputs[2], show_col_types = FALSE)
  cables <- read_csv(inputs[3], show_col_types = FALSE)
  scenarios <- read_csv(inputs[4], show_col_types = FALSE)
  cutoff <- read_csv(inputs[5], col_types = cols(corridor = col_character(), country = col_character()))
  failure <- read_csv(inputs[6], show_col_types = FALSE)
  if (anyDuplicated(scenarios$country) || anyNA(scenarios$n_scenarios) ||
      any(!landings$country %in% scenarios$country) ||
      any(!cutoff$country %in% landings$country) ||
      any(!is.finite(landings$lon) | !is.finite(landings$lat)) ||
      any(abs(landings$lon) > 180 | abs(landings$lat) > 90)) {
    stop("Map inputs contain missing country results or invalid coordinates.", call. = FALSE)
  }
  points <- landings |> left_join(scenarios, by = "country") |>
    arrange(n_scenarios) |> st_as_sf(coords = c("lon", "lat"), crs = 4326)
  corridors <- study_corridors()
  titles <- c(red_sea = "Red Sea", taiwan = "Taiwan / Luzon Strait", tonga = "Tonga")
  world <- st_as_sf(maps::map("world", plot = FALSE, fill = TRUE))
  world <- st_wrap_dateline(world, options = c("WRAPDATELINE=YES", "DATELINEOFFSET=180"), quiet = TRUE)
  routes <- st_read(inputs[1], quiet = TRUE)
  if (!"id" %in% names(routes) || is.na(st_crs(routes))) stop("Route GeoJSON needs id and CRS.", call. = FALSE)
  routes <- st_transform(routes, 4326) |> mutate(cable_id = as.character(id))
  if (any(!cables$cable_id %in% routes$cable_id)) stop("Some selected cables have no route geometry.", call. = FALSE)
  routes <- routes |> semi_join(cables, by = "cable_id")
  routes <- st_wrap_dateline(routes, options = c("WRAPDATELINE=YES", "DATELINEOFFSET=180"), quiet = TRUE)
  backdrop <- function() ggplot() +
    geom_sf(data = world, fill = "#F0F2F3", colour = "#CDD3D8", linewidth = 0.18) +
    coord_sf(xlim = c(-180, 180), ylim = c(-60, 85), expand = FALSE, default_crs = st_crs(4326)) +
    labs(x = NULL, y = NULL) + report_theme()
  source_note <- "Sources: TeleGeography; project failure simulations. Cleaned data: 04 Nov 2026; routes downloaded: 12 Nov 2026."
  exposure_levels <- as.character(0:max(2, scenarios$n_scenarios))
  colours <- c("0" = "#B6C2C9", "1" = "#33869B", "2" = "#183E69", "3" = "#663A83", "4" = "#A23648")
  if (any(!as.character(scenarios$n_scenarios) %in% names(colours))) stop("Unexpected scenario count.", call. = FALSE)
  points$exposure <- factor(points$n_scenarios, levels = exposure_levels)
  overview <- backdrop() +
    geom_sf(data = points, aes(colour = exposure), size = 0.9, alpha = 0.85) +
    geom_sf(data = corridors, fill = NA, colour = "#B94B32", linewidth = 0.7) +
    annotate("text", x = c(43, 121, -175), y = c(4, 10, -31),
             label = c("Red Sea", "Taiwan", "Tonga"), family = "sans", size = 3.2, colour = "#8E3824") +
    scale_colour_manual(values = colours, drop = FALSE, name = "Cut-off scenarios") +
    labs(title = "Where submarine cable failures leave countries cut off",
         subtitle = "Landing points coloured by country exposure. Outlined boxes mark the three study corridors.",
         caption = paste("Targeted steps 1-10 count as one scenario; combined corridor failure is excluded. Multiple points may belong to one country.", source_note, sep = "\n"))
  ggsave(file.path(dir_figures, "map_scenario_exposure.png"), overview, width = 12, height = 6.8, dpi = 300, bg = "white")

  plots <- list(exposure = overview)
  for (scenario in corridors$corridor) {
    ids <- unique(cables$cable_id[cables$corridor == scenario])
    selected <- routes |> filter(cable_id %in% ids)
    affected <- sort(unique(cutoff$country[cutoff$corridor == scenario]))
    affected_points <- points |> filter(country %in% affected)
    row <- failure |> filter(corridor == scenario)
    if (nrow(row) != 1 || row$cables_removed != length(ids)) stop("Corridor summary does not match selected cables.", call. = FALSE)
    names_note <- if (length(affected)) paste("Newly cut-off countries:", paste(affected, collapse = ", ")) else
      "No newly cut-off countries in this scenario. Cable loss can still reduce redundancy; this model does not measure traffic or slowdowns."
    p <- backdrop() +
      geom_sf(data = selected, aes(colour = "Removed cable routes"), linewidth = 0.35, alpha = 0.8) +
      geom_sf(data = corridors[corridors$corridor == scenario, ], fill = NA,
              colour = "#152D3D", linewidth = 0.8, linetype = "dashed") +
      geom_sf(data = affected_points, aes(fill = "Newly cut-off countries"), shape = 21,
              colour = "#152D3D", size = 2.3, stroke = 0.35) +
      scale_colour_manual(values = c("Removed cable routes" = "#BE4438"), name = NULL) +
      scale_fill_manual(values = c("Newly cut-off countries" = "#E8B44D"), name = NULL) +
      labs(title = paste(titles[[scenario]], "| Cable failure footprint"),
        subtitle = sprintf("%s selected cables | %s newly cut-off countries | %s countries remain in the giant component",
                           length(ids), length(affected), row$giant),
        caption = paste(stringr::str_wrap(names_note, width = 135),
          "Dashed box: failure corridor. Red lines show whole selected cables; markers show affected countries' landing points.",
          "Baseline-disconnected countries are excluded. Country connectivity is modelled, not measured internet service.", source_note, sep = "\n"))
    ggsave(file.path(dir_figures, paste0("map_", scenario, ".png")), p,
           width = 12, height = 7.4, dpi = 300, bg = "white")
    plots[[scenario]] <- p
  }
  message("Saved four map_*.png figures at 300 dpi.")
  invisible(list(plots = plots, points = points, corridors = corridors))
}

map_results <- run_map_figures()
