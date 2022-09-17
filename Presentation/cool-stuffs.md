## Cool Stuffs of Spatial Analysis in R

>In this section, I did some exploratory spatial data analysis in R. Due to the inherent complexity of spatial data, it could be nasty to deal with. However, the `sf` package provides a slik workflow in terms of spatial data, and coherent integration with `tidyverse` ecosystem. In the end of this section, I explored the rent in Wisconsin using US census API.**

## Wisconsin Counties Areas

```r
# Download (if needed) and load package management tools 
if (!require("pacman")) install.packages("pacman") 
```

```r
# Download (if needed) and load some packages for spatial analysis
pacman::p_load(sf, tidyverse, data.table, hrbrthemes, lwgeom, rnaturalearth, maps, mapdata, spData, tigris, tidycensus, leaflet, tmap, tmaptools) 
```

The `sf` is an important package in this illustration.[^1]  `tidycensus` and `tigris` are packages for the ease of using US census data. `tidyverse` contains the workhorse packages for (almost every) data analysis task in R. The `maps` and `mapdata` packages have detailed county- and state/province-level data for several individual nations.

Now, we read the Shapefile[^2] of Wisconsin using `sf::st_read`.

```r
## Read Shapefile in R using sf::st_readrm
wi_shape <- st_read("~/Documents/test-play/Just-Playing/WI_CensusTL_Counties_2019/WI_CensusTL_Counties_2019.shp", quiet = TRUE)

wi_shape
```

Using the Shapefile, we can draw a simple plot using `ggplot2` (one of my favourite package in R).

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
<img src="/Figures/wi_shape_plot.png" width = 65% height = 65%>

But that is just a map. We want to do something more interesting. Say, add the area information for each county in Wisconsin.

First, we do a little data wrangling using the `tidyverse` package.

```r
wi_area <- wi_shape %>%
    mutate(AREA = ALAND/1000000000) # Create a new variable
```

Now we add more layers into our map.

```r
# Plot the area of Counties in Wisconsin
wi_area_plot <- ggplot(wi_area) +
     geom_sf(aes(fill = AREA), alpha=0.8, col="white") +
     scale_fill_viridis_c(name = "Area") + # For beauty and color-blind people.
     labs(  
       title = "Counties of Wisconsin", 
       caption = "Data: UW-Madison Robinson Map Library"
     )

wi_area_plot
```

<img src="/Figures/wi_area_plot.png" width = 65% height = 65%>

## Household Median Incomes in Wisconsin

>Now, we illustrate something that has more "economics flavor." We want to know the household income median across Wisconsin. This can be straightforward to do with some plain data summary, but our spatial analysis definitely spice it up.**

```r
## add settings to optimize use with the sf package
options(tigris_class = "sf") 
options(tigris_use_cache = TRUE)
```

