# DepMap Data Download Script for Breast Cancer Cell Lines
# This script downloads necessary data from DepMap Public 24Q2 release
# Focus: Proving HR-deficient breast cancer cell lines depend on PARP1

# Load required packages
library(tidyverse)
library(here)

# Create data directory if it doesn't exist
if (!dir.exists(here("data"))) {
  dir.create(here("data"), recursive = TRUE)
}

# DepMap Public 24Q2 data URLs (most recent complete release)
depmap_base_url <- "https://depmap.org/portal/download/api/download/external?file_name=public_24Q2%2F"

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

# Function to download files with progress
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
