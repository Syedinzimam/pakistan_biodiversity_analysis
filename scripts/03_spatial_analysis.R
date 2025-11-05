# ========================================
# Pakistan Biodiversity Analysis
# Script 03: Spatial Analysis
# Author: Syed Inzimam Ali Shah
# Date: 2025
# ========================================

library(sf)
library(dplyr)
library(ggplot2)
library(viridis)

setwd("C:/pakistan-biodiversity-analysis")

cat("=== DAY 7: SPATIAL ANALYSIS ===\n\n")

# ========================================
# STEP 1: Load Cleaned Data
# ========================================

cat("Step 1: Loading cleaned data...\n")
species_sf <- st_read("data/processed/species_occurrences_clean.shp", quiet = TRUE)
pakistan <- st_read("data/processed/pakistan_boundary.shp", quiet = TRUE)

cat("Loaded", nrow(species_sf), "clean species records\n")
cat("Unique species:", n_distinct(species_sf$species), "\n\n")

# ========================================
# STEP 2: Create Analysis Grid
# ========================================

cat("Step 2: Creating spatial grid over Pakistan...\n")

# Create a 0.5 degree grid (approximately 50km x 50km cells)
grid <- st_make_grid(
  pakistan,
  cellsize = 0.5,  # 0.5 degree cells
  what = "polygons"
) %>%
  st_sf() %>%
  mutate(cell_id = row_number())

cat("Created", nrow(grid), "initial grid cells\n")

# Keep only grid cells that intersect with Pakistan
grid_pakistan <- st_intersection(grid, pakistan)

cat("Grid cells within Pakistan:", nrow(grid_pakistan), "\n\n")

# ========================================
# STEP 3: Calculate Species Richness
# ========================================

cat("Step 3: Calculating species richness per grid cell...\n")

# Join species points with grid
species_grid <- st_join(species_sf, grid_pakistan)

# Calculate richness metrics for each cell
richness_data <- species_grid %>%
  st_drop_geometry() %>%
  group_by(cell_id) %>%
  summarise(
    species_richness = n_distinct(species),
    total_records = n(),
    n_families = n_distinct(family),
    n_genera = n_distinct(genus),
    n_orders = n_distinct(order)
  )

cat("Calculated richness for", nrow(richness_data), "grid cells with data\n")

# Join back to grid
grid_richness <- grid_pakistan %>%
  left_join(richness_data, by = "cell_id") %>%
  mutate(
    species_richness = ifelse(is.na(species_richness), 0, species_richness),
    total_records = ifelse(is.na(total_records), 0, total_records),
    n_families = ifelse(is.na(n_families), 0, n_families),
    n_genera = ifelse(is.na(n_genera), 0, n_genera),
    n_orders = ifelse(is.na(n_orders), 0, n_orders)
  )

# Summary statistics
cat("\n=== SPECIES RICHNESS STATISTICS ===\n")
cat("Mean species per cell:", round(mean(grid_richness$species_richness), 2), "\n")
cat("Median species per cell:", median(grid_richness$species_richness), "\n")
cat("Maximum species in a cell:", max(grid_richness$species_richness), "\n")
cat("Minimum species in a cell:", min(grid_richness$species_richness), "\n")
cat("Standard deviation:", round(sd(grid_richness$species_richness), 2), "\n\n")

# ========================================
# STEP 4: Identify Biodiversity Hotspots
# ========================================

cat("Step 4: Identifying biodiversity hotspots...\n")

# Define hotspots as top 10% in species richness
richness_threshold <- quantile(grid_richness$species_richness[grid_richness$species_richness > 0], 0.90)

hotspots <- grid_richness %>%
  filter(species_richness >= richness_threshold) %>%
  arrange(desc(species_richness))

cat("Hotspot threshold:", round(richness_threshold, 0), "species per cell\n")
cat("Number of hotspot cells:", nrow(hotspots), "\n")
cat("Hotspots contain", sum(hotspots$species_richness), "total species observations\n\n")

# Top 5 richest cells
cat("Top 5 richest cells:\n")
top_cells <- grid_richness %>%
  arrange(desc(species_richness)) %>%
  head(5) %>%
  st_drop_geometry() %>%
  select(cell_id, species_richness, total_records, n_families)
print(top_cells)

# ========================================
# STEP 5: Calculate Sampling Effort
# ========================================

cat("\nStep 5: Analyzing sampling effort...\n")

# Categorize sampling effort
grid_richness <- grid_richness %>%
  mutate(
    sampling_effort = case_when(
      total_records == 0 ~ "Unsampled",
      total_records < 10 ~ "Low",
      total_records < 50 ~ "Medium",
      total_records < 200 ~ "High",
      TRUE ~ "Very High"
    ),
    sampling_effort = factor(sampling_effort, 
                             levels = c("Unsampled", "Low", "Medium", "High", "Very High"))
  )

# Summary of sampling effort
effort_summary <- grid_richness %>%
  st_drop_geometry() %>%
  count(sampling_effort)

