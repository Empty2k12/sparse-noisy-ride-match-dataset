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

gpx_file <- "29-Sep-2025-2135.gpx"
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

esel_route <- st_read("29-Sep-2025-2135.geojson")

coords_matrix <- st_coordinates(esel_route)

esel_route_df <- as.data.frame(coords_matrix) %>%
  rename(lon = X, lat = Y)

if ("L1" %in% names(df)) {
  esel_route_df <- esel_route_df %>% rename(group = L1)
}

bbox <- make_bbox(range(gpx_route_df$lon), range(gpx_route_df$lat))

base_map <- get_stadiamap(
  bbox = bbox,
  zoom = 14,
  maptype = "alidade_smooth"
)

gpx_route_df <- 
  gpx_route_df %>%
  mutate(lat_lead = lead(lat)) %>%
  mutate(lon_lead = lead(lon)) %>%
  rowwise() %>%
  mutate(dist_to_lead_m = distm(c(lon, lat), c(lon_lead, lat_lead), fun = distHaversine)[1,1]) %>%
  ungroup()

gpx_route_df <- 
  gpx_route_df %>%
  mutate(ts_POSIXct_lead = lead(ts_POSIXct)) %>%
  mutate(ts_diff_s = as.numeric(difftime(ts_POSIXct_lead, ts_POSIXct, units = "secs"))) 

gpx_route_df <- 
  gpx_route_df %>%
  mutate(speed_m_per_sec = dist_to_lead_m / ts_diff_s) %>%
  mutate(speed_km_per_h = speed_m_per_sec * 3.6)

plt_speed_km_per_h <- 
  ggplot(gpx_route_df, aes(x = ts_POSIXct, y = speed_km_per_h)) + 
  geom_line() + 
  labs(x = "Time", y = "Speed [km/h]") + 
  theme_grey(base_size = 14)
plt_speed_km_per_h

dat_df_dist_marks <- 
  gpx_route_df %>% 
  mutate(dist_m_cumsum = cumsum(dist_to_lead_m)) %>%
  mutate(dist_m_cumsum_km_floor = floor(dist_m_cumsum / 1000)) %>%
  group_by(dist_m_cumsum_km_floor) %>%
  filter(row_number() == 1, dist_m_cumsum_km_floor > 0) 

plt_path_fancy <- 
  ggmap(base_map) + 
  geom_path(data = gpx_route_df, aes(lon, lat),
            size = 0.3) +
  geom_path(data = esel_route_df, aes(lon, lat),
            size = 1, col = "darkgreen") +
  geom_point(data = gpx_route_df, aes(lon, lat, col = speed_km_per_h),
             size = 1, alpha = 0.5) +
  geom_label(data = dat_df_dist_marks, aes(lon, lat, label = dist_m_cumsum_km_floor),
             size = 3) +
  scale_color_viridis_c(option = "plasma", 
                        limits = c(0, 35),
                        oob = scales::squish) +
  labs(x = "Longitude", 
       y = "Latitude",
       col = "Speed [km/h]",
       title = "Long Ride Sample") +
  theme(legend.position="bottom")
plt_path_fancy

ggsave("route_map.pdf", 
       plot = plt_path_fancy,
       width = 11.69,  # A4 landscape
       height = 8.27,
       device = "pdf")
