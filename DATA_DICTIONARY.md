# Data Dictionary

This document describes all data files, variables, and their meanings used in the DepMap PARP1 dependency analysis.

## Input Data Files (from DepMap)

### 1. CRISPRGeneEffect.csv (~500 MB)

**Description**: Gene dependency scores from genome-wide CRISPR knockout screens

**Source**: DepMap Public 24Q2

**Dimensions**: ~1000 rows (cell lines) × ~18,000 columns (genes)

**Format**:
- **First column**: `ModelID` - Unique cell line identifier
- **Remaining columns**: Gene dependency scores in format "GENE_NAME (Entrez_ID)"
  - Example: "PARP1 (142)", "BRCA1 (672)", "TP53 (7157)"

**Score Interpretation**:
| Score Range | Meaning | Example Genes |
|------------|---------|---------------|
| < -1.0 | Essential gene | Ribosomal proteins, DNA polymerase |
| -1.0 to -0.5 | Strong dependency | Oncogenes in addicted cancers |
| -0.5 to 0.0 | Weak dependency | Context-specific essential genes |
| 0.0 | Non-essential | Most genes in most contexts |
| > 0.0 | Growth advantage when knocked out | Some tumor suppressors |

**Key Points**:
- More negative = greater dependency
- CERES algorithm corrects for copy number and batch effects
- Scores are relative fitness effects after gene knockout

### 2. Model.csv (~10 MB)

**Description**: Cell line metadata and annotations

**Source**: DepMap Public 24Q2

**Key Variables**:

| Variable | Type | Description | Example Values |
|----------|------|-------------|----------------|
| `ModelID` | String | Unique cell line identifier | "ACH-000001" |
| `StrippedCellLineName` | String | Standardized cell line name | "MCF7", "MDAMB231" |
| `OncotreeLineage` | String | Cancer lineage/tissue of origin | "Breast", "Lung", "Ovary" |
| `OncotreePrimaryDisease` | String | Specific cancer type | "Breast Invasive Ductal Carcinoma" |
| `Age` | Numeric | Patient age at diagnosis | 48, 65, NULL |
| `Sex` | String | Patient sex | "Female", "Male", "Unknown" |
| `PatientRace` | String | Patient race/ethnicity | "White", "Black", "Asian", NULL |
| `PrimaryOrMetastasis` | String | Sample source | "Primary", "Metastatic" |
| `SampleCollectionSite` | String | Anatomical site | "breast", "pleural effusion" |

**Usage in Analysis**: Filter `OncotreeLineage == "Breast"` to get breast cancer cell lines

### 3. OmicsSomaticMutations.csv (~1.5 GB)

**Description**: Somatic mutations detected by whole exome sequencing

**Source**: DepMap Public 24Q2

**Key Variables**:

| Variable | Type | Description | Example Values |
|----------|------|-------------|----------------|
| `ModelID` | String | Cell line identifier | "ACH-000001" |
| `HugoSymbol` | String | Gene symbol | "BRCA1", "TP53", "PIK3CA" |
| `Chromosome` | String | Chromosome number | "17", "X", "MT" |
| `StartPosition` | Numeric | Genomic position (hg38) | 43045802 |
| `ReferenceAllele` | String | Reference nucleotide | "G", "A" |
| `AlternateAllele` | String | Variant nucleotide | "T", "C" |
| `VariantClassification` | String | Type of mutation | "Missense_Mutation", "Nonsense_Mutation" |
| `VariantType` | String | SNP or Indel | "SNP", "DEL", "INS" |
| `ProteinChange` | String | Amino acid change | "p.R1443*", "p.V600E" |
| `VariantInfo` | String | Predicted impact | "damaging", "truncating", "hotspot" |
| `isCOSMIChotspot` | Boolean | Known cancer hotspot | TRUE, FALSE |

**VariantInfo Categories**:
- **truncating**: Frameshift, nonsense, splice site → likely loss of function
- **damaging**: Missense predicted to impair protein function
- **hotspot**: Recurrent mutation in COSMIC database
- **other non-conserving**: Missense, impact unclear
- **other conserving**: Silent or conservative changes

**Usage in Analysis**: 
- Filter for HR genes: `HugoSymbol %in% c("BRCA1", "BRCA2", "PALB2", ...)`
- Filter for damaging: `VariantInfo %in% c("damaging", "truncating", "hotspot")`

### 4. OmicsExpressionProteinCodingGenesTPMLogp1.csv (~800 MB)

**Description**: Gene expression levels from RNA-seq

**Source**: DepMap Public 24Q2

**Format**: 
- Similar to CRISPRGeneEffect.csv
- First column: `ModelID`
- Remaining columns: Gene expression in format "GENE_NAME (Entrez_ID)"

**Units**: log2(TPM + 1)
- TPM = Transcripts Per Million (normalized for gene length and library size)
- log2 transformation for normal distribution
- +1 pseudocount to handle zero values

