## Regression Models for Forecasting
## We fit a simple linear model to every pixel in the SST data set, 
## and we use these models to predict Sea Surface Temperature (SST) for a month in which we have no SST data
## The model simply contain an intercept and a single regressor, namely, the Southern Oscillation Index (SOI).

# install.packages("STRbook") # You might need to install some system dependency in terminal before, see the error message.
# library(devtools)
# install_github("andrewzm/STRbook")

if (!require("pacman")) install.packages("pacman") # Download (if needed) and load package management tools 

pacman::p_load(broom, tidyverse, STRbook, purrr) # Download (if needed) and load some packages for spatial analysis
# broom and purrr are used for fitting and predicting with multiple models simultaneously

data("SST_df", package = "STRbook") # Use already tidied-up data
data("SSTlonlat", package = "STRbook") # Coordinates data
data("SSTlandmask", package = "STRbook") # Landmask data

lonlatmask_df <- data.frame(cbind(SSTlonlat, SSTlandmask)) # combine the land mask data with the coordinates data frame
names(lonlatmask_df) <- c("lon", "lat", "mask")

# Fit linear time-series models to the SSTs in each pixel using data up to April 1997

# Create a data frame containing the SST data from Jan 1970 to Apr 1997
SST_pre_May <- filter(SST_df, Year <= 1997) %>%
  filter(!(Year == 1997 &
             Month %in% c("May", "Jun", "Jul",
                          "Aug", "Sep", "Oct",
                          "Nov", "Dec"))) 

# Use purr and broom to construct a nested data frame that contains a linear model fitted to every fixel
fit_one_pixel <- function(data)
    mod <- lm(sst ~ 1 + soi, data = data) # the function that ﬁts the linear model at a single pixel to the data over time

pixel_lms <- SST_pre_May %>%
  filter(!is.na(sst)) %>% # remove missing data
  group_by(lon, lat) %>% # group by pixel
  nest() %>% 
  mutate(model = map(data, fit_one_pixel)) %>% # ﬁt a model to each pixel
  mutate(model_df = map(model, tidy)) # extract a data frame containing information on the linear ﬁt by pixel

pixel_lms %>% head(10)

# extract the model parameters from the linear-ﬁt data frames
lm_pars <- pixel_lms %>% 
  unnest(model_df) 

head(lm_pars, 10) # regression results

# Now, we plot spatial maps of the intercept and the regression coefﬁcient associated with SOI.
lm_pars <- left_join(lonlatmask_df, lm_pars) # Do a left join with the coordinates dataframe

# g2 <- ggplot(filter(lm_pars, term == "(Intercept)" | mask == 1)) +
#   geom_tile(aes(lon, lat, fill = estimate)) +
#   fill_scale() +
#   theme_bw() + coord_fixed()
# 
# g3 <- ggplot(filter(lm_pars, term == "soi" | mask == 1)) +
#   geom_tile(aes(lon, lat, fill = estimate)) +
#   fill_scale() +
#   theme_bw() + coord_fixed()

# Forecasting SST in October 1997 using the lagged SOI in September 1997
data("SOI", package = "STRbook") # Get SOI data
SOI_df <- select(SOI, -Ann) %>% 
  gather(Month, soi, -Year)

# Get SOI in September 1997 for forecasting
soi_fore <- filter(SOI_df, Month == "Sep" & Year == "1997") %>%
  select(soi)

forecast_one_pixel <- function(lm, soi_pred) {
  predict(lm,                           # linear model
          newdata = soi_fore,           # predict covariates
          interval = "prediction") %>%  # output intervals
    data.frame() %>%                      # convert to dataframe
    mutate(se = (upr-lwr)/(2 * 1.96)) %>% # compute standard error
    select(fit, se)                       # return fit & se
}

SST_Oct_1997 <- pixel_lms %>%
  mutate(fores = map(model,           # Save the ﬁt and prediction standard error as new cols
                     forecast_one_pixel,
                     soi_pred = soi_pred)) %>%
  unnest(fores)                           # Unnest the foress data

forecase_plot <- ggplot(SST_Oct_1997, aes(lon, lat, z = fit)) +
     geom_contour(aes(colour = after_stat(level))) +
     fill_scale() +
     theme_bw() + 
     coord_fixed() +
     labs(
       title = "Forecasted Sea Sea Surface Temperature (SST)"
     )

forecase_plot


