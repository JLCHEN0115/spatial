## Cool Stuffs of Spatial Analysis in R

*In this section, I did some exploratory spatial data analysis in R. Due to the inherent complexity of spatial data, it could be nasty to deal with. However, the **sf** package provides a slik workflow in terms of spatial data, and coherent integration with **tidyverse** ecosystem. In the end of this section, I explored the rent in Wisconsin using US census API.*

```r
# Download (if needed) and load package management tools 
if (!require("pacman")) install.packages("pacman") 
```

```r
# Download (if needed) and load some packages for spatial analysis
pacman::p_load(sf, tidyverse, data.table, hrbrthemes, lwgeom, rnaturalearth, maps, mapdata, spData, tigris, tidycensus, leaflet, tmap, tmaptools) 
```

The **sf** is an important package in this illustration.[^1]  **tidycensus** and **tigris** are packages for the ease of using US census data. **tidyverse** contains the workhorse packages for (almost every) data analysis task in R. The **maps** and **mapdata** packages have detailed county- and state/province-level data for several individual nations.

Now, we read the Shapefile of Wisconsin using **sf::st_read**.
```r
## Read Shapefile[^2] in R using sf::st_readrm
wi_shape <- st_read("~/Documents/test-play/Just-Playing/WI_CensusTL_Counties_2019/WI_CensusTL_Counties_2019.shp", quiet = TRUE)
```
Using the Shapefile, we can draw a simple plot using **ggplot2** (one of my favourite package in R).

```r
## Counties of Wisconsin Plot
wi_shape_plot <- ggplot(data = wi_shape) +
  geom_sf(color = "ghostwhite", fill = "red3") + # add geom_sf layer
  labs(
    title = "Counties of Wisconsin", 
    caption = "Data: UW-Madison Robinson Map Library"
  )

wi_shape_plot
```

Here it is.
![](Figures/wi_shape_plot.png)<!-- -->

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

[^1]: The “sf” stands for simple features, which is a simple (ahem!) standard for representing the spatial geometries of real-world objects on a computer.
[^2]: A *shapefile* is a simple, nontopological format for storing the geometric location and attribute information of geographic features.