cat("\nSampling effort distribution:\n")
print(effort_summary)

# Calculate coverage
total_cells <- nrow(grid_richness)
sampled_cells <- sum(grid_richness$total_records > 0)
cat("\nSpatial coverage:", round(sampled_cells/total_cells*100, 1), "% of Pakistan grid cells have data\n\n")

# ========================================
# STEP 6: Save Analysis Results
# ========================================

cat("Step 6: Saving analysis results...\n")

# Save richness grid
st_write(grid_richness, 
         "data/processed/grid_richness.shp",
         delete_dsn = TRUE, quiet = TRUE)

# Save hotspots
st_write(hotspots,
         "data/processed/biodiversity_hotspots.shp",
         delete_dsn = TRUE, quiet = TRUE)

# Save summary tables
richness_summary <- grid_richness %>%
  st_drop_geometry() %>%
  select(cell_id, species_richness, total_records, n_families, n_genera, n_orders, sampling_effort)

write.csv(richness_summary,
          "outputs/tables/grid_richness_summary.csv",
          row.names = FALSE)

hotspot_summary <- hotspots %>%
  st_drop_geometry() %>%
  select(cell_id, species_richness, total_records, n_families, n_genera)

write.csv(hotspot_summary,
          "outputs/tables/hotspot_summary.csv",
          row.names = FALSE)

cat("✓ Grid richness saved: data/processed/grid_richness.shp\n")
cat("✓ Hotspots saved: data/processed/biodiversity_hotspots.shp\n")
cat("✓ Summary tables saved to outputs/tables/\n\n")

# ========================================
# STEP 7: Create Visualizations
# ========================================

cat("Step 7: Creating spatial visualizations...\n\n")

# Visualization 1: Species Richness Heatmap
cat("  → Creating species richness heatmap...\n")

richness_map <- ggplot() +
  geom_sf(data = pakistan, fill = "gray95", color = "black", size = 0.3) +
  geom_sf(data = grid_richness, 
          aes(fill = species_richness),
          color = NA, alpha = 0.8) +
  scale_fill_viridis(
    name = "Species\nRichness",
    option = "plasma",
    na.value = "gray90",
    breaks = seq(0, max(grid_richness$species_richness), by = 50)
  ) +
  theme_minimal() +
  theme(
    plot.title = element_text(size = 16, face = "bold"),
    plot.subtitle = element_text(size = 12),
    legend.position = "right",
    panel.grid = element_blank(),
    axis.text = element_text(size = 8)
  ) +
  labs(
    title = "Biodiversity Patterns Across Pakistan",
    subtitle = paste("Species richness per", "0.5° grid cell |", 
                     n_distinct(species_sf$species), "total species"),
    caption = "Data source: GBIF.org | Analysis: Syed Inzimam Ali Shah"
  )

ggsave("outputs/maps/species_richness_heatmap.png",
       richness_map, width = 10, height = 12, dpi = 300)

# Visualization 2: Biodiversity Hotspots
cat("  → Creating hotspot map...\n")

hotspot_map <- ggplot() +
  geom_sf(data = pakistan, fill = "gray95", color = "black") +
  geom_sf(data = grid_richness, fill = "lightblue", alpha = 0.3, color = NA) +
  geom_sf(data = hotspots, aes(fill = species_richness), 
          color = "darkred", size = 0.5) +
  scale_fill_gradient(
    name = "Species\nRichness",
    low = "orange",
    high = "darkred"
  ) +
  theme_minimal() +
  theme(
    plot.title = element_text(size = 16, face = "bold"),
    plot.subtitle = element_text(size = 12),
    legend.position = "right",
    panel.grid = element_blank()
  ) +
  labs(
    title = "Biodiversity Hotspots in Pakistan",
    subtitle = paste("Top 10% areas by species richness |", nrow(hotspots), "hotspot cells"),
    caption = "Hotspots shown in red-orange gradient"
  )

ggsave("outputs/maps/biodiversity_hotspots_map.png",
       hotspot_map, width = 10, height = 12, dpi = 300)

# Visualization 3: Sampling Effort
cat("  → Creating sampling effort map...\n")

sampling_map <- ggplot() +
  geom_sf(data = pakistan, fill = "white", color = "black") +
  geom_sf(data = grid_richness,
          aes(fill = sampling_effort),
          color = "white", size = 0.1) +
  scale_fill_manual(
    values = c("Unsampled" = "gray90",
               "Low" = "#fee5d9",
               "Medium" = "#fcae91",
               "High" = "#fb6a4a",
               "Very High" = "#a50f15"),
    name = "Sampling\nEffort",
    drop = FALSE
  ) +
  theme_minimal() +
  theme(
    plot.title = element_text(size = 16, face = "bold"),
    plot.subtitle = element_text(size = 12),
    legend.position = "right",
    panel.grid = element_blank()
  ) +
  labs(
    title = "Data Collection Effort Across Pakistan",
    subtitle = paste(round(sampled_cells/total_cells*100, 1), 
                     "% of grid cells have observations"),
    caption = "Highlights data gaps and well-studied areas"
  )

