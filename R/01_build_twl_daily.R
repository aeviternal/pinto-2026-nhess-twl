# 01_build_twl_daily.R
# Hourly runup (R2) + observed water level  ->  daily predictors per transect.
#
# Fixes relative to the 2024 scripts:
#   1. Days are LOCAL calendar days. (Previously as.Date() on a POSIXct fell
#      back to UTC, so each "day" ran ~4 pm to ~4 pm Pacific.)
#   2. Daily maxima tolerate short gaps (the tide file has 3-hour gaps at
#      month boundaries that previously deleted whole days).
#   3. Previous-day values are computed for EVERY transect-day, not only for
#      days with a photo.
#
# Run from the repo root:  Rscript R/01_build_twl_daily.R

library(data.table)
library(lubridate)
source("R/00_config.R")
dir.create(OUT_DIR, showWarnings = FALSE)

# ---- time -------------------------------------------------------------------
datenum <- fread(file.path(SOURCE_DIR, TIME_FILE), header = FALSE)[[1]]
# MATLAB datenum 719529 = 1970-01-01
dt_utc   <- round_date(as.POSIXct((datenum - 719529) * 86400,
                                  origin = "1970-01-01", tz = "UTC"), "hour")
dt_local <- with_tz(dt_utc, LOCAL_TZ)
stopifnot(!anyDuplicated(dt_utc), all(diff(as.numeric(dt_utc)) == 3600))

time_dt <- data.table(
  date  = as.Date(format(dt_local, "%Y-%m-%d")),   # local calendar day
  hour  = hour(dt_local),
  dayhr = hour(dt_local) %in% DAYTIME_HOURS)
stopifnot(format(dt_local[1], "%Y-%m-%d %H") == "1999-12-31 16")  # UTC-8 check

# ---- water level ------------------------------------------------------------
tide <- fread(file.path(SOURCE_DIR, TIDE_FILE), header = FALSE,
              na.strings = c("NaN", "NA", ""))[[1]]
stopifnot(length(tide) == nrow(time_dt))
ref <- if (identical(TIDE_REFERENCE, "record_mean")) mean(tide, na.rm = TRUE) else
  as.numeric(TIDE_REFERENCE)
message(sprintf("Tide reference subtracted: %.4f m (station datum)", ref))
swl <- tide - ref

# ---- per-transect daily summaries -------------------------------------------
max_if <- function(x, min_n) {
  ok <- !is.na(x)
  if (sum(ok) >= min_n) max(x[ok]) else NA_real_
}

files <- list.files(SOURCE_DIR, pattern = RUNUP_GLOB)
mops  <- sub("_R2.*$", "", files)
message(length(files), " transect files")

one_transect <- function(f, mop_id) {
  r <- fread(file.path(SOURCE_DIR, f), header = FALSE,
             na.strings = c("NaN", "NA", ""))[[1]]
  stopifnot(length(r) == nrow(time_dt))
  h <- copy(time_dt)[, `:=`(runup = r, twl = r + swl)]

  d <- h[, .(twl   = max_if(twl,   MIN_HOURS_DAY),
             runup = max_if(runup, MIN_HOURS_DAY)), by = date]
  dd <- h[dayhr == TRUE,
          .(twl_daytime   = max_if(twl,   MIN_HOURS_DAYTIME),
            runup_daytime = max_if(runup, MIN_HOURS_DAYTIME)), by = date]
  d <- merge(d, dd, by = "date", all.x = TRUE)
  setorder(d, date)
  stopifnot(all(diff(d$date) == 1))                # consecutive days, so shift = lag

  d[, `:=`(twl_1_day_before   = shift(twl),        # previous day's 24-h maxima
           runup_1_day_before = shift(runup))]
  d[, `:=`(twl_max         = pmax(twl,         twl_1_day_before, na.rm = TRUE),
           twl_max_daytime = pmax(twl_daytime, twl_1_day_before, na.rm = TRUE))]
  d <- d[date >= START_DATE]
  d[, mop := mop_id]
  d
}

twl_daily <- rbindlist(Map(one_transect, files, mops))
setcolorder(twl_daily, c("mop", "date"))

saveRDS(twl_daily, file.path(OUT_DIR, "twl_daily.rds"))
message("Wrote ", nrow(twl_daily), " transect-days for ",
        uniqueN(twl_daily$mop), " transects, ",
        min(twl_daily$date), " to ", max(twl_daily$date))
