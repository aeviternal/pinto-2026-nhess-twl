# 04_runup_sensitivity.R
# How much do the thresholds move if runup is systematically too high or too low?
#
# A beach slope that is wrong by a constant factor at a transect changes Stockdon
# runup by a (nearly) constant factor at that transect. This script rescales
# hourly runup by a set of factors, rebuilds TWL-daytime, and refits the two
# thresholds at each of the main transects. It needs only the files the pipeline
# already uses: no slope data.
#
# Untested when written. Run from the repo root, with the source drive mounted,
# after R/01 and R/02:   Rscript R/04_runup_sensitivity.R

library(data.table)
library(lubridate)
source("R/00_config.R")

SCALES       <- c(0.8, 0.9, 1.0, 1.1, 1.2)   # runup multipliers
MIN_PHOTOS   <- 2
EXCLUDE_MOPS <- "D0841"

# ---- photo days and main transects -------------------------------------------
panel  <- as.data.table(readRDS(file.path(OUT_DIR, "twl_photo_panel.rds")))
panel[, date := as.Date(date)]
photos <- panel[photo == 1L, .(mop, date)]
main   <- panel[!is.na(twl_daytime), .(n = sum(photo)), by = mop][
            n >= MIN_PHOTOS & !mop %in% EXCLUDE_MOPS, mop]
message(length(main), " transects")

# ---- time and water level (same construction as R/01) -------------------------
datenum  <- fread(file.path(SOURCE_DIR, TIME_FILE), header = FALSE)[[1]]
dt_utc   <- round_date(as.POSIXct((datenum - 719529) * 86400,
                                  origin = "1970-01-01", tz = "UTC"), "hour")
dt_local <- with_tz(dt_utc, LOCAL_TZ)
day      <- as.Date(format(dt_local, "%Y-%m-%d"))
dayhr    <- hour(dt_local) %in% DAYTIME_HOURS

tide <- fread(file.path(SOURCE_DIR, TIDE_FILE), header = FALSE,
              na.strings = c("NaN", "NA", ""))[[1]]
ref  <- if (identical(TIDE_REFERENCE, "record_mean")) mean(tide, na.rm = TRUE) else
  as.numeric(TIDE_REFERENCE)
swl  <- tide - ref

max_if <- function(x, min_n) {
  ok <- !is.na(x)
  if (sum(ok) >= min_n) max(x[ok]) else NA_real_
}

# ---- refit one transect at one runup scale -------------------------------------
fit_one <- function(mop_id, r, scale) {
  h <- data.table(date = day, twl = swl + scale * r)[dayhr]
  d <- h[, .(x = max_if(twl, MIN_HOURS_DAYTIME)), by = date][date >= START_DATE & !is.na(x)]
  d[, photo := as.integer(date %in% photos[mop == mop_id, date])]
  mod <- suppressWarnings(glm(photo ~ x, data = d, family = binomial))
  b   <- unname(coef(mod))
  data.table(mop = mop_id, scale = scale, n_days = nrow(d), n_photos = sum(d$photo),
             threshold_50 = -b[1] / b[2],
             onset        = (qlogis(mean(d$photo)) - b[1]) / b[2],
             slope        = b[2], AIC = AIC(mod))
}

res <- rbindlist(lapply(main, function(m) {
  r <- fread(file.path(SOURCE_DIR, paste0(m, "_R2_value_in_m.csv")), header = FALSE,
             na.strings = c("NaN", "NA", ""))[[1]]
  stopifnot(length(r) == length(swl))
  rbindlist(lapply(SCALES, function(s) fit_one(m, r, s)))
}))

# ---- results ---------------------------------------------------------------------
base <- res[scale == 1, .(mop, base_50 = threshold_50, base_onset = onset, base_AIC = AIC)]
res  <- merge(res, base, by = "mop")
res[, `:=`(d_50 = threshold_50 - base_50, d_onset = onset - base_onset, d_AIC = AIC - base_AIC)]

dir.create(file.path(OUT_DIR, "tables"), showWarnings = FALSE, recursive = TRUE)
fwrite(res, file.path(OUT_DIR, "tables", "runup_scale_sensitivity.csv"))

options(width = 200)
cat("\nBy runup scale, across", length(main), "transects (shifts are relative to scale 1.0):\n")
print(res[, .(median_threshold_50 = round(median(threshold_50), 2),
              median_shift_50     = round(median(d_50), 2),
              range_shift_50      = paste(round(min(d_50), 2), "to", round(max(d_50), 2)),
              median_onset        = round(median(onset), 2),
              median_shift_onset  = round(median(d_onset), 2),
              median_dAIC         = round(median(d_AIC), 2)), by = scale])

cat("\nPer transect, 50 % documentation threshold (m) by runup scale:\n")
print(dcast(res, mop + n_photos ~ scale, value.var = "threshold_50")[
  , lapply(.SD, function(v) if (is.numeric(v)) round(v, 2) else v)], nrows = 100)

cat("\nPer transect, onset threshold (m) by runup scale:\n")
print(dcast(res, mop + n_photos ~ scale, value.var = "onset")[
  , lapply(.SD, function(v) if (is.numeric(v)) round(v, 2) else v)], nrows = 100)

# ---- what slope error does a runup factor correspond to? -------------------------
# Stockdon (2006), non-dissipative branch: R2 = sqrt(Hs*L0) * f(beta), with
# f(beta) = 1.1 * (0.35*beta + sqrt(0.563*beta^2 + 0.004) / 2).
f <- function(beta) 1.1 * (0.35 * beta + sqrt(0.563 * beta^2 + 0.004) / 2)
slopes <- c(0.02, 0.04, 0.06, 0.08, 0.10, 0.12)
tab <- data.table(beach_slope = slopes)
for (p in c(-50, -25, 25, 50)) {
  tab[, (sprintf("slope %+d%%", p)) := round(f(beach_slope * (1 + p / 100)) / f(beach_slope), 2)]
}
cat("\nRunup factor produced by a given relative error in beach slope",
    "(non-dissipative Stockdon):\n")
print(tab)
