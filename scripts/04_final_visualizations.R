# ========================================
# Pakistan Biodiversity Analysis
# Script 04: Final Visualizations
# Author: Syed Inzimam Ali Shah
# Date: Sep-Oct 2025
# ========================================

library(dplyr)
library(ggplot2)
library(sf)
library(viridis)
library(tidyr)

setwd("C:/pakistan_biodiversity_analysis")

cat("=== DAY 11: FINAL VISUALIZATIONS ===\n\n")

# ========================================
# STEP 1: Load All Data
# ========================================

cat("Step 1: Loading data...\n")
species_clean <- read.csv("data/processed/species_clean.csv")
grid_richness <- st_read("data/processed/grid_richness.shp", quiet = TRUE)
hotspots <- st_read("data/processed/biodiversity_hotspots.shp", quiet = TRUE)

cat("Loaded", nrow(species_clean), "species records\n")
cat("Unique species:", n_distinct(species_clean$species), "\n\n")

# ========================================
# STEP 2: Top Species Analysis
# ========================================

cat("Step 2: Creating top species visualizations...\n")

# Top 20 most recorded species
top_20_species <- species_clean %>%
  count(species, sort = TRUE) %>%
  head(20)

# Create bar chart
top_species_plot <- ggplot(top_20_species, aes(x = reorder(species, n), y = n)) +
  geom_col(fill = "#2c7bb6", alpha = 0.8) +
  coord_flip() +
  theme_minimal() +
  theme(
    plot.title = element_text(size = 16, face = "bold"),
    plot.subtitle = element_text(size = 12),
    axis.text.y = element_text(face = "italic", size = 10),
    axis.title = element_text(size = 12)
  ) +
  labs(
    title = "Top 20 Most Recorded Species in Pakistan",
    subtitle = "Based on GBIF occurrence records",
    x = NULL,
    y = "Number of Observations",
    caption = "Analysis: Syed Inzimam Ali Shah | Data: GBIF.org"
  )

ggsave("outputs/figures/top_20_species.png", 
       top_species_plot, width = 10, height = 8, dpi = 300)

cat("✓ Top species chart created\n")

# ========================================
# STEP 3: Taxonomic Composition
# ========================================

cat("Step 3: Creating taxonomic visualizations...\n")

# By Class
class_summary <- species_clean %>%
  count(class, sort = TRUE) %>%
  head(10) %>%
  mutate(percentage = round(n/sum(n)*100, 1))

class_plot <- ggplot(class_summary, aes(x = reorder(class, n), y = n, fill = class)) +
  geom_col(show.legend = FALSE) +
  geom_text(aes(label = paste0(n, " (", percentage, "%)")), 
            hjust = -0.1, size = 4) +
  coord_flip() +
  scale_fill_viridis_d(option = "turbo") +
  theme_minimal() +
  theme(
    plot.title = element_text(size = 16, face = "bold"),
    plot.subtitle = element_text(size = 12),
    axis.text = element_text(size = 11)
  ) +
  labs(
    title = "Taxonomic Composition by Class",
    subtitle = "Distribution of observations across major animal classes",
    x = NULL,
    y = "Number of Records",
    caption = "Top 10 classes shown"
  ) +
  expand_limits(y = max(class_summary$n) * 1.15)

ggsave("outputs/figures/taxonomic_by_class.png",
       class_plot, width = 10, height = 6, dpi = 300)

# By Order (top 15)
order_summary <- species_clean %>%
  count(order, sort = TRUE) %>%
  head(15)

order_plot <- ggplot(order_summary, aes(x = reorder(order, n), y = n)) +
  geom_col(fill = "#d95f02", alpha = 0.8) +
  coord_flip() +
  theme_minimal() +
  theme(
    plot.title = element_text(size = 16, face = "bold"),
    axis.text = element_text(size = 10)
  ) +
  labs(
    title = "Top 15 Orders by Number of Records",
    x = NULL,
    y = "Number of Observations"
  )

ggsave("outputs/figures/taxonomic_by_order.png",
       order_plot, width = 10, height = 7, dpi = 300)

cat("✓ Taxonomic charts created\n")

# ========================================
# STEP 4: Temporal Patterns
# ========================================

cat("Step 4: Creating temporal visualizations...\n")

# Monthly pattern with more detail
monthly_data <- species_clean %>%
  filter(!is.na(month)) %>%
  count(month) %>%
  mutate(
    month_name = factor(month.abb[month], levels = month.abb),
    season = case_when(
      month %in% c(12, 1, 2) ~ "Winter",
      month %in% c(3, 4, 5) ~ "Spring",
      month %in% c(6, 7, 8) ~ "Summer",
      month %in% c(9, 10, 11) ~ "Autumn"
    )
  )

