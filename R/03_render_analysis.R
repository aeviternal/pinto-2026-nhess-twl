# 03_render_analysis.R
# Runs analysis/analysis.Rmd: figures to output/figures, tables to output/tables,
# and an HTML log of every chunk to output/analysis.html.
#
# Run from the repo root:  Rscript R/03_render_analysis.R

rmarkdown::render("analysis/analysis.Rmd",
                  output_dir    = "output",
                  knit_root_dir = getwd(),
                  quiet         = FALSE)
