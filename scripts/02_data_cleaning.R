# ========================================
# Pakistan Biodiversity Analysis
# Script 02: Data Cleaning
# Author: Syed Inzimam Ali Shah
# Date: 2025
# ========================================

library(dplyr)
library(sf)
library(ggplot2)

setwd("C:/pakistan-biodiversity-analysis")

cat("=== DAY 5: DATA CLEANING ===\n\n")

# ========================================
# STEP 1: Load Raw Data
# ========================================

cat("Step 1: Loading raw data...\n")
species_raw <- read.csv("data/raw/gbif_pakistan_raw.csv")
pakistan_boundary <- st_read("data/processed/pakistan_boundary.shp", quiet = TRUE)

cat("Loaded", nrow(species_raw), "raw records\n\n")

# ========================================
# STEP 2: Data Cleaning Pipeline
# ========================================

cat("Step 2: Cleaning data...\n\n")

# Track cleaning steps
cleaning_log <- data.frame(
  Step = character(),
  Records_Removed = numeric(),
  Records_Remaining = numeric(),
  stringsAsFactors = FALSE
)

initial_count <- nrow(species_raw)

# Step 2.1: Remove records without coordinates
cat("  → Removing records without coordinates...\n")
species_clean <- species_raw %>%
  filter(!is.na(decimalLongitude), !is.na(decimalLatitude))

removed <- initial_count - nrow(species_clean)
cleaning_log <- rbind(cleaning_log, 
                      data.frame(Step = "No coordinates", 
                                Records_Removed = removed,
                                Records_Remaining = nrow(species_clean)))
cat("    Removed:", removed, "records\n")

# Step 2.2: Remove records without species name
cat("  → Removing records without species name...\n")
before <- nrow(species_clean)
species_clean <- species_clean %>%
  filter(!is.na(species), species != "")

removed <- before - nrow(species_clean)
cleaning_log <- rbind(cleaning_log,
                      data.frame(Step = "No species name",
                                Records_Removed = removed,
                                Records_Remaining = nrow(species_clean)))
cat("    Removed:", removed, "records\n")

# Step 2.3: Remove obvious coordinate errors
cat("  → Removing records with invalid coordinates...\n")
before <- nrow(species_clean)
species_clean <- species_clean %>%
  filter(decimalLongitude >= 60, decimalLongitude <= 78) %>%  # Pakistan longitude
  filter(decimalLatitude >= 23, decimalLatitude <= 38)        # Pakistan latitude

removed <- before - nrow(species_clean)
cleaning_log <- rbind(cleaning_log,
                      data.frame(Step = "Invalid coordinates",
                                Records_Removed = removed,
                                Records_Remaining = nrow(species_clean)))
cat("    Removed:", removed, "records\n")

# Step 2.4: Remove duplicate records
cat("  → Removing duplicate records...\n")
before <- nrow(species_clean)
species_clean <- species_clean %>%
  distinct(species, decimalLongitude, decimalLatitude, .keep_all = TRUE)

removed <- before - nrow(species_clean)
cleaning_log <- rbind(cleaning_log,
                      data.frame(Step = "Duplicates",
                                Records_Removed = removed,
                                Records_Remaining = nrow(species_clean)))
cat("    Removed:", removed, "records\n")

# Step 2.5: Keep only useful columns
cat("  → Selecting relevant columns...\n")
species_clean <- species_clean %>%
  select(species, scientificName, kingdom, phylum, class, order, 
         family, genus, decimalLongitude, decimalLatitude, 
         year, month, day, basisOfRecord, institutionCode, 
         datasetName, countryCode)

cat("\nCleaning complete!\n")
cat("Starting records:", initial_count, "\n")
cat("Final clean records:", nrow(species_clean), "\n")
cat("Total removed:", initial_count - nrow(species_clean), "\n")
cat("Retention rate:", round(nrow(species_clean)/initial_count*100, 1), "%\n\n")

# ========================================
# STEP 3: Convert to Spatial Object
# ========================================

cat("Step 3: Converting to spatial format...\n")

species_sf <- st_as_sf(species_clean,
                       coords = c("decimalLongitude", "decimalLatitude"),
                       crs = 4326)  # WGS84

# Verify points are within Pakistan
species_pakistan <- st_intersection(species_sf, pakistan_boundary)

cat("Records within Pakistan boundary:", nrow(species_pakistan), "\n")

if(nrow(species_pakistan) < nrow(species_sf)) {
  outside <- nrow(species_sf) - nrow(species_pakistan)
  cat("Note:", outside, "records were outside Pakistan boundary (removed)\n")
}

# ========================================
# STEP 4: Final Data Summary
# ========================================

cat("\n=== CLEANED DATA SUMMARY ===\n")

cat("Total clean records:", nrow(species_pakistan), "\n")
cat("Unique species:", n_distinct(species_pakistan$species), "\n")

# Taxonomic breakdown
cat("\nBy Class:\n")
class_summary <- species_pakistan %>%
  st_drop_geometry() %>%
  count(class, sort = TRUE) %>%
  head(5)
