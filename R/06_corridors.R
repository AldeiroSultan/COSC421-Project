# 06_corridors.R
# Owner: Sultan
# Identify in-service cables crossing the three study corridors.
source("R/00_setup.R")
source("R/helpers.R")

build_corridors <- function() {
  route_file <- file.path(dir_raw, "cable_geo.json")
  landings_file <- file.path(dir_processed, "cable_landings.csv")
  if (!file.exists(route_file)) {
    stop("Missing data/raw/cable_geo.json. Restore the route snapshot described in docs/data_notes.md into data/raw.", call. = FALSE)
  }
  if (!file.exists(landings_file)) stop("Missing cable_landings.csv from MF-0004.", call. = FALSE)

  # Approximate study areas from the task board, not historical outage footprints.
  corridors <- study_corridors()
  bounds <- st_drop_geometry(corridors)
  active <- read_csv(landings_file, show_col_types = FALSE) |>
    distinct(cable_id, cable_name)
  routes <- st_read(route_file, quiet = TRUE)
  if (!"id" %in% names(routes)) stop("Cable GeoJSON must contain an id field.", call. = FALSE)
  if (is.na(st_crs(routes))) stop("Cable routes have no coordinate reference system.", call. = FALSE)
  routes <- st_transform(routes, 4326) |>
    mutate(cable_id = as.character(id)) |>
    semi_join(active, by = "cable_id")
  if (nrow(routes) == 0) stop("No route IDs match the cleaned cable snapshot.", call. = FALSE)
  if (any(st_is_empty(routes))) stop("Active cable routes contain empty geometry.", call. = FALSE)

  # Split at the date line before planar lon/lat intersection. Otherwise a
  # Pacific segment can be interpreted as crossing most of the world.
  routes <- st_wrap_dateline(routes, options = c("WRAPDATELINE=YES", "DATELINEOFFSET=180"), quiet = TRUE)
  old_s2 <- sf_use_s2()
  on.exit(sf_use_s2(old_s2), add = TRUE)
  sf_use_s2(FALSE)
  hits <- st_intersects(corridors, routes)
  corridor_cables <- bind_rows(lapply(seq_along(hits), function(i) {
    tibble(corridor = rep(bounds$corridor[i], length(hits[[i]])),
           cable_id = routes$cable_id[hits[[i]]])
  })) |> distinct() |> arrange(corridor, cable_id)
  empty <- setdiff(bounds$corridor, corridor_cables$corridor)
  if (length(empty)) stop(paste("No active cables found for:", paste(empty, collapse = ", ")), call. = FALSE)

  # Three local panels make the small boxes and intersecting routes readable.
  panels <- lapply(seq_len(nrow(bounds)), function(i) {
    b <- bounds[i, ]
    ggplot() +
      geom_sf(data = routes[hits[[i]], ], colour = "#2378A0", linewidth = 0.4) +
      geom_sf(data = corridors[i, ], fill = "#EFAD32", alpha = 0.18,
              colour = "#B25C00", linewidth = 0.8) +
      coord_sf(xlim = c(b$xmin - 2, b$xmax + 2),
               ylim = c(b$ymin - 2, b$ymax + 2), expand = FALSE) +
      labs(title = paste(b$corridor, "|", n_distinct(routes$cable_id[hits[[i]]]), "cables"),
           subtitle = "Box: corridor | Blue: cable routes",
           x = "Longitude", y = "Latitude") + theme_minimal(base_size = 10)
  })
  map_file <- file.path(dir_figures, "corridors_map.png")
  png(map_file, width = 12, height = 5, units = "in", res = 300)
  tryCatch({
    grid::grid.newpage()
    grid::pushViewport(grid::viewport(layout = grid::grid.layout(1, 3)))
    for (i in seq_along(panels)) print(panels[[i]], newpage = FALSE,
      vp = grid::viewport(layout.pos.row = 1, layout.pos.col = i))
  }, finally = dev.off())
  write_csv(corridor_cables, file.path(dir_processed, "corridor_cables.csv"))
  print(count(corridor_cables, corridor, name = "n_cables"))
  print(left_join(corridor_cables, active, by = "cable_id"), n = Inf, width = Inf)

  # These are the task board's reference cables; this is a membership check,
  # not validation of which countries suffered a historical outage (MF-0013).
  reference <- tribble(
    ~reference, ~cable_id,
    "AAE-1", "asia-africa-europe-1-aae-1",
    "SEACOM/Tata TGN-Eurasia", "seacomtata-tgn-eurasia",
    "EIG", "europe-india-gateway-eig"
  ) |> mutate(in_cleaned_snapshot = cable_id %in% active$cable_id,
              intersects_red_sea = cable_id %in% corridor_cables$cable_id[corridor_cables$corridor == "red_sea"])
  print(reference)
  invisible(list(corridors = corridors, cables = corridor_cables, reference = reference))
}

corridor_results <- build_corridors()



