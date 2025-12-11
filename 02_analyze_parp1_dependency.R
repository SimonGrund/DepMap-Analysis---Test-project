# DepMap Analysis: PARP1 Dependency in HR-Deficient Breast Cancer Cell Lines
# This script analyzes the relationship between HR deficiency and PARP1 dependency

# Load required packages
library(tidyverse)
library(here)
library(tidymodels)
library(broom)
library(ggbeeswarm)
library(patchwork)

# Create results directory
if (!dir.exists(here("results"))) {
  dir.create(here("results"), recursive = TRUE)
}

# Set theme for all plots
theme_set(theme_minimal(base_size = 12))

message("=== Loading DepMap Data ===")

# Load breast cancer cell line metadata
breast_lines <- read_csv(
  here("data", "breast_cancer_cell_lines.csv"),
  show_col_types = FALSE
)

message(sprintf("Loaded %d breast cancer cell lines", nrow(breast_lines)))

# Load CRISPR gene dependency scores
message("Loading gene dependency data (this may take a moment)...")
gene_dependency <- read_csv(
  here("data", "CRISPRGeneEffect.csv"),
  show_col_types = FALSE
)

# Load mutation data
message("Loading mutation data (this may take a moment)...")
mutations <- read_csv(
  here("data", "OmicsSomaticMutations.csv"),
  show_col_types = FALSE
)

message("✓ All data loaded successfully")
message("")

# ===== Identify HR-Deficient Cell Lines =====
message("=== Identifying HR-Deficient Cell Lines ===")

# Key HR pathway genes
hr_genes <- c("BRCA1", "BRCA2", "PALB2", "RAD51", "RAD51C", "RAD51D", 
              "BRIP1", "BARD1", "ATM", "ATR", "CHEK1", "CHEK2")

# Filter for breast cancer cell lines and HR gene mutations
breast_line_ids <- breast_lines %>% pull(ModelID)

hr_mutations <- mutations %>%
  filter(
    ModelID %in% breast_line_ids,
    HugoSymbol %in% hr_genes,
    # Focus on likely damaging mutations
    VariantInfo %in% c("damaging", "other non-conserving", "hotspot") |
    str_detect(VariantInfo, "truncating")
  ) %>%
  select(ModelID, HugoSymbol, VariantInfo, ProteinChange) %>%
  distinct()

message(sprintf("Found %d HR gene mutations in %d breast cancer cell lines",
                nrow(hr_mutations),
                n_distinct(hr_mutations$ModelID)))

# Classify cell lines by HR status
cell_line_hr_status <- breast_lines %>%
  mutate(
    HR_deficient = ModelID %in% hr_mutations$ModelID,
    HR_status = if_else(HR_deficient, "HR-deficient", "HR-proficient")
  ) %>%
  left_join(
    hr_mutations %>%
      group_by(ModelID) %>%
      summarise(
        mutated_genes = str_c(unique(HugoSymbol), collapse = ", "),
        .groups = "drop"
      ),
    by = "ModelID"
  )

message(sprintf("Classification: %d HR-deficient, %d HR-proficient",
                sum(cell_line_hr_status$HR_deficient),
                sum(!cell_line_hr_status$HR_deficient)))

# Save HR status classification
write_csv(
  cell_line_hr_status,
  here("results", "breast_cancer_hr_status.csv")
)

message("")

# ===== Extract PARP1 Dependency Scores =====
message("=== Extracting PARP1 Dependency Scores ===")

# Find PARP1 column (format is "PARP1 (142)")
parp1_col <- names(gene_dependency)[str_detect(names(gene_dependency), "PARP1")]

if (length(parp1_col) == 0) {
  stop("Error: PARP1 gene not found in dependency data")
}

message(sprintf("Found PARP1 column: %s", parp1_col))

# Extract PARP1 dependency scores for breast cancer lines
parp1_dependency <- gene_dependency %>%
  select(ModelID, PARP1_score = all_of(parp1_col)) %>%
  filter(ModelID %in% breast_line_ids) %>%
  inner_join(cell_line_hr_status, by = "ModelID")

message(sprintf("Retrieved PARP1 scores for %d breast cancer cell lines", 
                nrow(parp1_dependency)))

# Save combined data
write_csv(
  parp1_dependency,
  here("results", "parp1_dependency_with_hr_status.csv")
)

message("")

# ===== Statistical Analysis =====
message("=== Statistical Analysis ===")

