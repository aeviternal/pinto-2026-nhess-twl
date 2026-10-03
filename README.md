# pinto-2026-nhess-twl

Code for "Integrating total water level data and visual evidence to assess
coastal flooding in San Diego County" (Pinto et al., NHESS, egusphere-2026-820).

## Pipeline

| Step | Script | Reads | Writes |
|---|---|---|---|
| 1 | `R/01_build_twl_daily.R` | hourly R2 per transect, hourly water level, time vector (source directory) | `output/twl_daily.rds` (full record, all transects) |
| 2 | `R/02_build_panel.R` | `output/twl_daily.rds`, `data/photo_transect_days.csv` | `output/twl_photo_panel.rds`, `output/twl_backbone.rds` |
| 3 | `R/03_render_analysis.R` | the panel and backbone, plus files in `data/` | `output/figures/`, `output/tables/`, `output/analysis.html` |

All paths and build choices are in `R/00_config.R`; analysis choices (headline
predictor, figure window) are the `params` at the top of `analysis/analysis.Rmd`.
Set the source directory with `TWL_SOURCE_DIR` or edit the default.

```bash
Rscript R/check_setup.R          # reports missing packages and input files
Rscript R/01_build_twl_daily.R
Rscript R/02_build_panel.R
Rscript R/03_render_analysis.R
```

Files expected in `data/`:

- `photo_transect_days.csv` (in the repo)
- `CA_v1.1_transect_definitions_SD_County.txt` (copy from the source directory)
- the AR catalog `.xlsx` and `oni.nc` (not in the repo). If either is absent,
  the atmospheric river or ENSO section is skipped and the rest still runs.

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
- The analysis Rmd has been ported and parameterised but its figures have not
  yet been reviewed against the manuscript.