**Typical Values**:
| Expression Level | log2(TPM+1) | Interpretation |
|-----------------|-------------|----------------|
| Not detected | 0-2 | Gene not expressed |
| Low | 2-4 | Weak expression |
| Moderate | 4-8 | Typical expression |
| High | 8-12 | Strong expression |
| Very high | >12 | Highly abundant |

**Usage in Analysis**: Optional validation that mutations reduce expression

---

## Output Data Files (from Analysis)

### 1. breast_cancer_cell_lines.csv

**Description**: Filtered metadata for breast cancer cell lines only

**Created by**: `01_download_depmap_data.R`

**Variables**:
- All variables from Model.csv
- Subset to `OncotreeLineage == "Breast"`

**Typical Size**: ~60-80 rows (cell lines)

### 2. breast_cancer_hr_status.csv

**Description**: Cell lines classified by HR status with mutation details

**Created by**: `02_analyze_parp1_dependency.R`

**Variables**:

| Variable | Type | Description |
|----------|------|-------------|
| `ModelID` | String | Cell line identifier |
| `StrippedCellLineName` | String | Cell line name |
| `OncotreeLineage` | String | Cancer lineage (all "Breast") |
| `OncotreePrimaryDisease` | String | Specific cancer type |
| `Age` | Numeric | Patient age |
| `Sex` | String | Patient sex |
| `PatientRace` | String | Patient race |
| `HR_deficient` | Logical | TRUE if HR-deficient, FALSE if HR-proficient |
| `HR_status` | String | "HR-deficient" or "HR-proficient" |
| `mutated_genes` | String | Comma-separated list of mutated HR genes |

**Example**:
```
ModelID: ACH-000123
StrippedCellLineName: MDAMB436
HR_deficient: TRUE
HR_status: HR-deficient
mutated_genes: BRCA1, CHEK2
```

### 3. parp1_dependency_with_hr_status.csv

**Description**: Combined dataset with PARP1 scores and HR status

**Created by**: `02_analyze_parp1_dependency.R`

**Variables**:
- All variables from breast_cancer_hr_status.csv
- `PARP1_score`: CRISPR dependency score for PARP1

**This is the main dataset for statistical analysis**

**Example**:
```
StrippedCellLineName: MDAMB436
HR_status: HR-deficient
mutated_genes: BRCA1, CHEK2
PARP1_score: -0.65   # Strong PARP1 dependency
```

### 4. summary_statistics.csv

**Description**: Summary statistics by HR status

**Created by**: `02_analyze_parp1_dependency.R`

**Variables**:

| Variable | Type | Description |
|----------|------|-------------|
| `HR_status` | String | "HR-deficient" or "HR-proficient" |
| `n` | Numeric | Sample size |
| `mean_parp1_dependency` | Numeric | Mean PARP1 score |
| `median_parp1_dependency` | Numeric | Median PARP1 score |
| `sd_parp1_dependency` | Numeric | Standard deviation |
| `se_parp1_dependency` | Numeric | Standard error of mean |

**Example**:
```
HR_status: HR-deficient
n: 15
mean_parp1_dependency: -0.52
median_parp1_dependency: -0.48
sd_parp1_dependency: 0.23
se_parp1_dependency: 0.06
```

### 5. statistical_results.rds

**Description**: Complete statistical analysis results (R binary format)

**Created by**: `02_analyze_parp1_dependency.R`

**Contents** (list object):
- `summary_statistics`: Data frame of summary stats
- `t_test`: Tidy data frame from t.test() via broom::tidy()
- `linear_model_coefficients`: Model coefficients from lm()
- `linear_model_fit`: Model fit statistics (R², AIC, etc.)

**Usage**: 
```r
results <- read_rds("results/statistical_results.rds")
results$t_test  # Access t-test results
```

---

## Visualization Files (PNG)

All visualizations are saved as PNG files (300 DPI, publication quality).

### 1. parp1_dependency_violin.png

**Type**: Violin plot with overlaid points and summary statistics

**Shows**:
- Distribution shape for each group
- Individual cell lines (beeswarm points)
- Mean ± standard error (error bars)
- Quartiles (within violin)
- Dependency threshold line (-0.5)

**Best for**: Main figure in publications

### 2. parp1_dependency_boxplot.png

**Type**: Box plot with jittered points

**Shows**:
- Median (center line)
- Quartiles (box)
- Range (whiskers)
- Individual cell lines (jittered points)

**Best for**: Simple comparison

### 3. parp1_dependency_density.png

**Type**: Density curves with group means

**Shows**:
- Smoothed distribution for each group
- Mean values (dashed lines)
- Overlap between groups

**Best for**: Distribution comparison

### 4. parp1_dependency_all_lines.png

**Type**: Scatter plot of all cell lines

**Shows**:
- Each cell line as a point
- Ordered by PARP1 dependency
- Color-coded by HR status
- Dependency threshold line

**Best for**: Showing complete dataset

### 5. parp1_dependency_summary_panel.png

