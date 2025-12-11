# DepMap Analysis: PARP1 Dependency in HR-Deficient Breast Cancer

This project analyzes data from the [DepMap (Dependency Map) Project](https://depmap.org/) to prove that **Homologous Recombination (HR) deficient breast cancer cell lines depend on PARP1 for survival**.

## 🎯 Project Goal

Demonstrate that breast cancer cell lines with mutations in HR pathway genes (BRCA1, BRCA2, PALB2, etc.) show significantly greater dependency on PARP1 compared to HR-proficient cell lines, providing evidence for the therapeutic rationale of PARP inhibitors in HR-deficient cancers.

## 📋 Background

**Homologous Recombination (HR)** is a DNA repair pathway critical for fixing double-strand breaks. When HR is deficient (e.g., due to BRCA1/2 mutations), cells become dependent on alternative repair mechanisms, particularly **PARP1** (Poly ADP-ribose polymerase 1).

This creates a "synthetic lethality" relationship where:
- HR-deficient cells require PARP1 for survival
- PARP inhibitors selectively kill HR-deficient cancer cells
- This is the basis for FDA-approved PARP inhibitors in BRCA-mutated cancers

## 🗂️ Project Structure

```
DepMap-Analysis/
├── 01_download_depmap_data.R      # Download and prepare DepMap data
├── 02_analyze_parp1_dependency.R  # Main analysis script
├── data/                          # Raw data files (created by script)
├── results/                       # Analysis outputs and visualizations
├── DepMap-Analysis.Rproj         # RStudio project file
└── README.md                      # This file
```

## 📦 Required R Packages

This analysis uses the tidyverse ecosystem and related packages:

```r
# Install required packages
install.packages(c(
  "tidyverse",    # Data manipulation and visualization
  "here",         # Path management
  "tidymodels",   # Modeling framework
  "broom",        # Tidy model outputs
  "ggbeeswarm",   # Better point distributions
  "patchwork"     # Combine plots
))
```

## 🚀 How to Run the Analysis

### Step 1: Download DepMap Data

Run the first script to download necessary data from the latest DepMap Public release:

```r
source("01_download_depmap_data.R")
```

This will download (~2-3 GB total):
- **CRISPRGeneEffect.csv**: Gene dependency scores (CERES algorithm)
- **Model.csv**: Cell line metadata (cancer types, lineage)
- **OmicsSomaticMutations.csv**: Mutation data
- **OmicsExpressionProteinCodingGenesTPMLogp1.csv**: Gene expression data

The script automatically:
- Creates a `data/` directory
- Downloads only missing files (skip if already downloaded)
- Filters for breast cancer cell lines
- Saves filtered metadata

**Note**: 
- Downloads may take 10-30 minutes depending on your connection
- If you encounter 404 errors, the DepMap release version may have changed. See [Troubleshooting](#-troubleshooting) below

### Step 2: Run the Analysis

Execute the main analysis script:

```r
source("02_analyze_parp1_dependency.R")
```

This script:
1. **Identifies HR-deficient cell lines** based on mutations in key HR genes (BRCA1, BRCA2, PALB2, RAD51, etc.)
2. **Extracts PARP1 dependency scores** from CRISPR screening data
3. **Performs statistical analysis** (t-test, linear models)
4. **Generates visualizations** showing the relationship
5. **Saves all results** to the `results/` folder

## 📊 Expected Outputs

### Data Files (in `results/`)

- `breast_cancer_hr_status.csv`: Cell lines classified by HR status
- `parp1_dependency_with_hr_status.csv`: Combined dependency scores and HR status
- `summary_statistics.csv`: Summary stats by group
- `statistical_results.rds`: Complete statistical test results

### Visualizations (PNG files in `results/`)

1. **parp1_dependency_violin.png**: Violin plot with individual cell lines
2. **parp1_dependency_boxplot.png**: Box plot comparison
3. **parp1_dependency_density.png**: Density distributions
4. **parp1_dependency_all_lines.png**: Individual cell line rankings
5. **parp1_dependency_summary_panel.png**: Combined multi-panel figure

## 📈 Expected Results

The analysis should demonstrate:

- ✅ **HR-deficient cell lines have significantly more negative PARP1 dependency scores** (more dependent on PARP1)
- ✅ **Statistical significance** with p-value < 0.05 (typically p < 0.001)
- ✅ **Clear separation** between HR-deficient and HR-proficient groups
- ✅ **Biological validation** of synthetic lethality concept

### Interpretation of Dependency Scores

**CERES Dependency Scores**:
- **Negative values** = gene knockout reduces cell viability (dependency)
- **Scores < -0.5** = strong dependency
- **Scores near 0** = non-essential gene
- **Positive values** = gene knockout increases viability

## 🧬 HR Pathway Genes Analyzed

The analysis identifies HR deficiency based on damaging mutations in:

- **BRCA1, BRCA2**: Major HR genes, most common in hereditary breast cancer
- **PALB2**: Partner and localizer of BRCA2
- **RAD51, RAD51C, RAD51D**: Core HR recombinase and paralogs
- **BRIP1, BARD1**: BRCA1-interacting proteins
- **ATM, ATR**: DNA damage checkpoint kinases
- **CHEK1, CHEK2**: Checkpoint effector kinases

## 🔬 Methodology

### Data Source
- **DepMap Public** (latest quarterly release)
- Consortium data from Broad Institute
- Includes 1000+ cancer cell lines
- Releases updated quarterly (Q1, Q2, Q3, Q4)

### Dependency Measurement
- **CRISPR-Cas9 screens** systematically knock out each gene
- **CERES algorithm** corrects for copy number and off-target effects
- Scores represent fitness effect of gene knockout

### Statistical Approach
- **Tidyverse** for data wrangling and visualization
- **T-test** for comparing group means
- **Linear models** for effect size estimation
- **Tidymodels** framework for extensible analysis

## 📚 References

1. **DepMap Project**: https://depmap.org/
2. Meyers, R. M., et al. (2017). "Computational correction of copy number effect improves specificity of CRISPR–Cas9 essentiality screens in cancer cells." *Nature Genetics*
3. Farmer, H., et al. (2005). "Targeting the DNA repair defect in BRCA mutant cells as a therapeutic strategy." *Nature*
4. Bryant, H. E., et al. (2005). "Specific killing of BRCA2-deficient tumours with inhibitors of poly(ADP-ribose) polymerase." *Nature*

## 🤝 Contributing

This is a test/demonstration project. Feel free to:
- Extend the analysis to other cancer types
- Add additional HR pathway genes
- Include gene expression data
- Perform more sophisticated modeling

## 📄 License

This project uses publicly available data from DepMap. Please cite DepMap appropriately if you use this analysis:

> DepMap, Broad (2024): DepMap Public. figshare. Dataset. https://depmap.org/portal/download/
> 
> Note: The specific release version (e.g., 24Q2, 24Q4) depends on when you download the data.

## 🔧 Troubleshooting

### 404 Errors During Data Download

If you encounter 404 errors when downloading data, the DepMap release version has likely been updated. DepMap releases new data quarterly (e.g., 24Q2, 24Q4, 25Q1).

**Solution 1: Update the Release Version**
1. Open `01_download_depmap_data.R`
2. Find the line: `depmap_base_url <- "https://depmap.org/portal/download/api/download/external?file_name=public_XXQX%2F"`
3. Visit https://depmap.org/portal/download/ to find the current release version
4. Update `XXQX` to the current version (e.g., `24Q4`, `25Q1`, etc.)
5. Re-run the download script

**Solution 2: Manual Download**
1. Visit https://depmap.org/portal/download/
2. Find the latest "DepMap Public" release
3. Download these files:
   - CRISPRGeneEffect.csv
   - Model.csv
   - OmicsSomaticMutations.csv
   - OmicsExpressionProteinCodingGenesTPMLogp1.csv
4. Place them in the `data/` directory (create it if it doesn't exist)
5. Re-run the download script (it will skip existing files)

### Other Common Issues

- **Out of memory**: Close other applications or use a system with more RAM (8GB+ recommended)
- **Package installation fails**: Try installing packages individually with `install.packages("package_name")`
- **File not found errors**: Ensure you're in the project directory; use the RStudio project file for automatic path management

## 💡 Tips

- **First run**: Allow time for data downloads (2-3 GB)
- **Subsequent runs**: Data files are cached, analysis runs quickly
- **Memory**: Ensure adequate RAM (8GB+ recommended) for loading large datasets
- **Customization**: Edit gene lists, thresholds, or visualizations as needed
- **DepMap Updates**: DepMap releases new data quarterly; check for updates if downloads fail

## 📧 Contact

For questions about the analysis methodology or DepMap data, refer to:
- DepMap Portal: https://depmap.org/portal/
- DepMap Documentation: https://forum.depmap.org/

---

**Happy Analyzing! 🧬📊**