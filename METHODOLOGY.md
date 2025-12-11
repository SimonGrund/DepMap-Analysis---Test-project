# Methodology: PARP1 Dependency Analysis in HR-Deficient Breast Cancer

This document provides a detailed explanation of the scientific methodology, data sources, and analytical approaches used in this project.

## Scientific Background

### Synthetic Lethality

**Synthetic lethality** occurs when the combination of two genetic defects leads to cell death, while either defect alone is viable. This concept is fundamental to precision cancer therapy.

### Homologous Recombination (HR) Pathway

The HR pathway is critical for:
- Repairing DNA double-strand breaks (DSBs)
- Maintaining genomic stability
- Preventing cancer development

**Key HR Genes**:
- **BRCA1/BRCA2**: Major HR proteins, frequently mutated in hereditary breast/ovarian cancer
- **PALB2**: Partners with BRCA2 for HR function
- **RAD51**: Core recombinase enzyme
- **ATM/ATR**: DNA damage response kinases

When HR is deficient, cells cannot properly repair DSBs through this high-fidelity mechanism.

### PARP1 and Alternative Repair

**PARP1 (Poly ADP-ribose polymerase 1)** is essential for:
- Base excision repair (BER)
- Single-strand break (SSB) repair
- Backup DNA repair when HR is absent

**The Synthetic Lethal Relationship**:
1. HR-deficient cells rely on PARP1 for survival
2. PARP inhibitors block this backup repair mechanism
3. HR-deficient cells accumulate unrepaired DNA damage → cell death
4. Normal cells (with functional HR) survive PARP inhibition

This creates a **therapeutic window** for selective cancer cell killing.

## Data Sources

### DepMap (Dependency Map) Project

**DepMap** is a comprehensive effort by the Broad Institute to systematically identify cancer dependencies.

**Key Features**:
- 1000+ cancer cell lines
- Genome-wide CRISPR knockout screens
- Multi-omics characterization (mutations, expression, copy number, etc.)
- Quarterly public data releases

**Website**: https://depmap.org/

### Release Used: Latest Quarterly Release

This analysis uses the most recent DepMap public release available. DepMap releases new data quarterly (e.g., 24Q2, 24Q4, 25Q1). The specific release version is defined in `01_download_depmap_data.R` and should be updated as new releases become available.

## Datasets

### 1. CRISPRGeneEffect.csv (~500MB)

**Content**: Gene dependency scores from CRISPR-Cas9 knockout screens

**Method**: 
- Genome-wide CRISPR library used to systematically knockout each gene
- Cell viability measured after knockout
- **CERES algorithm** corrects for:
  - Copy number effects (genes in amplified regions appear more essential)
  - Off-target cutting by sgRNAs
  - Batch effects

**Interpretation of Scores**:
- **Negative scores**: Gene knockout reduces cell viability (dependency)
- **Score < -0.5**: Strong dependency (gene is essential)
- **Score ≈ 0**: Non-essential gene
- **Positive scores**: Gene knockout increases viability (rare, potential tumor suppressor)

**Key Points**:
- Lower (more negative) = greater dependency
- Essential genes (e.g., ribosomal proteins) have scores around -1.0 to -1.5
- Non-essential genes cluster around 0

### 2. Model.csv (~10MB)

**Content**: Cell line metadata and annotations

**Includes**:
- Cell line identifiers (ModelID, cell line name)
- Cancer type classifications (OncotreeLineage, OncotreePrimaryDisease)
- Patient demographics (age, sex, race)
- Tissue source and culture conditions

**Usage**: Filter for breast cancer cell lines using `OncotreeLineage == "Breast"`

### 3. OmicsSomaticMutations.csv (~1.5GB)

**Content**: Somatic mutations from whole exome sequencing (WES)

**Annotations**:
- Gene symbol (HugoSymbol)
- Variant classification (missense, nonsense, frameshift, etc.)
- Variant impact (VariantInfo): damaging, truncating, hotspot, etc.
- Protein change

**Usage**: Identify cell lines with damaging mutations in HR pathway genes

**Mutation Categories of Interest**:
- **Truncating**: Frameshift, nonsense → likely loss of function
- **Damaging**: Missense mutations predicted to impair protein function
- **Hotspot**: Recurrent mutations in cancer (may be gain or loss of function)

### 4. OmicsExpressionProteinCodingGenesTPMLogp1.csv (~800MB)

**Content**: Gene expression levels from RNA-seq

**Units**: log2(TPM + 1)
- TPM = Transcripts Per Million
- Log transformation for normality

**Usage**: Optional validation that mutations correlate with expression loss

## Analytical Workflow

### Step 1: Data Download and Preparation

**Script**: `01_download_depmap_data.R`

**Actions**:
1. Download four datasets from DepMap portal
2. Load cell line metadata
3. Filter for breast cancer lineage
4. Save filtered metadata

