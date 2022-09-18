# Spatial Statistics

***For analysis about tourism and economic development with spatial economics/ econometrics (also the spillover effects), the paper [Tourism and Economic Development: Evidence from Mexico’s Coastline](https://www.aeaweb.org/articles?id=10.1257/aer.20161434) by Benjamin Faber and Cecile Gaubert should be a great one (in my personal opinion.)***

> This repository is mainly base on [the lecture notes by Grant McDermott](https://github.com/uo-ec607) as well as the book [Spatio-Temporal Statistics with R](https://spacetimewithr.org/) by  Christopher, Andrew and Noel. Please see the original sources for lisenses.

## Three Goals for Spatio-temporal Statistical Modelling

1. Predict a plausible value of a response variable at some location in space within the time span of the observations, and reporting the uncertainty of prediction. (for interpolation / smoothing)

2. Perform scientific inference about the important covariates on the response variable in the presence of spatio-temporal dependence.

3. Forecasting the future value of the response variable at some location, along with the uncertainty of the forecast.

## Steps in Spatial(-temporal) Statistics Modelling

**There are four steps for spatial(-temporal) statistical analysis.**

- **STEP 1** [Exploratory Data Analysis](/Presentation/cool-stuffs.md)

    Usually we start with some visualization and summary to examine the dependent structure and potential relations across time and space.

- **STEP 2** [Fitting in Some Simple Models](/Presentation/simple-fit.md)

    These are usually very basic statistical models that *does not* explicitly account for spatio-temporal structure. e.g., OLS, Generalized Linear Models or Lasso(still not account the structure explicitly).

    There is a chance to accomplish the goal with these methods, but most likely, they cannot or we want to take full advantage of our spatial-temporal data. This calls for more specialized spatial-temporal models.

- **STEP 3** [Spatio-Temporal Models]

    - **Descriptive Approach**

    In Descriptive Spatio-Temporal Statistical Models, the dependent random process is defined by moment conditions of its marginal distribution. It does not particularly concern with the causal structure that lead to dependence in the random process. This is the traditional way and works good for prediction and inference (constructing confidence sets).

    - **Dynamic Approach**

    Modelling effort focused on conditional distribution that describe evolution of the spatial process in time.  
    **Most useful for forecasting.**

- **SETP 4** [Spatio-Temporal Statistical Models Evaluation]