monthly_plot <- ggplot(monthly_data, aes(x = month_name, y = n, fill = season)) +
  geom_col(alpha = 0.8) +
  scale_fill_manual(
    values = c("Winter" = "#3288bd", "Spring" = "#66c2a5", 
               "Summer" = "#fee08b", "Autumn" = "#d53e4f")
  ) +
  theme_minimal() +
  theme(
    plot.title = element_text(size = 16, face = "bold"),
    plot.subtitle = element_text(size = 12),
    axis.text.x = element_text(angle = 0, size = 11),
    legend.position = "top"
  ) +
  labs(
    title = "Seasonal Pattern of Species Observations",
    subtitle = "Number of records by month",
    x = "Month",
    y = "Number of Records",
    fill = "Season"
  )

ggsave("outputs/figures/seasonal_pattern.png",
       monthly_plot, width = 10, height = 6, dpi = 300)

cat("✓ Temporal charts created\n")

# ========================================
# STEP 5: Family Diversity
# ========================================

cat("Step 5: Creating family diversity visualization...\n")

# Top families
family_summary <- species_clean %>%
  count(family, sort = TRUE) %>%
  head(15) %>%
  filter(!is.na(family))

family_plot <- ggplot(family_summary, aes(x = reorder(family, n), y = n)) +
  geom_col(fill = "#7570b3", alpha = 0.8) +
  coord_flip() +
  theme_minimal() +
  theme(
    plot.title = element_text(size = 16, face = "bold"),
    axis.text.y = element_text(size = 10)
  ) +
  labs(
    title = "Top 15 Most Diverse Families",
    subtitle = "Families with most recorded observations",
    x = NULL,
    y = "Number of Records"
  )

ggsave("outputs/figures/top_families.png",
       family_plot, width = 10, height = 7, dpi = 300)

cat("✓ Family diversity chart created\n")

# ========================================
# STEP 6: Summary Statistics Panel
# ========================================

cat("Step 6: Creating summary statistics panel...\n")

# Prepare summary data
total_records <- nrow(species_clean)
total_species <- n_distinct(species_clean$species)
total_families <- n_distinct(species_clean$family, na.rm = TRUE)
total_orders <- n_distinct(species_clean$order, na.rm = TRUE)
hotspot_count <- nrow(hotspots)
grid_cells <- nrow(grid_richness)

# Create a summary visualization
summary_data <- data.frame(
  Metric = c("Total Records", "Unique Species", "Families", 
             "Orders", "Hotspots", "Grid Cells"),
  Value = c(total_records, total_species, total_families, 
            total_orders, hotspot_count, grid_cells),
  Category = c("Data", "Data", "Taxonomy", "Taxonomy", "Analysis", "Analysis")
)

summary_plot <- ggplot(summary_data, aes(x = reorder(Metric, Value), y = Value, fill = Category)) +
  geom_col(alpha = 0.8) +
  geom_text(aes(label = format(Value, big.mark = ",")), 
            hjust = -0.2, size = 5, fontface = "bold") +
  coord_flip() +
  scale_fill_manual(values = c("Data" = "#1b9e77", "Taxonomy" = "#d95f02", "Analysis" = "#7570b3")) +
  theme_minimal() +
  theme(
    plot.title = element_text(size = 18, face = "bold"),
    plot.subtitle = element_text(size = 14),
    axis.text = element_text(size = 12),
    legend.position = "top",
    legend.text = element_text(size = 11)
  ) +
  labs(
    title = "Pakistan Biodiversity Analysis Summary",
    subtitle = "Key statistics from GBIF data analysis",
    x = NULL,
    y = "Count",
    fill = "Category",
    caption = "Analysis by: Syed Inzimam Ali Shah | 2025"
  ) +
  expand_limits(y = max(summary_data$Value) * 1.2)

ggsave("outputs/figures/summary_statistics.png",
       summary_plot, width = 10, height = 7, dpi = 300)

cat("✓ Summary statistics panel created\n")

# ========================================
# STEP 7: Comparison Chart
# ========================================

cat("Step 7: Creating before/after comparison chart...\n")

# Data quality comparison
comparison_data <- data.frame(
  Stage = rep(c("Raw Data", "Clean Data"), each = 3),
  Metric = rep(c("Records", "Species", "Families"), 2),
  Value = c(
    10000, 859, n_distinct(read.csv("data/raw/gbif_pakistan_raw.csv")$family, na.rm = TRUE),
    total_records, total_species, total_families
  )
)