To access US census data, you need to [request an key for API](https://api.census.gov/data/key_signup.html) first.

Then `tidycensus` and `tigris` will take over aftering telling them your key.

```r
# Set up API access
census_api_key("YOUR KEY HERE", install = TRUE) 
```

Now, we request Wisconsin county level *American Community Survey*[^3] data.

```r
wi_income <- get_acs(
  geography = "county",
  variables = "B19013_001", # Searching for variable IDs is usually painful. load_variable() is an option, also see https://censusreporter.org/
  state = "WI",
  year = 2019,
  geometry = TRUE
)
```

Let us print out the `wi_income` object that we just created and take a look at its structure.


```r
wi_income
```

```
## Simple feature collection with 72 features and 5 fields
## Geometry type: MULTIPOLYGON
## Dimension:     XY
## Bounding box:  xmin: -92.88811 ymin: 42.49198 xmax: -86.80542 ymax: 47.08062
## Geodetic CRS:  NAD83
## First 10 features:
##    GEOID                          NAME   variable estimate  moe                       geometry
## 1  55121 Trempealeau County, Wisconsin B19013_001    58548 1500 MULTIPOLYGON (((-91.61285 4...
## 2  55111        Sauk County, Wisconsin B19013_001    59943 1719 MULTIPOLYGON (((-90.3124 43...
## 3  55043       Grant County, Wisconsin B19013_001    54800 1264 MULTIPOLYGON (((-91.15681 4...
## 4  55075   Marinette County, Wisconsin B19013_001    50330 1525 MULTIPOLYGON (((-87.50588 4...
## 5  55003     Ashland County, Wisconsin B19013_001    42510 2858 MULTIPOLYGON (((-90.46546 4...
## 6  55037    Florence County, Wisconsin B19013_001    52181 3397 MULTIPOLYGON (((-88.68331 4...
## 7  55029        Door County, Wisconsin B19013_001    61560 2056 MULTIPOLYGON (((-86.95617 4...
## 8  55023    Crawford County, Wisconsin B19013_001    50595 2414 MULTIPOLYGON (((-91.21499 4...
## 9  55001       Adams County, Wisconsin B19013_001    46369 1834 MULTIPOLYGON (((-90.02638 4...
## 10 55007    Bayfield County, Wisconsin B19013_001    56096 1877 MULTIPOLYGON (((-90.80495 4...
```


**Like people say, a graph worth a thousand words.**

```r
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
```

<img src="/Figures/wi_income_plot.png" width = 65% height = 65%>

That is great, but maybe "too much." Maybe we are only interested in comparing some of the *Metropolitan Aeras(MAs)*. 

The general concept of a metropolitan area (MA) is that of a core area containing a large population nucleus, together with adjacent communities that have a high degree of economic and social integration with that core.(Like a group of commuties with a hub, HK and SZ with cities in Guangdong, Guangxi.)

Now, we want to compare median incomes for downtown Madison(capital city of WI) and Milwaukee (a great city with an amazing basketball team *Milwaukee Bucks*).

First, we ask metro data from the remote server.

```r
mad_mil = 
  tigris::core_based_statistical_areas(cb = TRUE) %>%
  filter(grepl("Madison, WI|Milwaukee", NAME)) %>%
  select(metro_name = NAME)
mad_mil
```

Note that `mad_mil` is *just* a Shapefile that contains no real data of interest.
In fact, it's only $2 \times 2$.

```
## Simple feature collection with 2 features and 1 field
## Geometry type: MULTIPOLYGON
## Dimension:     XY
## Bounding box:  xmin: -90.42991 ymin: 42.50026 xmax: -87.79169 ymax: 43.64367
## Geodetic CRS:  NAD83
##               metro_name                       geometry
## 1            Madison, WI MULTIPOLYGON (((-90.42991 4...
## 2 Milwaukee-Waukesha, WI MULTIPOLYGON (((-88.54215 4...
```

Now, we get the *tract level data*[^4].

```r
wi_tract_income <- get_acs(
  geography = "tract", # county before
  variables = "B19013_001", 
  state = "WI",
  year = 2019,
  geometry = TRUE
)
```

**Important Step:** <ins>Do a spatial join on our two data sets using the `sf::st_join()` function. </ins> That is, we want each community got mapped into the correct metro area that includes it.

```
wi_compare = 
  st_join(
    wi_tract_income, 
    mad_mil,
    join = st_within, left = FALSE
  )
```

Now we can draw a histogram to compare across metros.

```r
wi_compare_plot <- wi_compare %>%
  ggplot(aes(x = estimate)) + 
  geom_histogram() + 
  facet_wrap(~metro_name) +
  labs(
    title = "Households Income Medians in 2019", 
    caption = "Data: US Census Bureau"
  ) 
wi_compare_plot
```
<img src="/Figures/wi_compare_plot.png" width = 65% height = 65%>


[^1]: The “sf” stands for simple features, which is a simple (ahem!) standard for representing the spatial geometries of real-world objects on a computer.

[^2]: A *shapefile* is a simple, nontopological format for storing the geometric location and attribute information of geographic features.

[^3]: American Community Survey provides great data for research in social science. From wikipedia: "Sent to approximately 295,000 addresses monthly (or 3.5 million per year), it is the largest household survey that the Census Bureau administers."

[^4]: The *"Census Tract"* is an area roughly equivalent to a neighborhood established by the Bureau of Census for analyzing populations.