print(class_summary)

# Top species
cat("\nTop 10 species:\n")
top_species <- species_pakistan %>%
  st_drop_geometry() %>%
  count(species, sort = TRUE) %>%
  head(10)
print(top_species)

# ========================================
# STEP 5: Save Cleaned Data
# ========================================

cat("\nStep 5: Saving cleaned data...\n")

# Save as shapefile (with spatial info)
st_write(species_pakistan, 
         "data/processed/species_occurrences_clean.shp",
         delete_dsn = TRUE, quiet = TRUE)

# Save as CSV (without geometry, for easy viewing)
# Extract coordinates BEFORE dropping geometry
coords <- st_coordinates(species_pakistan)

species_clean_csv <- species_pakistan %>%
  st_drop_geometry() %>%
  mutate(longitude = coords[,1],
         latitude = coords[,2])

write.csv(species_clean_csv, 
          "data/processed/species_clean.csv",
          row.names = FALSE)

# Save cleaning log
write.csv(cleaning_log,
          "outputs/tables/cleaning_log.csv",
          row.names = FALSE)

cat("✓ Cleaned shapefile: data/processed/species_occurrences_clean.shp\n")
cat("✓ Cleaned CSV: data/processed/species_clean.csv\n")
cat("✓ Cleaning log: outputs/tables/cleaning_log.csv\n")

# ========================================
# STEP 6: Create Before/After Comparison
# ========================================

cat("\nStep 6: Creating comparison visualizations...\n")

# Load raw data as spatial
species_raw_sf <- st_as_sf(species_raw %>% 
                             filter(!is.na(decimalLongitude), 
                                    !is.na(decimalLatitude)),
                           coords = c("decimalLongitude", "decimalLatitude"),
                           crs = 4326)

# Before cleaning map
before_map <- ggplot() +
  geom_sf(data = pakistan_boundary, fill = "lightgray", color = "black") +
  geom_sf(data = species_raw_sf, alpha = 0.2, size = 0.3, color = "red") +
  theme_minimal() +
  labs(title = "BEFORE Cleaning",
       subtitle = paste(nrow(species_raw_sf), "records"),
       caption = "Red dots show all records including problematic ones")

# After cleaning map
after_map <- ggplot() +
  geom_sf(data = pakistan_boundary, fill = "lightgray", color = "black") +
  geom_sf(data = species_pakistan, alpha = 0.2, size = 0.3, color = "darkgreen") +
  theme_minimal() +
  labs(title = "AFTER Cleaning",
       subtitle = paste(nrow(species_pakistan), "high-quality records"),
       caption = "Green dots show clean, validated records")

# Save comparison
ggsave("outputs/figures/before_cleaning.png", before_map, 
       width = 8, height = 10, dpi = 300)

ggsave("outputs/figures/after_cleaning.png", after_map, 
       width = 8, height = 10, dpi = 300)

cat("✓ Comparison maps saved to outputs/figures/\n")

# ========================================
# STEP 7: Quality Report
# ========================================

cat("\nStep 7: Generating quality report...\n")

sink("outputs/tables/cleaning_report.txt")
cat("====================================\n")
cat("DATA CLEANING REPORT\n")
cat("====================================\n\n")
cat("Date:", as.character(Sys.Date()), "\n\n")

cat("CLEANING STEPS\n")
cat("--------------\n")
print(cleaning_log)

cat("\n\nFINAL DATASET STATISTICS\n")
cat("------------------------\n")
cat("Clean records:", nrow(species_pakistan), "\n")
cat("Unique species:", n_distinct(species_pakistan$species), "\n")
cat("Date range:", min(species_pakistan$year, na.rm = TRUE), "to",
    max(species_pakistan$year, na.rm = TRUE), "\n")

cat("\n\nTAXONOMIC COMPOSITION\n")
cat("---------------------\n")
print(class_summary)

cat("\n\nMOST RECORDED SPECIES\n")
cat("--------------------\n")
print(top_species)

cat("\n\nDATA QUALITY ASSESSMENT\n")
cat("-----------------------\n")
cat("✓ All records have valid coordinates\n")
cat("✓ All records have species identification\n")
cat("✓ All duplicates removed\n")
cat("✓ All records within Pakistan boundaries\n")
cat("✓ Dataset ready for spatial analysis\n")

sink()

cat("✓ Quality report saved to: outputs/tables/cleaning_report.txt\n")

# ========================================
# FINAL SUMMARY
# ========================================

cat("\n=== DAY 5 COMPLETE ===\n")
cat("\n✓ Data cleaning successful!\n")
cat("✓ Starting with", initial_count, "records\n")
cat("✓ Cleaned dataset has", nrow(species_pakistan), "high-quality records\n")
cat("✓ Ready for spatial analysis (Day 7)!\n\n")

cat("Check your outputs:\n")
cat("  • outputs/figures/before_cleaning.png\n")
cat("  • outputs/figures/after_cleaning.png\n")
cat("  • outputs/tables/cleaning_report.txt\n")
cat("  • data/processed/species_clean.csv\n")