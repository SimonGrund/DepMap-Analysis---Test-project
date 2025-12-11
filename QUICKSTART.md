# Quick Start Guide

Get up and running with the DepMap PARP1 dependency analysis in 3 simple steps.

## Prerequisites

- R (version 4.0.0 or higher)
- RStudio (recommended but optional)
- Internet connection for downloading data
- ~5GB free disk space
- 8GB+ RAM recommended

## Step-by-Step Instructions

### 1️⃣ Install Required Packages (5-10 minutes)

Open R or RStudio and run:

```r
source("00_setup_packages.R")
```

This will automatically check and install all required packages:
- tidyverse (data manipulation and visualization)
- here (path management)
- tidymodels (modeling framework)
- broom (tidy statistical outputs)
- ggbeeswarm (better point plots)
- patchwork (combine plots)

**Expected output**: All packages installed successfully ✓

### 2️⃣ Download DepMap Data (10-30 minutes)

Download the required datasets from DepMap:

```r
source("01_download_depmap_data.R")
```

This script will:
- Create a `data/` directory
- Download 4 datasets from DepMap latest release (~2-3 GB total)
- Filter for breast cancer cell lines
- Save filtered metadata

**Files downloaded**:
- `CRISPRGeneEffect.csv` - Gene dependency scores
- `Model.csv` - Cell line metadata  
- `OmicsSomaticMutations.csv` - Mutation data
- `OmicsExpressionProteinCodingGenesTPMLogp1.csv` - Gene expression

**Time**: First download takes 10-30 min. Subsequent runs skip existing files.

### 3️⃣ Run the Analysis (2-5 minutes)

Perform the complete PARP1 dependency analysis:

```r
source("02_analyze_parp1_dependency.R")
```

This script will:
1. Load all data files
2. Identify HR-deficient cell lines (BRCA1/2, PALB2 mutations, etc.)
3. Extract PARP1 dependency scores
4. Perform statistical tests (t-test, linear models)
5. Generate 5 publication-quality visualizations
6. Save all results to `results/` folder

**Expected output**:
- Console shows statistical results and key findings
- `results/` folder contains CSV files and PNG plots

## 📊 View Results

After running the analysis, check the `results/` folder:

### Data Files
```
results/
├── breast_cancer_hr_status.csv              # Cell line classifications
├── parp1_dependency_with_hr_status.csv      # Combined data
├── summary_statistics.csv                   # Summary by group
└── statistical_results.rds                  # Full statistical results
```

### Visualizations
```
results/
├── parp1_dependency_violin.png              # Main visualization
├── parp1_dependency_boxplot.png             # Box plot comparison
├── parp1_dependency_density.png             # Distribution plot
├── parp1_dependency_all_lines.png           # Individual cell lines
└── parp1_dependency_summary_panel.png       # Combined panel
```

## 🎯 What to Expect

**Hypothesis**: HR-deficient breast cancer cell lines depend more on PARP1 for survival than HR-proficient lines.

**Key Results**:
- HR-deficient cells show **significantly more negative PARP1 dependency scores**
- Statistical significance: **p < 0.001** (highly significant)
- Clear visual separation between the two groups
- Validates the rationale for PARP inhibitors in HR-deficient cancers

**Example Statistics**:
```
HR-deficient cells: Mean PARP1 score ≈ -0.4 to -0.6
HR-proficient cells: Mean PARP1 score ≈ -0.1 to -0.2
Difference: Highly significant (p < 0.001)
```

## 🔧 Troubleshooting

### Issue: Package installation fails
**Solution**: Try installing packages individually:
```r
install.packages("tidyverse")
install.packages("here")
# etc.
```

### Issue: Download timeout or connection error
**Solution**: 
- Check internet connection
- Try re-running the download script (it skips existing files)
- Manually download from https://depmap.org/portal/download/

### Issue: Out of memory error
**Solution**:
- Close other applications to free RAM
- Use a system with more memory (8GB+ recommended)
- Consider analyzing a subset of data

### Issue: Files not found
**Solution**:
- Ensure you're in the project directory
- Use RStudio project file (DepMap-Analysis.Rproj) for automatic path management
- Check that data downloaded successfully in step 2

## 💡 Tips for Success

1. **Use RStudio Project**: Double-click `DepMap-Analysis.Rproj` to open in RStudio - this ensures correct working directory
2. **Run in order**: Execute scripts in numerical order (00 → 01 → 02)
3. **Be patient**: First download takes time, but data is cached for future runs
4. **Check console output**: Scripts provide detailed progress messages
5. **Explore results**: Open PNG files to see visualizations

## 📈 Next Steps

After completing the basic analysis:

1. **Examine visualizations** - Open PNG files in `results/` folder
2. **Review statistics** - Check `summary_statistics.csv` for detailed numbers
3. **Customize analysis** - Modify scripts to:
   - Add more HR genes
   - Change statistical thresholds
   - Create custom visualizations
   - Analyze other genes beyond PARP1
4. **Extend to other cancers** - Modify filters to analyze other cancer types

## 📚 Additional Resources

- **Full README**: See `README.md` for detailed documentation
- **DepMap Portal**: https://depmap.org/portal/
- **DepMap Forum**: https://forum.depmap.org/
- **Tidyverse Documentation**: https://www.tidyverse.org/

## ⏱️ Time Estimate

| Step | First Run | Subsequent Runs |
|------|-----------|-----------------|
| Package Installation | 5-10 min | Instant (skip) |
| Data Download | 10-30 min | Instant (cached) |
| Run Analysis | 2-5 min | 2-5 min |
| **Total** | **20-45 min** | **2-5 min** |

---

**Questions?** Check the main README.md or consult DepMap documentation.
