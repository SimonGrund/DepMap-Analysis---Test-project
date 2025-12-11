# Setup Script: Install Required R Packages
# Run this script first to ensure all dependencies are installed

message("=== DepMap Analysis Package Setup ===")
message("This script will check and install required R packages")
message("")

# List of required packages
required_packages <- c(
  "tidyverse",    # Core tidyverse packages (dplyr, ggplot2, tidyr, etc.)
  "here",         # Path management
  "tidymodels",   # Tidy modeling framework
  "broom",        # Tidy model outputs
  "ggbeeswarm",   # Better point distributions for plots
  "patchwork"     # Combine multiple plots
)

# Function to check and install packages
install_if_missing <- function(package) {
  if (!require(package, character.only = TRUE, quietly = TRUE)) {
    message(sprintf("Installing %s...", package))
    install.packages(package, dependencies = TRUE, repos = "https://cloud.r-project.org/")
    
    # Verify installation
    if (require(package, character.only = TRUE, quietly = TRUE)) {
      message(sprintf("✓ %s installed successfully", package))
      return(TRUE)
    } else {
      warning(sprintf("✗ Failed to install %s", package))
      return(FALSE)
    }
  } else {
    message(sprintf("✓ %s already installed", package))
    return(TRUE)
  }
}

# Check and install all packages
message("Checking required packages:")
message("")

results <- sapply(required_packages, install_if_missing)

message("")
message("=== Installation Summary ===")

if (all(results)) {
  message(sprintf("✓ All %d packages are ready!", length(required_packages)))
  message("")
  message("You can now run:")
  message("  1. source('01_download_depmap_data.R')     # Download data")
  message("  2. source('02_analyze_parp1_dependency.R')  # Run analysis")
} else {
  failed_packages <- required_packages[!results]
  warning(sprintf("Failed to install %d package(s): %s", 
                  length(failed_packages),
                  paste(failed_packages, collapse = ", ")))
  message("")
  message("Please try installing failed packages manually:")
  message(sprintf("install.packages(c('%s'))", paste(failed_packages, collapse = "', '")))
}

# Display R version info
message("")
message("=== R Environment Info ===")
message(sprintf("R version: %s", R.version.string))
message(sprintf("Platform: %s", R.version$platform))
message(sprintf("Working directory: %s", getwd()))