**Type**: Combined multi-panel figure (patchwork)

**Shows**: Violin, density, and box plot in one figure

**Best for**: Comprehensive presentation

---

## Variable Naming Conventions

### Naming Patterns

- **Snake_case**: Used for most variables (`HR_status`, `PARP1_score`)
- **PascalCase**: Used in DepMap original data (`ModelID`, `OncotreeLineage`)
- **Lower case**: Used for simple names (`n`, `mean`, `median`)

### Common Prefixes

- `mean_`: Arithmetic mean of variable
- `median_`: Median of variable
- `sd_`: Standard deviation
- `se_`: Standard error
- `n_`: Count or number

### Suffix Conventions

- `_score`: CRISPR dependency score
- `_deficient`: Boolean for deficiency status
- `_status`: Categorical status variable
- `_genes`: List or count of genes

---

## Data Types and Formats

### ModelID Format

**Pattern**: `ACH-XXXXXX` where X is a digit

**Example**: `ACH-000001`, `ACH-000456`

**Note**: ACH = "Achilles" project prefix

### Gene Column Format

**Pattern**: `GENE_SYMBOL (ENTREZ_ID)`

**Examples**: 
- `PARP1 (142)`
- `BRCA1 (672)`
- `TP53 (7157)`

### Protein Change Format

**Pattern**: `p.ORIGINAL_POS_NEW`

**Examples**:
- `p.R1443*` = Arginine at position 1443 to stop codon (truncating)
- `p.V600E` = Valine at position 600 to Glutamate (hotspot)
- `p.A1708E` = Alanine at position 1708 to Glutamate

---

## Missing Data

### Representation

- **CSV files**: Empty cell or "NA" or "NULL"
- **R**: `NA` (logical NA)
- **Statistical calculations**: Typically excluded with `na.rm = TRUE`

### Common Missing Data

| Variable | Reason for Missing |
|----------|-------------------|
| `Age` | Not recorded or patient privacy |
| `PatientRace` | Not recorded or patient privacy |
| `mutated_genes` | No HR gene mutations detected |
| Expression values | Gene not measured or filtered out |

---

## Data Quality Notes

### Cell Line Authentication

DepMap cell lines are:
- STR fingerprinted
- Mycoplasma tested
- Karyotyped
- Compared to other databases (CCLE, COSMIC)

### Mutation Calling

- Whole exome sequencing (WES)
- Aligned to hg38 reference genome
- Variants called with multiple algorithms
- Filtered for quality and coverage

### CRISPR Screening

- Genome-wide sgRNA library
- Multiple sgRNAs per gene
- Biological replicates
- CERES algorithm for deconvolution

---

## File Size Guidelines

| File | Approximate Size | Load Time |
|------|------------------|-----------|
| Model.csv | 10 MB | < 1 sec |
| CRISPRGeneEffect.csv | 500 MB | 10-30 sec |
| OmicsSomaticMutations.csv | 1.5 GB | 30-60 sec |
| OmicsExpression.csv | 800 MB | 20-40 sec |
| breast_cancer_cell_lines.csv | < 1 MB | < 1 sec |
| parp1_dependency_with_hr_status.csv | < 1 MB | < 1 sec |

---

## Data Access

### Download Links

Base URL: `https://depmap.org/portal/download/api/download/external?file_name=public_24Q2%2F`

**Files**:
1. `CRISPRGeneEffect.csv`
2. `Model.csv`
3. `OmicsSomaticMutations.csv`
4. `OmicsExpressionProteinCodingGenesTPMLogp1.csv`

**Note**: Links are automatically used by `01_download_depmap_data.R`

### Data Version

- **Release**: DepMap Public 24Q2
- **Release Date**: 2024 Quarter 2
- **DepMap Version**: 24Q2
- **Reference Genome**: hg38

---

## Tips for Working with Data

### Memory Management

For large files (CRISPRGeneEffect, Mutations):
```r
# Read only needed columns
gene_dep <- read_csv("data/CRISPRGeneEffect.csv", 
                     col_select = c("ModelID", contains("PARP1")))

# Filter early
mutations <- read_csv("data/OmicsSomaticMutations.csv") %>%
  filter(ModelID %in% breast_cancer_ids)
```

### Joining Data

Always join on `ModelID`:
```r
combined <- cell_lines %>%
  left_join(dependencies, by = "ModelID") %>%
  left_join(mutations, by = "ModelID")
```

### Gene Name Matching

Extract gene symbol from column names:
```r
# Column format: "GENE (ENTREZ_ID)"
gene_name <- str_extract(colname, "^[^\\s]+")
# Result: "PARP1"
```

---

## References

1. DepMap Portal: https://depmap.org/portal/
2. Data Downloads: https://depmap.org/portal/download/
3. DepMap Forum: https://forum.depmap.org/
4. Documentation: https://depmap.org/portal/download/

---

**Last Updated**: December 2024  
**Data Version**: DepMap Public 24Q2  
**Document Version**: 1.0
