if (!require("pacman")) install.packages("pacman") # Download (if needed) and load package management tools 

pacman::p_load(sf, tidyverse, data.table, hrbrthemes, lwgeom, rnaturalearth, maps, mapdata, spData, tigris, tidycensus, leaflet, tmap, tmaptools) # Download (if needed) and load some packages for spatial analysis
# sf objects are designed to integrate with a tidyverse workflow. 
# tidycensus and tigris are packages for US census data 
# tidyverse contains the workhorse packages for data analysis
# The maps and mapdata packages have detailed county- and province-level data for several individual nations.

wi_shape <- st_read("~/Documents/test-play/Just-Playing/WI_CensusTL_Counties_2019/WI_CensusTL_Counties_2019.shp", quiet = TRUE) # Read Shapefile in R using sf::st_readrm

# Counties of Wisconsin Plot
wi_shape_plot <- ggplot(data = wi_shape) +
  geom_sf(color = "ghostwhite", fill = "red3") + # add geom_df layer
  labs(
    title = "Counties of Wisconsin", 
    caption = "Data: UW-Madison Robinson Map Library"
  )

# Output the plot with higher resolution
# ggsave("wi_shape_plot.png", plot = wi_shape_plot, dpi = 300) 

# Wrangle the data to plot area information (in 1000 Square Kilometer)
wi_area <- wi_shape %>%
    mutate(AREA = ALAND/1000000000) # Create a new variable

# Plot the area of Counties in Wisconsin
wi_area_plot <- ggplot(wi_area) +
     geom_sf(aes(fill = AREA), alpha=0.8, col="white") +
     scale_fill_viridis_c(name = "Area") + # For beauty and color-blind people.
     labs(  
       title = "Counties of Wisconsin", 
       caption = "Data: UW-Madison Robinson Map Library"
     )

wi_area_plot
###############################################################################
# add settings to optimize use with the sf package
options(tigris_class = "sf") 
options(tigris_use_cache = TRUE)

# Set up API access
# census_api_key("YOUR KEY HERE", install = TRUE) 

wi_income <- get_acs(
  geography = "county",
  variables = "B19013_001", # Searching for variable IDs is usually painful. 
                            #load_variable() is an option, also use https://censusreporter.org/
  state = "WI",
  year = 2019,
  geometry = TRUE
)

wi_income 

wi_income_plot <- wi_income %>%
     ggplot() + 
     geom_sf(aes(fill = estimate, color = estimate)) + 
     coord_sf(crs = 26910) + 
     scale_fill_viridis_c(name = "inflation-adjusted ($)", labels = scales::comma) + 
     scale_color_viridis_c(name = "inflation-adjusted ($)", labels = scales::comma) +
     labs(
         title = "Median Households Income in 2019 Across Wisconsion", 
         caption = "Data: US Census Bureau"
     ) 

wi_income_plot

# Now, compare median incomes for downtown Madison and 
# Milwaukee (a great city with an amazing basketball team)

mad_mil = 
  tigris::core_based_statistical_areas(cb = TRUE) %>%
  filter(grepl("Madison, WI|Milwaukee", NAME)) %>%
  select(metro_name = NAME)

mad_mil

# Now, we get tract level data 
#The "Census Tract" is an area roughly equivalent to a neighborhood established by 
# the Bureau of Census for analyzing populations.
wi_tract_income <- get_acs(
  geography = "tract", # county before
  variables = "B19013_001", # Searching for variable IDs is usually painful. 
  #load_variable() is an option, also use https://censusreporter.org/
  state = "WI",
  year = 2019,
  geometry = TRUE
)

# Do a spatial join on our two data sets using the sf::st_join() function.
wi_compare = 
  st_join(
    wi_tract_income, 
    mad_mil,
    join = st_within, left = FALSE
  )

# Draw a histogram to compare across metros.
wi_compare_plot <- wi_compare %>%
  ggplot(aes(x = estimate)) + 
  geom_histogram() + 
  facet_wrap(~metro_name) +
  labs(
    title = "Households Income Medians in 2019", 
    caption = "Data: US Census Bureau"
  ) 

wi_compare_plot
