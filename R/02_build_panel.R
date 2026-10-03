# 02_build_panel.R
# Join the cleaned photo list to the daily predictors.
#   output/twl_photo_panel.rds  analysis panel, START_DATE onward, transects
#                               with at least one matched photo
#   output/twl_backbone.rds     full-record daily series for the same transects
#                               (used for the long ENSO time series)
#
# Run from the repo root:  Rscript R/02_build_panel.R

library(data.table)
source("R/00_config.R")

twl_all <- readRDS(file.path(OUT_DIR, "twl_daily.rds"))
twl     <- twl_all[date >= START_DATE]
photos  <- fread("data/photo_transect_days.csv")
photos[, date := as.Date(date)]
stopifnot(!anyDuplicated(photos, by = c("mop", "date")))

# Report what cannot be matched rather than silently dropping it.
unmatched <- photos[!twl, on = c("mop", "date")]
if (nrow(unmatched)) {
  message(nrow(unmatched), " photo transect-days have no TWL row ",
          "(outside San Diego County or before ", START_DATE, "):")
  print(unmatched)
  fwrite(unmatched, file.path(OUT_DIR, "photos_unmatched.csv"))
}

photos[, photo := 1L]
panel <- merge(twl[mop %in% photos$mop], photos, by = c("mop", "date"), all.x = TRUE)
panel[is.na(photo), photo := 0L]
keep  <- panel[, .(any_photo = any(photo == 1L)), by = mop][any_photo == TRUE, mop]
panel <- panel[mop %in% keep]

saveRDS(as.data.frame(panel), file.path(OUT_DIR, "twl_photo_panel.rds"))
fwrite(panel, file.path(OUT_DIR, "twl_photo_panel.csv"))
message("Panel: ", nrow(panel), " transect-days, ", uniqueN(panel$mop),
        " transects, ", sum(panel$photo), " photo transect-days")

backbone <- twl_all[mop %in% keep,
                    .(mop, date, twl, runup, twl_daytime, runup_daytime)]
saveRDS(as.data.frame(backbone), file.path(OUT_DIR, "twl_backbone.rds"))
message("Backbone: ", nrow(backbone), " transect-days, ",
        min(backbone$date), " to ", max(backbone$date))