**Output**: 
- Raw data files in `data/` directory
- `breast_cancer_cell_lines.csv`: ~60-80 breast cancer cell lines

### Step 2: HR Status Classification

**Script**: `02_analyze_parp1_dependency.R` (Part 1)

**Method**:
1. Define HR pathway genes (BRCA1, BRCA2, PALB2, RAD51, etc.)
2. Extract mutations in these genes from breast cancer cell lines
3. Filter for likely damaging mutations:
   - Truncating mutations (frameshift, nonsense)
   - Damaging missense mutations
   - Known hotspot mutations
4. Classify cell lines:
   - **HR-deficient**: Has ≥1 damaging mutation in HR genes
   - **HR-proficient**: No damaging HR mutations

**Rationale**: 
- Focus on mutations likely to impair HR function
- Single damaging hit in key HR genes (BRCA1/2) sufficient for deficiency
- Conservative approach avoids false positives

**Output**: 
- `breast_cancer_hr_status.csv`: Cell lines with HR classification
- Typically ~10-20 HR-deficient, ~50-70 HR-proficient

### Step 3: PARP1 Dependency Extraction

**Script**: `02_analyze_parp1_dependency.R` (Part 2)

**Method**:
1. Locate PARP1 column in gene dependency matrix
2. Extract PARP1 dependency scores for breast cancer cell lines
3. Join with HR status classification

**Output**: 
- `parp1_dependency_with_hr_status.csv`: Combined dataset for analysis

### Step 4: Statistical Analysis

**Script**: `02_analyze_parp1_dependency.R` (Part 3)

#### Descriptive Statistics

Calculate for each group (HR-deficient, HR-proficient):
- Mean PARP1 dependency score
- Median
- Standard deviation
- Standard error
- Sample size

#### Inferential Statistics

**A. Two-Sample T-Test**

**Hypothesis**:
- H₀: No difference in mean PARP1 dependency between groups
- H₁: HR-deficient cells have MORE NEGATIVE (more dependent) PARP1 scores

**Test**: Welch's t-test (one-tailed)
- Assumes unequal variances
- One-tailed: testing if HR-deficient < HR-proficient
- Significance level: α = 0.05

**Expected Result**: p < 0.001 (highly significant)

**B. Linear Model**

**Model**: `PARP1_score ~ HR_status`

**Purpose**:
- Estimate effect size (difference between groups)
- Calculate confidence intervals
- Assess model fit (R²)

**Interpretation**:
- Coefficient for HR_statusHR-proficient = difference in means
- Positive coefficient = HR-proficient less dependent (less negative scores)
- R² indicates proportion of variance explained

#### Effect Size

**Cohen's d** can be calculated from the t-test:
- d = (Mean₁ - Mean₂) / Pooled SD
- d > 0.8 = large effect
- Typically expect d ≈ 1.0-1.5 for this analysis

### Step 5: Visualization

**Script**: `02_analyze_parp1_dependency.R` (Part 4)

Five complementary visualizations:

**1. Violin Plot with Beeswarm**
- Shows distribution shape
- Individual cell lines visible
- Mean ± SE overlaid
- **Primary figure for publication**

**2. Box Plot**
- Traditional comparison
- Shows quartiles and outliers
- Jittered points for raw data

**3. Density Plot**
- Smooth distribution curves
- Group means marked
- Good for overlapping distributions

**4. Individual Cell Line Plot**
- Rank-ordered by PARP1 score
- Color-coded by HR status
- Shows complete dataset

**5. Combined Summary Panel**
- Multi-panel figure using patchwork
- Comprehensive view for presentations

