# ========================================
# Pakistan Biodiversity Analysis
# Script 01: Setup and Data Download
# Author: [Syed Inzimam Ali Shah]
# Date: Sep-Oct 2025
# ========================================

# Load libraries
library(rgbif)
library(dplyr)
library(sf)
library(rnaturalearth)
library(ggplot2)

# Set working directory
setwd("C:/pakistan_biodiversity_analysis")

cat("=== PAKISTAN BIODIVERSITY DATA DOWNLOAD ===\n\n")

# ========================================
# STEP 1: Get Pakistan Boundary
# ========================================

cat("Step 1: Downloading Pakistan boundary...\n")

# Download Pakistan boundary from Natural Earth
pakistan <- ne_countries(scale = "medium", country = "Pakistan", returnclass = "sf")

# Save the boundary
st_write(pakistan, "data/processed/pakistan_boundary.shp", delete_dsn = TRUE)

# Visualize it
plot(st_geometry(pakistan), main = "Pakistan Boundary", col = "lightgreen", border = "darkgreen")

cat("✓ Pakistan boundary downloaded!\n\n")

# ========================================
# STEP 2: Download Species Data from GBIF
# ========================================

cat("Step 2: Downloading species occurrence data...\n")
cat("This will take 3-5 minutes...\n\n")

# Download occurrence data for Pakistan
# Starting with 10,000 records (you can increase later)
species_data <- occ_search(
  country = "PK",              # Pakistan
  hasCoordinate = TRUE,        # Only records with GPS coordinates
  limit = 10000                # Number of records
)

# Extract the actual data
species_records <- species_data$data

cat("✓ Downloaded", nrow(species_records), "species records!\n\n")

# ========================================
# STEP 3: Quick Look at the Data
# ========================================

cat("=== DATA SUMMARY ===\n")
cat("Total records:", nrow(species_records), "\n")
cat("Unique species:", n_distinct(species_records$species), "\n")
cat("Date range:", min(species_records$year, na.rm = TRUE), "to", 
    max(species_records$year, na.rm = TRUE), "\n\n")

# Most common species
cat("Top 10 most recorded species:\n")
top_species <- species_records %>%
  count(species, sort = TRUE) %>%
  head(10)
print(top_species)

# ========================================
# STEP 4: Save Raw Data
# ========================================

cat("\nStep 4: Saving data...\n")

# Save as CSV
write.csv(species_records, "data/raw/gbif_pakistan_raw.csv", row.names = FALSE)

cat("✓ Data saved to: data/raw/gbif_pakistan_raw.csv\n")

# ========================================
# STEP 5: Quick Preview Map
# ========================================

cat("\nStep 5: Creating preview map...\n")

# Convert to spatial object
species_sf <- st_as_sf(species_records,
                       coords = c("decimalLongitude", "decimalLatitude"),
                       crs = 4326)

# Create quick map
preview <- ggplot() +
  geom_sf(data = pakistan, fill = "lightgray", color = "black") +
  geom_sf(data = species_sf, alpha = 0.3, size = 0.5, color = "darkgreen") +
  theme_minimal() +
  labs(title = "Species Occurrences in Pakistan",
       subtitle = paste(nrow(species_sf), "records from GBIF"),
       caption = "Data source: GBIF.org")

print(preview)

# Save the map
ggsave("outputs/figures/preview_map.png", preview, width = 8, height = 10, dpi = 300)

cat("\n✓ Preview map saved to: outputs/figures/preview_map.png\n")

cat("\n=== SCRIPT COMPLETED SUCCESSFULLY! ===\n")
cat("Check your outputs/figures/ folder to see the map!\n")
```

3. **Save the script:**
  - **File → Save As...**
  - Navigate to: `C:/pakistan_biodiversity_analysis/scripts/`
- Name: `01_setup_and_download.R`
- Click **Save**
  
  ---
  
  ### **Step 2: Run the Script**
  
  **Click the "Source" button** (top-right corner of the script window)

**OR**
  
  Press **Ctrl+A** (select all) then **Ctrl+Enter** (run)

---
  
  ### **Step 3: Watch It Work!**
  
  You'll see messages appear in the Console like:
```
=== PAKISTAN BIODIVERSITY DATA DOWNLOAD ===

Step 1: Downloading Pakistan boundary...
✓ Pakistan boundary downloaded!

Step 2: Downloading species occurrence data...
This will take 3-5 minutes...
