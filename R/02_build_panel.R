# 02_build_panel.R
# Join the cleaned photo list to the daily predictors -> analysis panel.
# Output has the column names the analysis Rmd expects (plus twl_max and
# twl_max_daytime, already computed for every row).
#
# Run from the repo root:  Rscript R/02_build_panel.R

library(data.table)
source("R/00_config.R")

twl    <- readRDS(file.path(OUT_DIR, "twl_daily.rds"))
photos <- fread("data/photo_transect_days.csv")
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
panel <- panel[mop %in% keep]                      # transects with >= 1 matched photo

saveRDS(as.data.frame(panel), file.path(OUT_DIR, "twl_photo_panel.rds"))
fwrite(panel, file.path(OUT_DIR, "twl_photo_panel.csv"))
message("Panel: ", nrow(panel), " transect-days, ", uniqueN(panel$mop),
        " transects, ", sum(panel$photo), " photo transect-days")
