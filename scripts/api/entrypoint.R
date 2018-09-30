root_dir = dirname(rprojroot::thisfile())

# Packages
library(plumber)

# Create and run router
plumb(file.path(root_dir,"plumber.R"))$run(port=8000)