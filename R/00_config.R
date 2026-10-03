# 00_config.R -- paths and analysis choices. Edit here, nowhere else.

# Source data from Susheel Adusumilli (hourly, UTC, starting 2000-01-01 00:00).
SOURCE_DIR <- Sys.getenv("TWL_SOURCE_DIR",
                         "/Volumes/TWC9/Data/MOP_Vertical/mop_twl_lsr")
TIME_FILE  <- "time.csv"                           # MATLAB datenum, UTC
TIDE_FILE  <- "tide_level_in_m_mean_removed.csv"   # observed water level, La Jolla
                                                   # (9410230), station datum.
                                                   # Despite the name, NOT demeaned.
RUNUP_GLOB <- "_R2_value_in_m\\.csv$"              # one file per MOP transect

OUT_DIR    <- "output"
LOCAL_TZ   <- "America/Los_Angeles"

# Vertical reference. "record_mean" subtracts the mean of the tide file
# (2.186 m; what the submitted analysis did). Or give a number, e.g. 2.164 for
# NOAA MSL (1983-2001 epoch) on station datum.
TIDE_REFERENCE <- "record_mean"

# Daytime window, local clock hours of the hourly timestamps (inclusive).
# 7:18 = 7 a.m. through 6 p.m.
DAYTIME_HOURS <- 7:18

# A daily maximum is reported only if at least this many hourly values exist.
MIN_HOURS_DAY     <- 20   # of 24 (23/25 on DST days)
MIN_HOURS_DAYTIME <- 10   # of length(DAYTIME_HOURS)

START_DATE <- as.Date("2015-01-01")
