# pinto-2026-nhess-twl

Code for "Integrating total water level data and visual evidence to assess coastal
flooding in San Diego County" (Pinto et al., NHESS, egusphere-2026-820), as revised in
response to the reviewers.

The full analysis log, with every code chunk, table and figure, is at
<https://aeviternal.github.io/pinto-2026-nhess-twl/analysis.html>.

## What the analysis does

Photographs of coastal flooding, each assigned to a 100 m MOP transect and a date, are
compared with modeled total water level (TWL) at the same transect. For each transect
with two or more photo days, a logistic regression of photo occurrence on daily TWL gives
two thresholds:

- the **documentation threshold**, the TWL at which a photo is as likely as not on
  a given day (fitted probability 0.5);
- the **balanced documentation threshold**, the TWL at which the fitted probability
  equals the transect's overall photo frequency, above which a photo is more likely
  than on an average day.

## Pipeline

| Step | Script | Reads | Writes |
|---|---|---|---|
| 1 | `R/01_build_twl_daily.R` | hourly runup per transect, hourly water level, time vector (source directory) | `output/twl_daily.rds` (full record, all transects) |
| 2 | `R/02_build_panel.R` | `output/twl_daily.rds`, `data/photo_transect_days.csv` | `output/twl_photo_panel.rds`, `output/twl_backbone.rds` |
| 3 | `R/03_render_analysis.R` | the panel and backbone, plus files in `data/` | `output/figures/`, `output/tables/`, `output/analysis.html` |
| 4 | `R/04_runup_sensitivity.R` | the panel, plus the hourly source files | `output/tables/runup_scale_sensitivity.csv` |

Paths and build choices are in `R/00_config.R`. Analysis choices (headline predictor,
figure window) are the `params` at the top of `analysis/analysis.Rmd`. Set the source
directory with the environment variable `TWL_SOURCE_DIR` or edit the default.

```
Rscript R/check_setup.R          # reports missing packages and input files
Rscript R/01_build_twl_daily.R
Rscript R/02_build_panel.R
Rscript R/03_render_analysis.R
Rscript R/04_runup_sensitivity.R # optional: sensitivity of thresholds to runup
```

Requirements: R (run with 4.5.2), a C++ compiler for Stan, pandoc, and the packages
listed in `R/check_setup.R`.

## Data

Link to data in Zenodo: [DOI 10.5281/zenodo.18729176
](https://zenodo.org/records/23254924)
In `data/`:

- `photo_transect_days.csv` (in the repo): one row per transect-day with at least one
  photo meeting the flooding criteria.
- `CA_v1.1_transect_definitions_SD_County.txt` (copy from the source directory).
- The atmospheric river catalog (`.xlsx`) and `oni.nc` (not in the repo). If either is
  absent, the atmospheric river or ENSO section is skipped and the rest still runs.

Source directory (not in the repo; about 3 GB):

- `D####_R2_value_in_m.csv`: hourly wave runup (R2, Stockdon et al., 2006) per MOP
  transect.
- `tide_level_in_m_mean_removed.csv`: hourly observed water level at the La Jolla tide
  gauge (NOAA 9410230) on station datum. Despite the name, the mean has not been
  removed. One series is applied to all transects.
- `time.csv`: MATLAB datenum, UTC, hourly from 2000-01-01 00:00.

The source data, trimmed to the study period and transects, will be archived on Zenodo
with this code.

## Predictors

Hourly TWL = R2 + (water level − reference). The reference is the mean of the water
level record, which is 0.02 m above NOAA mean sea level (1983–2001 epoch). Days are
local calendar days (America/Los_Angeles). The daytime window is 7 a.m. to 6 p.m.
A daily maximum is reported when at least 20 of 24 hourly values are present, and a
daytime maximum when at least 10 of 12 are present.

| Column | Definition |
|---|---|
| `twl`, `runup` | maximum over the local day |
| `twl_daytime`, `runup_daytime` | maximum over the daytime window |
| `twl_1_day_before`, `runup_1_day_before` | previous day's 24-hour maximum |
| `twl_max` | larger of `twl` and `twl_1_day_before` |
| `twl_max_daytime` | larger of `twl_daytime` and `twl_1_day_before` |

The headline predictor is `twl_daytime`.

## Changes from the submitted analysis

This code replaces the scripts behind the submitted manuscript. Two errors in how the
daily predictors were built have been corrected:

1. Daily values were computed on UTC calendar days. They are now computed on local
   calendar days.
2. The previous day's value was filled in only on days with a photo, which affected
   `twl_max` and `twl_max_daytime`. It is now computed for every transect-day.

The study period is January 2015 to April 2024.

## Limitations

- `data/photo_transect_days.csv` was extracted from the cleaned photo database. The
  steps that produced it from the original photo spreadsheet (coding against the
  flooding criteria, and assignment to transects) are described in the manuscript but
  are not scripted here.
- The water level record has no data for June 2006 or from November 2006 to December
  2007. This affects only the ENSO figures, which use the record from 2000.
