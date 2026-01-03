library(leaflet)
library(jsonlite)
library(xml2)
library(htmlwidgets)

GROUNDTRUTH_DIR <- getwd()
DATA_DIR <- file.path(GROUNDTRUTH_DIR, "data")
OUTPUT_DIR <- file.path(GROUNDTRUTH_DIR, "docs")
ICONS_DIR <- file.path(OUTPUT_DIR, "icons")

dir.create(OUTPUT_DIR, recursive = TRUE, showWarnings = FALSE)
dir.create(ICONS_DIR, recursive = TRUE, showWarnings = FALSE)

START_ICON_FILE <- file.path(ICONS_DIR, "start.png")
END_ICON_FILE <- file.path(ICONS_DIR, "end.png")

parse_gpx <- function(gpx_file) {
  doc <- read_xml(gpx_file)
  ns <- xml_ns(doc)

  trkpts <- xml_find_all(doc, ".//d1:trkpt", ns)

  if (length(trkpts) == 0) {
    trkpts <- xml_find_all(doc, ".//trkpt")
  }

  if (length(trkpts) == 0) {
    stop("No track points found in GPX file")
  }

  lat <- as.numeric(xml_attr(trkpts, "lat"))
  lon <- as.numeric(xml_attr(trkpts, "lon"))

  data.frame(lat = lat, lon = lon)
}

parse_esel <- function(esel_file) {
  data <- fromJSON(esel_file)
  data.frame(
    lat = data$lat,
    lon = data$lon,
    accuracy = ifelse(is.null(data$accuracy), NA, data$accuracy)
  )
}