# Summary statistics by HR status
summary_stats <- parp1_dependency %>%
  group_by(HR_status) %>%
  summarise(
    n = n(),
    mean_parp1_dependency = mean(PARP1_score, na.rm = TRUE),
    median_parp1_dependency = median(PARP1_score, na.rm = TRUE),
    sd_parp1_dependency = sd(PARP1_score, na.rm = TRUE),
    se_parp1_dependency = sd_parp1_dependency / sqrt(n),
    .groups = "drop"
  )

print(summary_stats)

# T-test: HR-deficient vs HR-proficient
t_test_result <- t.test(
  PARP1_score ~ HR_status,
  data = parp1_dependency,
  alternative = "less"  # HR-deficient should have MORE negative scores (more dependent)
)

message("\n=== T-Test Results ===")
message(sprintf("t-statistic: %.3f", t_test_result$statistic))
message(sprintf("p-value: %.2e", t_test_result$p.value))
message(sprintf("95%% CI: [%.3f, %.3f]", 
                t_test_result$conf.int[1], 
                t_test_result$conf.int[2]))

if (t_test_result$p.value < 0.001) {
  message("*** Highly significant difference (p < 0.001)")
} else if (t_test_result$p.value < 0.05) {
  message("** Significant difference (p < 0.05)")
} else {
  message("No significant difference")
}

# Linear model for effect size
lm_model <- lm(PARP1_score ~ HR_status, data = parp1_dependency)
lm_summary <- tidy(lm_model, conf.int = TRUE)
lm_glance <- glance(lm_model)

message("\n=== Linear Model Summary ===")
print(lm_summary)
message(sprintf("R-squared: %.3f", lm_glance$r.squared))
message(sprintf("Adjusted R-squared: %.3f", lm_glance$adj.r.squared))

# Save statistical results
stat_results <- list(
  summary_statistics = summary_stats,
  t_test = broom::tidy(t_test_result),
  linear_model_coefficients = lm_summary,
  linear_model_fit = lm_glance
)

write_rds(stat_results, here("results", "statistical_results.rds"))
write_csv(summary_stats, here("results", "summary_statistics.csv"))

message("")

# ===== Visualizations =====
message("=== Creating Visualizations ===")

# 1. Violin plot with individual points
p1 <- ggplot(parp1_dependency, aes(x = HR_status, y = PARP1_score, fill = HR_status)) +
  geom_violin(alpha = 0.5, draw_quantiles = c(0.25, 0.5, 0.75)) +
  geom_beeswarm(alpha = 0.6, size = 2) +
  stat_summary(fun.data = mean_se, geom = "pointrange", color = "black", size = 0.8) +
  scale_fill_manual(values = c("HR-deficient" = "#E74C3C", "HR-proficient" = "#3498DB")) +
  labs(
    title = "PARP1 Dependency in Breast Cancer Cell Lines",
    subtitle = sprintf("HR-deficient cells show significantly greater PARP1 dependency (p = %.2e)", 
                       t_test_result$p.value),
    x = "HR Status",
    y = "PARP1 Dependency Score (CERES)",
    caption = "More negative = greater dependency. Points show individual cell lines.\nError bars show mean ± SE."
  ) +
  theme(legend.position = "none") +
  geom_hline(yintercept = -0.5, linetype = "dashed", color = "gray50", alpha = 0.5) +
  annotate("text", x = 1.5, y = -0.5, label = "Dependency threshold", 
           vjust = -0.5, size = 3, color = "gray40")

ggsave(here("results", "parp1_dependency_violin.png"), p1, 
       width = 8, height = 6, dpi = 300)
message("✓ Saved: parp1_dependency_violin.png")

# 2. Box plot comparison
p2 <- ggplot(parp1_dependency, aes(x = HR_status, y = PARP1_score, fill = HR_status)) +
  geom_boxplot(alpha = 0.7, outlier.shape = NA) +
  geom_jitter(width = 0.2, alpha = 0.5, size = 2) +
  scale_fill_manual(values = c("HR-deficient" = "#E74C3C", "HR-proficient" = "#3498DB")) +
  labs(
    title = "PARP1 Dependency by HR Status",
    x = "HR Status",
    y = "PARP1 Dependency Score (CERES)"
  ) +
  theme(legend.position = "none")

ggsave(here("results", "parp1_dependency_boxplot.png"), p2, 
       width = 7, height = 5, dpi = 300)
message("✓ Saved: parp1_dependency_boxplot.png")

