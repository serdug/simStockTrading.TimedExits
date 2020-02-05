# Copyright (c) 2020 Sergey Dugaev
# Licensed under the MIT license.
# See the LICENSE file in the project root for more information.
#
# Model performance calculation in local environments. Using a separate 
# environment to calculate results for each input enables to avoid repetitions 
# in the code applying the same functions to every particular environment. 
# 
# It may be practical, for instance, when analysing sensitivity of model 
# performance to trade price fluctuations. In such a case, a series of models 
# with different trade signals and/or different trade prices may be calculated 
# in just one go.

parameters <- function() {
  # Assigns parameter values to variables. 
  # Requires:
  #   param - parameters read from YAML file
  
  # Cash initially allocated for trading
  Cash <<- param$cash
  
  # A vector (num) to calculate a fraction of initially allocated cash 
  # available for opening a new position.
  # Coefficients, such as 5 (for 1/5 limit per position held for 5 days) are 
  # multiplied to further calculate cash limit of exposure per position.
  lim <- 1 / param$coef
  
  # Limit of exposure (USD) per position.
  LimPP <<- Cash * cumprod(lim)[length(lim)]
  
  # Broker's commission per share bought or sold
  Fee <<- param$comm
  
  # Holding period
  HoldPer <<- param$keep
}

detect.env <- function(e) {
  # Returns an environment object being provided either its name (character) or 
  # the environment object itself.
  if (is.environment(e)) e else get(e)
}

# Read parameters from YAML file
param <- yaml::yaml.load_file("params.yaml")

# Assign values to global variables visible in every local environment
parameters()

# Listed inputs ==> local environments for calculations
listed <- param$input

# Calculate results in local environments specific to every set of input 
# signals and/or prices.
for (i in 1:length(listed)) {
  # Naming a specific environment for each set of calculations
  lvl <- paste("calc", i, ".env", sep = "")
  
  if (!exists(lvl)) {
    # Convert lvl from character string to a new environment object
    assign(lvl, new.env())
    
    # Copy template functions sourced from file to this environment locally
    sys.source(file = "./template.R", envir = detect.env(lvl))
  } else {
    stop(paste("Duplicate object name:", lvl, sep = " "))
  }
  
  local({
    # Read signals from input data
    sig <- read.csv(paste(param$path, param$input[i], sep = ""))

    # Initialize a list for arguments holding calculation results
    ast <- list()
    
    prices()
    positions()
    quantity()
    commissions()
    proceeds()
    basis()
    totals()
    assets()
    # drawdowns()
  }, envir = detect.env(lvl))
}

# Cleaning up
rm(i, lvl)
