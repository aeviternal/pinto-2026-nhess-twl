# pinto-2026-nhess-twl

Code for "Integrating total water level data and visual evidence to assess
coastal flooding in San Diego County" (Pinto et al., NHESS, egusphere-2026-820).

## Pipeline

| Step | Script | Reads | Writes |
|---|---|---|---|
| 1 | `R/01_build_twl_daily.R` | hourly R2 per transect, hourly water level, time vector (source directory) | `output/twl_daily.rds` |
| 2 | `R/02_build_panel.R` | `output/twl_daily.rds`, `data/photo_transect_days.csv` | `output/twl_photo_panel.rds` |
| 3 | `analysis/` (Denali's Rmd) | `output/twl_photo_panel.rds`, transect definitions, AR catalog, ONI | figures and tables |

All paths and analysis choices are in `R/00_config.R`. Set the source directory
with `TWL_SOURCE_DIR` or edit the default.

```bash
Rscript R/01_build_twl_daily.R
Rscript R/02_build_panel.R
```

## Source data (not in the repo)

- `D####_R2_value_in_m.csv`: hourly wave runup (R2) per MOP transect.
- `tide_level_in_m_mean_removed.csv`: hourly observed water level at the La
  Jolla gauge (NOAA 9410230) on station datum. Despite the name, the mean has
  not been removed. One series is applied to all transects.
- `time.csv`: MATLAB datenum, UTC, hourly from 2000-01-01 00:00.

## Predictors

Hourly TWL = R2 + (water level - reference). Days are local calendar days
(America/Los_Angeles).

| Column | Definition |
|---|---|
| `twl`, `runup` | maximum over the local day |
| `twl_daytime`, `runup_daytime` | maximum over the daytime window (`DAYTIME_HOURS`) |
| `twl_1_day_before`, `runup_1_day_before` | previous day's 24-hour maximum |
| `twl_max` | larger of `twl` and `twl_1_day_before` |
| `twl_max_daytime` | larger of `twl_daytime` and `twl_1_day_before` |

## Open items

- `data/photo_transect_days.csv` is the list of photo transect-days extracted
  from `DP_20241204_cleaned.rds`. The cleaning that produced it from the photo
  spreadsheet is not yet scripted.
- Step 3: move the analysis Rmd here and point `twl_photos_rds` at the panel.
