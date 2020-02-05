# Copyright (c) 2020 Sergey Dugaev
# Licensed under the MIT license.
# See the LICENSE file in the project root for more information.
#
# View results and save results in CSV format.

source('./main.R')

list.envs <- function() {
  # Returns a character vector of the names of local environments.
  a <- ls(.GlobalEnv)
  x <- c()
  for (i in 1:length(a)) {
    if (is.environment(get(a[i]))) x <- c(x, a[i])
  }
  return(x)
}

myEnvirs <- list.envs()

# The numbers of input, output files and environments containing calculated 
# results must be the same
stopifnot(length(param$input) == length(param$output))
stopifnot(length(myEnvirs)    == length(param$output))

# Initialize empty variables for results
perf <- list()

# Write results in the output files
for (i in 1:length(myEnvirs)) {
  perf[[i]] <- local(
    data.frame(Date        = ast$Date,
               ClosePx     = ast$ClosePx,
               TradePx     = ast$TradePx,
               SI          = as.integer(ast$S$Pos$I),
               SO          = as.integer(ast$S$Pos$O),
               LI          = as.integer(ast$L$Pos$I),
               LO          = as.integer(ast$L$Pos$O),
               Assets      = ast$NAV), 
    envir = detect.env(myEnvirs[i]))
  
  id_csv <- param$out[[i]]
  write.csv(perf[[i]], file = id_csv, fileEncoding = "UTF-8", row.names = FALSE)
}

# Pick an index to view the respective data frame
# View(perf[[i]])

# Cleaning up
rm(i, id_csv)

#####################################################################
# # Alternative naming
# t_stamp   <- strptime(date(), format = "%a %b %d %H:%M:%S %Y")
# t_stamp_s <- format(as.POSIXct(t_stamp), format = "%Y-%m-%d")
# id_data <- "file_name"
# id_csv  <- paste("./calc/", id_data, "_", t_stamp_s, ".csv", sep = "")
# write.csv(perf, file = id_csv, fileEncoding = "UTF-8", row.names = FALSE)