create_ride_map <- function(ride_name) {
  ride_dir <- file.path(DATA_DIR, ride_name)
  gpx_file <- file.path(ride_dir, paste0(ride_name, ".gpx"))
  esel_file <- file.path(ride_dir, paste0(ride_name, "-esel.json"))

  if (!file.exists(gpx_file)) {
    stop(paste("GPX file not found:", gpx_file))
  }
  if (!file.exists(esel_file)) {
    stop(paste("Esel file not found:", esel_file))
  }

  gpx_data <- parse_gpx(gpx_file)

  esel_data <- parse_esel(esel_file)

  center_lat <- mean(c(gpx_data$lat, esel_data$lat))
  center_lon <- mean(c(gpx_data$lon, esel_data$lon))

  startIcon <- makeIcon(
    iconUrl = "icons/start.png",
    iconWidth = 20, iconHeight = 20,
    iconAnchorX = 10, iconAnchorY = 10
  )
  endIcon <- makeIcon(
    iconUrl = "icons/end.png",
    iconWidth = 20, iconHeight = 20,
    iconAnchorX = 10, iconAnchorY = 10
  )

  map <- leaflet() %>%
    addTiles() %>%
    setView(lng = center_lon, lat = center_lat, zoom = 14) %>%

    addPolylines(
      lng = gpx_data$lon,
      lat = gpx_data$lat,
      color = "#2196F3",
      weight = 4,
      opacity = 0.8,
      group = "Ground Truth (GPX)"
    ) %>%

    addPolylines(
      lng = esel_data$lon,
      lat = esel_data$lat,
      color = "#F44336",
      weight = 3,
      opacity = 0.8,
      group = "esel.ac Track"
    ) %>%

    addCircleMarkers(
      lng = gpx_data$lon,
      lat = gpx_data$lat,
      radius = 3,
      color = "#1565C0",
      fillOpacity = 0.6,
      stroke = FALSE,
      group = "Ground Truth Points"
    ) %>%

    addCircleMarkers(
      lng = esel_data$lon,
      lat = esel_data$lat,
      radius = 4,
      color = "#D32F2F",
      fillOpacity = 0.6,
      stroke = FALSE,
      group = "esel.ac Points"
    ) %>%

    addMarkers(
      lng = gpx_data$lon[1],
      lat = gpx_data$lat[1],
      icon = startIcon,
      popup = "Start (Ground Truth)"
    ) %>%

    addMarkers(
      lng = gpx_data$lon[nrow(gpx_data)],
      lat = gpx_data$lat[nrow(gpx_data)],
      icon = endIcon,
      popup = "End (Ground Truth)"
    ) %>%

    addLayersControl(
      overlayGroups = c("Ground Truth (GPX)", "esel.ac Track", 
                        "Ground Truth Points", "esel.ac Points"),
      options = layersControlOptions(collapsed = FALSE)
    ) %>%

    addLegend(
      position = "bottomright",
      colors = c("#2196F3", "#F44336"),
      labels = c("Ground Truth (GPX)", "esel.ac Track"),
      title = ride_name
    )

  output_file <- file.path(OUTPUT_DIR, paste0(ride_name, "_map.html"))

  saveWidget(map, output_file, selfcontained = TRUE)

  doc <- read_html(output_file)
  head_node <- xml_find_first(doc, "//head")

  meta_node <- read_xml('<meta name="robots" content="noindex"/>')
  xml_add_child(head_node, meta_node, .where = 0)

  title_node <- xml_find_first(doc, "//title")
  xml_set_text(title_node, ride_name)

  body_node <- xml_find_first(doc, "//body")
  footer_html <- read_xml('<div style="position: fixed; bottom: 10px; left: 10px; background: rgba(255,255,255,0.9); padding: 8px 12px; border-radius: 4px; font-family: -apple-system, BlinkMacSystemFont, sans-serif; font-size: 12px; box-shadow: 0 1px 3px rgba(0,0,0,0.2); z-index: 1000;">
    <span style="color: #666;">Raw data licensed under </span>
    <a href="https://creativecommons.org/licenses/by-nc-sa/4.0/" target="_blank" style="color: #2196F3; text-decoration: none;">CC-BY-NC-SA 4.0</a>
    <span style="color: #666;"> | </span>
    <a href="https://github.com/Empty2k12/sparse-noisy-ride-match-dataset" target="_blank" style="color: #2196F3; text-decoration: none;">Repository</a>
  </div>')
  xml_add_child(body_node, footer_html)

  write_html(doc, output_file)

  return(map)
}

list_rides <- function() {
  rides <- list.dirs(DATA_DIR, full.names = FALSE, recursive = FALSE)
  pattern <- "^\\d{2}-[A-Za-z]{3}-\\d{4}-\\d{4}$"
  rides <- rides[grepl(pattern, rides)]
  return(rides)
}

generate_index_html <- function(rides) {
  index_file <- file.path(OUTPUT_DIR, "index.html")

  html_content <- paste0('<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <meta name="robots" content="noindex">
    <title>Sparse, Noisy Ride Match Dataset</title>
    <style>
        body {
            font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Oxygen, Ubuntu, sans-serif;
            max-width: 1200px;
            margin: 0 auto;
            padding: 20px;
            background-color: #f5f5f5;
        }
        h1 {
            color: #333;
            border-bottom: 3px solid #2196F3;
            padding-bottom: 10px;
        }
        .ride-grid {
            display: grid;
            grid-template-columns: repeat(auto-fill, minmax(300px, 1fr));
            gap: 20px;
            margin-top: 30px;
        }
        .ride-card {
            background: white;
            border-radius: 8px;
            padding: 20px;
            box-shadow: 0 2px 4px rgba(0,0,0,0.1);
            transition: transform 0.2s, box-shadow 0.2s;
        }
        .ride-card:hover {
            transform: translateY(-2px);
            box-shadow: 0 4px 8px rgba(0,0,0,0.15);
        }
        .ride-card a {
            color: #2196F3;
            text-decoration: none;
            font-weight: 500;
            font-size: 16px;
        }
        .ride-card a:hover {
            text-decoration: underline;
        }
        .ride-date {
            color: #666;
            font-size: 14px;
            margin-top: 5px;
        }
        .stats {
            background: white;
            border-radius: 8px;
            padding: 15px;
            margin-bottom: 20px;
            box-shadow: 0 2px 4px rgba(0,0,0,0.1);
        }
    </style>
</head>
<body>
    <h1>Sparse, Noisy Ride Match Dataset</h1>
    <div class="stats">
        <p><strong>Total Rides:</strong> ', length(rides), '</p>
        <p>Compare ground truth GPS tracks (blue) with esel.ac tracked routes (red)</p>
    </div>
    <div class="ride-grid">
')
  
  rides_sorted <- sort(rides)
  
  for (ride in rides_sorted) {
    map_file <- paste0(ride, "_map.html")
    html_content <- paste0(html_content, '        <div class="ride-card">
            <a href="', map_file, '" target="_blank">', ride, '</a>
        </div>
')
  }
  
  html_content <- paste0(html_content, '    </div>
    <footer style="margin-top: 40px; text-align: center; color: #666; font-size: 14px;">
        <p>Generated on ', format(Sys.time(), "%Y-%m-%d %H:%M:%S"), '</p>
        <p>Raw data licensed under <a href="https://creativecommons.org/licenses/by-nc-sa/4.0/" target="_blank" style="color: #2196F3; text-decoration: none;">CC-BY-NC-SA 4.0</a> | <a href="https://github.com/Empty2k12/sparse-noisy-ride-match-dataset" target="_blank" style="color: #2196F3; text-decoration: none;">Repository</a></p>
    </footer>
</body>
</html>')
  
  writeLines(html_content, index_file)
}

rides <- list_rides()
successful_rides <- c()

for (ride in rides) {
  tryCatch({
    create_ride_map(ride)
    successful_rides <- c(successful_rides, ride)
  }, error = function(e) {
    cat("Error processing", ride, ":", e$message, "\n")
  })
}

generate_index_html(successful_rides)