**Color Scheme**:
- HR-deficient: Red (#E74C3C) - danger/dependency
- HR-proficient: Blue (#3498DB) - normal/control

## Tidyverse and Tidymodels Implementation

### Why Tidyverse?

**Tidyverse** is a collection of R packages designed for data science with:
- Consistent API and syntax
- Emphasis on readability
- Powerful data manipulation (dplyr)
- Elegant visualization (ggplot2)
- Pipe operator (`%>%`) for workflow clarity

### Key Packages Used

**Data Manipulation**:
- `dplyr`: filter, select, mutate, summarise, join operations
- `tidyr`: pivot, separate, nest/unnest
- `purrr`: functional programming (map functions)

**Visualization**:
- `ggplot2`: Grammar of graphics
- `ggbeeswarm`: Better point distributions than jitter
- `patchwork`: Combine multiple plots

**Statistical Modeling**:
- `broom`: Convert statistical objects to tidy data frames
  - `tidy()`: Extract coefficient tables
  - `glance()`: Model-level statistics
  - `augment()`: Add predictions/residuals

**Utilities**:
- `here`: Project-relative paths (no hardcoded paths)
- `readr`: Fast CSV reading with better defaults

### Tidy Data Principles

All data follows tidy format:
1. Each variable is a column
2. Each observation is a row
3. Each type of observational unit is a table

This enables:
- Consistent tool application
- Easy transformation and analysis
- Seamless integration with ggplot2

## Quality Control and Validation

### Data Quality Checks

1. **Completeness**: Verify all datasets downloaded successfully
2. **Sample Size**: Ensure adequate breast cancer cell lines (>50)
3. **HR Classification**: Confirm reasonable HR-deficient proportion (10-30%)
4. **Missing Data**: Check for NA values in key variables

### Biological Validation

1. **Known HR Genes**: Use established HR pathway genes from literature
2. **Mutation Impact**: Filter for likely damaging mutations
3. **Expected Direction**: HR-deficient should be MORE dependent (more negative)
4. **Effect Size**: Should be substantial (Cohen's d > 0.8)

### Statistical Assumptions

**T-Test Assumptions**:
1. **Independence**: Cell lines are independent samples ✓
2. **Normality**: Dependency scores approximately normal (CLT applies)
3. **Equal variance**: Not required (Welch's t-test)

**Linear Model Assumptions**:
1. **Linearity**: Relationship between predictor and outcome
2. **Independence**: Residuals independent
3. **Normality**: Residuals approximately normal
4. **Homoscedasticity**: Constant variance of residuals

## Expected Results

### Numerical Results

**Typical Values**:
- HR-deficient mean: -0.4 to -0.6
- HR-proficient mean: -0.1 to -0.2
- Difference: ~0.3-0.4 (substantial)
- p-value: < 0.001 (highly significant)
- R²: 0.2-0.4 (moderate to strong)

### Interpretation

**PARP1 Dependency Threshold**: -0.5
- Scores below -0.5 indicate strong dependency
- Many HR-deficient lines exceed this threshold
- Few HR-proficient lines are strongly dependent

**Clinical Relevance**:
- Validates PARP inhibitor sensitivity in HR-deficient tumors
- Supports patient stratification based on HR status
- Informs clinical trial design and patient selection

## Limitations

1. **Cell Line Models**: May not fully recapture tumor complexity
2. **Binary Classification**: HR deficiency is a spectrum, not binary
3. **Other Factors**: Copy number, methylation, other mutations may affect PARP1 dependency
4. **Sample Size**: Relatively small n for HR-deficient group
5. **2D Culture**: Lacks tumor microenvironment

## Extensions and Future Directions

1. **Additional Cancer Types**: Extend to ovarian, prostate, pancreatic cancers
2. **Multiple PARP Genes**: Analyze PARP2, PARP3
3. **Combination Dependencies**: Test synthetic lethal pairs beyond PARP1
4. **Gene Expression**: Correlate dependency with PARP1/BRCA1 expression
5. **Machine Learning**: Build predictive models of PARP inhibitor sensitivity
6. **Drug Response**: Correlate CRISPR dependency with PARP inhibitor IC50 data

## References

### DepMap

1. Tsherniak, A. et al. (2017). Defining a Cancer Dependency Map. *Cell* 170, 564-576.
2. Meyers, R.M. et al. (2017). Computational correction of copy number effect improves specificity of CRISPR-Cas9 essentiality screens in cancer cells. *Nature Genetics* 49, 1779-1784.
3. DepMap, Broad (2024). DepMap Public. *figshare*. https://depmap.org/portal/download/ (Note: Cite the specific quarterly release used)

### Synthetic Lethality and PARP Inhibition

4. Farmer, H. et al. (2005). Targeting the DNA repair defect in BRCA mutant cells as a therapeutic strategy. *Nature* 434, 917-921.
5. Bryant, H.E. et al. (2005). Specific killing of BRCA2-deficient tumours with inhibitors of poly(ADP-ribose) polymerase. *Nature* 434, 913-917.
6. Lord, C.J. & Ashworth, A. (2017). PARP inhibitors: Synthetic lethality in the clinic. *Science* 355, 1152-1158.

### Homologous Recombination

7. Moynahan, M.E. & Jasin, M. (2010). Mitotic homologous recombination maintains genomic stability and suppresses tumorigenesis. *Nature Reviews Molecular Cell Biology* 11, 196-207.
8. Roy, R., Chun, J. & Powell, S.N. (2012). BRCA1 and BRCA2: different roles in a common pathway of genome protection. *Nature Reviews Cancer* 12, 68-78.

### Tidyverse

9. Wickham, H. et al. (2019). Welcome to the Tidyverse. *Journal of Open Source Software* 4(43), 1686.
10. Kuhn, M. & Wickham, H. (2020). Tidymodels: a collection of packages for modeling and machine learning using tidyverse principles. https://www.tidymodels.org

---

**Document Version**: 1.1  
**Last Updated**: December 2024  
**Corresponding Data Release**: DepMap Public (quarterly releases)
