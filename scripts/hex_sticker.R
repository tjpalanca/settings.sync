library(hexSticker)
library(usethis)
library(magrittr)

logo_location <- "inst/img/logo.png"

sticker(
  subplot =
    png::readPNG("inst/img/gear.png") %>%
    grid::rasterGrob(interpolate = TRUE),
  package  = "settings.sync",
  filename = logo_location,
  p_size   = 20,
  s_width  = 10,
  s_height = 0.9,
  s_x      = 1,
  h_color  = "#FAFAFA",
  h_fill   = "#008080"
)

file.remove("man/figures/logo.png")
use_logo(logo_location)