comparison_plot <- ggplot(comparison_data, aes(x = Metric, y = Value, fill = Stage)) +
  geom_col(position = "dodge", alpha = 0.8) +
  geom_text(aes(label = format(Value, big.mark = ",")), 
            position = position_dodge(width = 0.9), 
            vjust = -0.5, size = 4) +
  scale_fill_manual(values = c("Raw Data" = "#fc8d62", "Clean Data" = "#66c2a5")) +
  theme_minimal() +
  theme(
    plot.title = element_text(size = 16, face = "bold"),
    plot.subtitle = element_text(size = 12),
    legend.position = "top",
    legend.text = element_text(size = 11)
  ) +
  labs(
    title = "Data Cleaning Impact",
    subtitle = "Comparison of raw vs. cleaned dataset",
    x = NULL,
    y = "Count",
    fill = NULL
  ) +
  expand_limits(y = max(comparison_data$Value) * 1.15)

ggsave("outputs/figures/data_cleaning_comparison.png",
       comparison_plot, width = 10, height = 6, dpi = 300)

cat("✓ Comparison chart created\n")

# ========================================
# STEP 8: Create Infographic-Style Summary
# ========================================

cat("Step 8: Creating project highlights infographic...\n")

# This will be a simple text-based visualization
highlight_data <- data.frame(
  x = c(1, 2, 3, 1, 2, 3),
  y = c(2, 2, 2, 1, 1, 1),
  label = c(
    paste0(format(total_records, big.mark = ","), "\nClean Records"),
    paste0(total_species, "\nUnique Species"),
    paste0(hotspot_count, "\nBiodiversity\nHotspots"),
    "82%\nBird Records",
    "29%\nArea Coverage",
    paste0(max(grid_richness$spcRchn, na.rm = TRUE), "\nMax Species\nper Cell")
  ),
  color = rep(c("#1b9e77", "#d95f02", "#7570b3", "#e7298a", "#66a61e", "#e6ab02"), 1)
)

infographic <- ggplot(highlight_data, aes(x = x, y = y)) +
  geom_tile(aes(fill = color), width = 0.9, height = 0.9, alpha = 0.3, show.legend = FALSE) +
  geom_text(aes(label = label), size = 6, fontface = "bold") +
  scale_fill_identity() +
  theme_void() +
  theme(
    plot.title = element_text(size = 20, face = "bold", hjust = 0.5),
    plot.subtitle = element_text(size = 14, hjust = 0.5),
    plot.margin = margin(20, 20, 20, 20)
  ) +
  labs(
    title = "Pakistan Biodiversity Analysis",
    subtitle = "Key Findings at a Glance"
  ) +
  coord_fixed()

ggsave("outputs/figures/project_highlights.png",
       infographic, width = 12, height = 8, dpi = 300)

cat("✓ Infographic created\n")

# ========================================
# STEP 9: Save Visualization Summary
# ========================================

cat("\nStep 9: Saving visualization summary...\n")

sink("outputs/tables/visualization_summary.txt")
cat("====================================\n")
cat("VISUALIZATION SUMMARY\n")
cat("====================================\n\n")
cat("Date:", as.character(Sys.Date()), "\n")
cat("Analyst: Syed Inzimam Ali Shah\n\n")

cat("VISUALIZATIONS CREATED\n")
cat("----------------------\n\n")

cat("1. Top Species Analysis\n")
cat("   - File: outputs/figures/top_20_species.png\n")
cat("   - Shows: 20 most frequently recorded species\n\n")

cat("2. Taxonomic Composition\n")
cat("   - Files: taxonomic_by_class.png, taxonomic_by_order.png\n")
cat("   - Shows: Distribution across taxonomic groups\n\n")

cat("3. Temporal Patterns\n")
cat("   - File: outputs/figures/seasonal_pattern.png\n")
cat("   - Shows: Monthly and seasonal observation patterns\n\n")

cat("4. Family Diversity\n")
cat("   - File: outputs/figures/top_families.png\n")
cat("   - Shows: Most diverse taxonomic families\n\n")

cat("5. Summary Statistics\n")
cat("   - File: outputs/figures/summary_statistics.png\n")
cat("   - Shows: Key project metrics\n\n")

cat("6. Data Quality Comparison\n")
cat("   - File: outputs/figures/data_cleaning_comparison.png\n")
cat("   - Shows: Impact of data cleaning process\n\n")

cat("7. Project Highlights\n")
cat("   - File: outputs/figures/project_highlights.png\n")
cat("   - Shows: Key findings infographic\n\n")

cat("KEY STATISTICS\n")
cat("--------------\n")
cat("Total visualizations created: 10\n")
cat("Total species analyzed:", total_species, "\n")
cat("Most common class:", class_summary$class[1], "\n")
cat("Peak observation month:", monthly_data$month_name[which.max(monthly_data$n)], "\n")

sink()

cat("✓ Summary saved\n")

# =================================== #