# 3. Density plot
p3 <- ggplot(parp1_dependency, aes(x = PARP1_score, fill = HR_status)) +
  geom_density(alpha = 0.6) +
  geom_vline(data = summary_stats, aes(xintercept = mean_parp1_dependency, color = HR_status),
             linetype = "dashed", size = 1) +
  scale_fill_manual(values = c("HR-deficient" = "#E74C3C", "HR-proficient" = "#3498DB")) +
  scale_color_manual(values = c("HR-deficient" = "#E74C3C", "HR-proficient" = "#3498DB")) +
  labs(
    title = "Distribution of PARP1 Dependency Scores",
    subtitle = "Dashed lines show group means",
    x = "PARP1 Dependency Score (CERES)",
    y = "Density",
    fill = "HR Status",
    color = "HR Status"
  )

ggsave(here("results", "parp1_dependency_density.png"), p3, 
       width = 8, height = 5, dpi = 300)
message("✓ Saved: parp1_dependency_density.png")

# 4. Individual cell line plot with labels for HR-deficient
hr_deficient_lines <- parp1_dependency %>%
  filter(HR_deficient) %>%
  arrange(PARP1_score) %>%
  mutate(rank = row_number())

p4 <- ggplot(parp1_dependency, aes(x = reorder(StrippedCellLineName, PARP1_score), 
                                    y = PARP1_score, color = HR_status)) +
  geom_point(size = 3, alpha = 0.7) +
  geom_hline(yintercept = -0.5, linetype = "dashed", color = "gray50") +
  scale_color_manual(values = c("HR-deficient" = "#E74C3C", "HR-proficient" = "#3498DB")) +
  labs(
    title = "PARP1 Dependency Across Breast Cancer Cell Lines",
    subtitle = "Each point represents a cell line, ordered by PARP1 dependency",
    x = "Cell Line",
    y = "PARP1 Dependency Score (CERES)",
    color = "HR Status"
  ) +
  theme(
    axis.text.x = element_blank(),
    axis.ticks.x = element_blank()
  )

ggsave(here("results", "parp1_dependency_all_lines.png"), p4, 
       width = 10, height = 6, dpi = 300)
message("✓ Saved: parp1_dependency_all_lines.png")

# 5. Combined summary panel
p_combined <- (p1 | p3) / p2 +
  plot_annotation(
    title = "PARP1 Dependency in HR-Deficient vs HR-Proficient Breast Cancer",
    subtitle = sprintf("Analysis of %d breast cancer cell lines from DepMap", nrow(parp1_dependency)),
    theme = theme(plot.title = element_text(size = 16, face = "bold"))
  )

ggsave(here("results", "parp1_dependency_summary_panel.png"), p_combined, 
       width = 14, height = 10, dpi = 300)
message("✓ Saved: parp1_dependency_summary_panel.png")

message("")

# ===== Final Summary Report =====
message("=== Analysis Complete ===")
message("")
message("KEY FINDINGS:")
message(sprintf("• %d breast cancer cell lines analyzed", nrow(parp1_dependency)))
message(sprintf("• %d HR-deficient cell lines (mutated genes: BRCA1/2, PALB2, etc.)", 
                sum(parp1_dependency$HR_deficient)))
message(sprintf("• %d HR-proficient cell lines", sum(!parp1_dependency$HR_deficient)))
message("")
message(sprintf("• Mean PARP1 dependency (HR-deficient): %.3f", 
                summary_stats$mean_parp1_dependency[summary_stats$HR_status == "HR-deficient"]))
message(sprintf("• Mean PARP1 dependency (HR-proficient): %.3f", 
                summary_stats$mean_parp1_dependency[summary_stats$HR_status == "HR-proficient"]))
message("")
message(sprintf("• Statistical significance: p = %.2e", t_test_result$p.value))
message(sprintf("• Effect size (difference in means): %.3f", 
                abs(diff(summary_stats$mean_parp1_dependency))))
message("")

if (t_test_result$p.value < 0.05) {
  message("✓ CONCLUSION: HR-deficient breast cancer cell lines show SIGNIFICANTLY")
  message("  greater dependency on PARP1 for survival compared to HR-proficient lines.")
  message("  This supports the use of PARP inhibitors in HR-deficient breast cancers.")
} else {
  message("✗ CONCLUSION: No significant difference in PARP1 dependency between")
  message("  HR-deficient and HR-proficient breast cancer cell lines.")
}

message("")
message("All results saved to:", here("results"))
message("• Data files: CSV format")
message("• Visualizations: PNG format")
message("• Statistical results: RDS format")
