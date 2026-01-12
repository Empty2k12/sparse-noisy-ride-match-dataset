# Install packages
install.packages(c("XML", "ggmap", "ggplot2"))
install.packages(c("sf"))

library(XML)
library(ggmap)
library(ggplot2)
library(tidyverse)
library(here)
library(XML)
library(lubridate)
library(ggmap)
library(geosphere)
library(sf)
library(dplyr)
library(tidyr)

gpx_file <- "26-Sep-2025-2028.gpx"
gpx_parsed <- htmlTreeParse(file = gpx_file, 
                            useInternalNodes = TRUE)

coords <- xpathSApply(doc = gpx_parsed, 
                      path = "//trkpt", 
                      fun = xmlAttrs)

ts_chr <- xpathSApply(doc = gpx_parsed, path = "//trkpt/time", xmlValue)

gpx_route_df <- data.frame(
  ts_POSIXct = ymd_hms(ts_chr, tz = "Europe/Berlin"),
  lon = as.numeric(coords["lon", ]),
  lat = as.numeric(coords["lat", ])
)

esel_route <- st_read("26-Sep-2025-2028.geojson")

coords_matrix <- st_coordinates(esel_route)

esel_route_df <- as.data.frame(coords_matrix) %>%
  rename(lon = X, lat = Y)

if ("L1" %in% names(df)) {
  esel_route_df <- esel_route_df %>% rename(group = L1)
}

bbox <- make_bbox(range(gpx_route_df$lon), range(gpx_route_df$lat), f = c(0.05, 0.25))

base_map <- get_stadiamap(
  bbox = bbox,
  zoom = 16,
  maptype = "alidade_smooth"
)

plt_path_fancy <- 
  ggmap(base_map) + 
  geom_path(data = gpx_route_df, aes(lon, lat),
            size = 0.5, col = "orange", alpha = 0.8) +
  geom_point(data = gpx_route_df, aes(lon, lat, fill="lightsalmon"),
             size = 1, col = "orange", pch=21, alpha = 0.8) +
  geom_path(data = esel_route_df, aes(lon, lat),
            size = 0.5, col = "darkgreen", alpha = 0.8) +
  geom_point(data = esel_route_df, aes(lon, lat),
             size = 1, col = "darkgreen") +
  theme(axis.line=element_blank(),axis.text.x=element_blank(),
          axis.text.y=element_blank(),axis.ticks=element_blank(),
          axis.title.x=element_blank(),
          axis.title.y=element_blank(),legend.position="none",
          panel.background=element_blank(),panel.border=element_blank(),panel.grid.major=element_blank(),
          panel.grid.minor=element_blank(),plot.background=element_blank(),
        plot.margin = unit(c(0, 0, 0, 0), "cm"))
plt_path_fancy

lon_range <- bbox["right"] - bbox["left"]
lat_range <- bbox["top"] - bbox["bottom"]

mid_lat <- (bbox["top"] + bbox["bottom"]) / 2

aspect_ratio <- (lon_range * cos(mid_lat * pi / 180)) / lat_range

width <- 8  # inches
height <- width / aspect_ratio

ggsave("26-Sep-2025-2028.pdf", 
       width = width, 
       height = height, 
       units = "in")