ggsave("outputs/maps/sampling_effort_map.png",
       sampling_map, width = 10, height = 12, dpi = 300)

# Visualization 4: Richness Distribution Histogram
cat("  → Creating richness distribution chart...\n")

richness_hist <- ggplot(grid_richness %>% filter(species_richness > 0), 
                        aes(x = species_richness)) +
  geom_histogram(bins = 30, fill = "#2c7bb6", color = "white") +
  geom_vline(xintercept = richness_threshold, color = "red", 
             linetype = "dashed", size = 1) +
  annotate("text", x = richness_threshold + 20, y = Inf, 
           label = "Hotspot\nThreshold", 
           color = "red", vjust = 2, size = 4) +
  theme_minimal() +
  theme(
    plot.title = element_text(size = 14, face = "bold")
  ) +
  labs(
    title = "Distribution of Species Richness",
    subtitle = "Frequency of grid cells by number of species",
    x = "Species Richness (per grid cell)",
    y = "Number of Grid Cells"
  )

ggsave("outputs/figures/richness_distribution.png",
       richness_hist, width = 10, height = 6, dpi = 300)

cat("\n✓ All visualizations created!\n\n")

# ========================================
# STEP 8: Generate Analysis Report
# ========================================

cat("Step 8: Generating spatial analysis report...\n")

sink("outputs/tables/spatial_analysis_report.txt")
cat("====================================\n")
cat("SPATIAL ANALYSIS REPORT\n")
cat("====================================\n\n")
cat("Analysis Date:", as.character(Sys.Date()), "\n")
cat("Analyst: Syed Inzimam Ali Shah\n\n")

cat("DATASET OVERVIEW\n")
cat("----------------\n")
cat("Total species records:", nrow(species_sf), "\n")
cat("Unique species:", n_distinct(species_sf$species), "\n")
cat("Grid resolution: 0.5° (~50km)\n")
cat("Total grid cells:", nrow(grid_richness), "\n")
cat("Cells with data:", sampled_cells, "\n")
cat("Spatial coverage:", round(sampled_cells/total_cells*100, 1), "%\n\n")

cat("SPECIES RICHNESS STATISTICS\n")
cat("---------------------------\n")
cat("Mean species per cell:", round(mean(grid_richness$species_richness), 2), "\n")
cat("Median species per cell:", median(grid_richness$species_richness), "\n")
cat("Maximum species in a cell:", max(grid_richness$species_richness), "\n")
cat("Standard deviation:", round(sd(grid_richness$species_richness), 2), "\n\n")

cat("BIODIVERSITY HOTSPOTS\n")
cat("---------------------\n")
cat("Hotspot definition: Top 10% richest cells\n")
cat("Richness threshold:", round(richness_threshold, 0), "species\n")
cat("Number of hotspot cells:", nrow(hotspots), "\n")
cat("Percentage of total area:", round(nrow(hotspots)/nrow(grid_richness)*100, 1), "%\n\n")

cat("Top 5 Richest Cells:\n")
print(top_cells)

cat("\n\nSAMPLING EFFORT\n")
cat("---------------\n")
print(effort_summary)

cat("\n\nKEY FINDINGS\n")
cat("------------\n")
cat("1. Species richness is not evenly distributed across Pakistan\n")
cat("2. Biodiversity hotspots identified in", nrow(hotspots), "grid cells\n")
cat("3. Sampling coverage:", round(sampled_cells/total_cells*100, 1), "% of the country\n")
cat("4. Data gaps exist in", total_cells - sampled_cells, "grid cells\n")
cat("5. High-effort areas show greater species diversity\n\n")

cat("RECOMMENDATIONS\n")
cat("---------------\n")
cat("1. Focus conservation efforts on identified hotspot areas\n")
cat("2. Increase sampling in underrepresented regions\n")
cat("3. Conduct targeted surveys in data-gap areas\n")
cat("4. Monitor biodiversity trends in hotspot cells over time\n")
cat("5. Integrate with habitat and threat data for conservation planning\n")

sink()

cat("✓ Spatial analysis report saved\n\n")

# ========================================
# FINAL SUMMARY
# ========================================

cat("=== DAY 7 COMPLETE ===\n\n")
cat("✓ Spatial analysis successful!\n")
cat("✓ Grid created:", nrow(grid_richness), "cells\n")
cat("✓ Hotspots identified:", nrow(hotspots), "priority areas\n")
cat("✓ Maps created:", 4, "visualizations\n")
cat("✓ Ready for final visualizations (Day 11)!\n\n")

cat("Check your outputs:\n")
cat("  • outputs/maps/species_richness_heatmap.png\n")
cat("  • outputs/maps/biodiversity_hotspots_map.png\n")
cat("  • outputs/maps/sampling_effort_map.png\n")
cat("  • outputs/figures/richness_distribution.png\n")
cat("  • outputs/tables/spatial_analysis_report.txt\n")

