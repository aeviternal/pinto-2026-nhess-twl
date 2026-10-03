# check_setup.R -- reports what is missing before running the analysis.
# Run from the repo root:  Rscript R/check_setup.R

source("R/00_config.R")
cat("R version:", R.version.string, "\n\n")

pkgs <- c("data.table", "lubridate", "tidyverse", "here", "broom", "gridExtra",
          "viridis", "DT", "readxl", "lme4", "ggtext", "ncdf4", "posterior",
          "brms", "rstan", "rmarkdown", "knitr")
have <- vapply(pkgs, requireNamespace, logical(1), quietly = TRUE)
cat("Packages missing:", if (all(have)) "none" else paste(pkgs[!have], collapse = ", "), "\n")

cat("Pandoc available:",
    if (have[["rmarkdown"]]) rmarkdown::pandoc_available() else NA, "\n")
cat("C++ compiler (needed by Stan):", nzchar(Sys.which("clang++")) || nzchar(Sys.which("g++")), "\n\n")

files <- c(
  "source data folder"            = SOURCE_DIR,
  "output/twl_photo_panel.rds"    = "output/twl_photo_panel.rds",
  "output/twl_backbone.rds"       = "output/twl_backbone.rds",
  "data/photo_transect_days.csv"  = "data/photo_transect_days.csv",
  "data/CA_v1.1_transect_definitions_SD_County.txt" =
    "data/CA_v1.1_transect_definitions_SD_County.txt",
  "data/ARcatalog_NCEP_NEW_1948-2023_COMPREHENSIVE_08-07-2023_Ranked_Daily_32.5.xlsx (optional: AR section)" =
    "data/ARcatalog_NCEP_NEW_1948-2023_COMPREHENSIVE_08-07-2023_Ranked_Daily_32.5.xlsx",
  "data/oni.nc (optional: ENSO section)" = "data/oni.nc")
for (i in seq_along(files))
  cat(sprintf("%-8s %s\n", if (file.exists(files[i])) "found" else "MISSING", names(files)[i]))
