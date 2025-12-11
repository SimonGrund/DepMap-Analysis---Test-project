# DepMap Data Download Script for Breast Cancer Cell Lines
# This script downloads necessary data from DepMap Public (latest quarterly release)
# Focus: Proving HR-deficient breast cancer cell lines depend on PARP1
#
# NOTE: DepMap releases new data quarterly (e.g., 24Q2, 24Q4, 25Q1)
# If downloads fail with 404 errors, the release version may have changed.
# Visit https://depmap.org/portal/download/ to find the current release and
# update the 'depmap_base_url' variable below to the correct version.

# Load required packages
library(tidyverse)
library(here)

# Create data directory if it doesn't exist
if (!dir.exists(here("data"))) {
  dir.create(here("data"), recursive = TRUE)
}

# DepMap Public 24Q4 data URLs (updated to latest release)
# Note: DepMap releases are quarterly. If these URLs fail, visit:
# https://depmap.org/portal/download/ to find the current release
depmap_base_url <- "https://depmap.org/portal/download/api/download/external?file_name=public_24Q4%2F"

# Define datasets to download
datasets <- list(
  # Gene dependency scores (CERES) - shows which genes are essential for cell survival
  gene_dependency = list(
    url = paste0(depmap_base_url, "CRISPRGeneEffect.csv"),
    filename = "CRISPRGeneEffect.csv"
  ),
  
  # Cell line metadata - includes cancer type, lineage, etc.
  sample_info = list(
    url = paste0(depmap_base_url, "Model.csv"),
    filename = "Model.csv"
  ),
  
  # Mutation data - to identify HR-deficient cell lines
  mutations = list(
    url = paste0(depmap_base_url, "OmicsSomaticMutations.csv"),
    filename = "OmicsSomaticMutations.csv"
  ),
  
  # Gene expression data - for validation
  gene_expression = list(
    url = paste0(depmap_base_url, "OmicsExpressionProteinCodingGenesTPMLogp1.csv"),
    filename = "OmicsExpressionProteinCodingGenesTPMLogp1.csv"
  )
)

# Function to download files with progress and better error handling
download_depmap_file <- function(url, filename) {
  filepath <- here("data", filename)
  
  # Skip if file already exists
  if (file.exists(filepath)) {
    message(sprintf("✓ %s already exists, skipping download", filename))
    return(filepath)
  }
  
  message(sprintf("Downloading %s...", filename))
  message(sprintf("URL: %s", url))
  
  tryCatch({
    download.file(
      url = url,
      destfile = filepath,
      method = "auto",
      mode = "wb",
      quiet = FALSE
    )
    message(sprintf("✓ Successfully downloaded %s", filename))
    return(filepath)
  }, error = function(e) {
    message(sprintf("✗ Error downloading %s: %s", filename, e$message))
    
    # Check if it's a 404 error and provide helpful guidance
    if (grepl("404|Not Found", e$message, ignore.case = TRUE)) {
      message("   ⚠ 404 Error: The file was not found at the specified URL.")
      message("   This usually means the DepMap release version has changed.")
      message("   Please visit https://depmap.org/portal/download/ to:")
      message("   1. Find the current release version")
      message("   2. Download files manually, or")
      message("   3. Update the 'depmap_base_url' in this script")
    }
    
    return(NULL)
  })
}

# Download all datasets
message("=== Starting DepMap Data Download ===")
message(sprintf("Data will be saved to: %s", here("data")))
message("")

download_results <- map2(
  map(datasets, "url"),
  map(datasets, "filename"),
  download_depmap_file
)

message("")
message("=== Download Summary ===")
success_count <- sum(!is.null(download_results))
message(sprintf("Successfully downloaded/found: %d/%d files", success_count, length(datasets)))

if (success_count == length(datasets)) {
  message("✓ All data files are ready for analysis!")
} else {
  warning("Some files failed to download. Check messages above for details.")
  message("")
  message("=== Manual Download Instructions ===")
  message("If automatic downloads fail due to URL changes:")
  message("1. Visit: https://depmap.org/portal/download/")
  message("2. Look for the latest 'DepMap Public' release (e.g., 24Q4, 25Q1, etc.)")
  message("3. Download these files manually:")
  message("   - CRISPRGeneEffect.csv")
  message("   - Model.csv")
  message("   - OmicsSomaticMutations.csv")
  message("   - OmicsExpressionProteinCodingGenesTPMLogp1.csv")
  message(sprintf("4. Place them in: %s", here("data")))
  message("5. Re-run this script - it will skip existing files")
  message("")
  message("Alternatively, update the 'depmap_base_url' variable in this script")
  message("to point to the current release version.")
}

# Load and filter breast cancer cell lines
message("")
message("=== Loading and Filtering Data ===")

# Load sample info to identify breast cancer cell lines
sample_info <- read_csv(
  here("data", "Model.csv"),
  show_col_types = FALSE
)

# Filter for breast cancer cell lines
breast_cancer_lines <- sample_info %>%
  filter(OncotreeLineage == "Breast") %>%
  select(ModelID, StrippedCellLineName, OncotreeLineage, 
         OncotreePrimaryDisease, Age, Sex, PatientRace)

message(sprintf("Found %d breast cancer cell lines in DepMap", nrow(breast_cancer_lines)))

# Save filtered breast cancer cell line info
write_csv(
  breast_cancer_lines,
  here("data", "breast_cancer_cell_lines.csv")
)

message(sprintf("✓ Saved breast cancer cell line metadata to: %s", 
                here("data", "breast_cancer_cell_lines.csv")))

message("")
message("=== Next Steps ===")
message("1. Run 02_analyze_parp1_dependency.R to perform the analysis")
message("2. Check the results/ folder for outputs and visualizations")
