# Home Rprofile
if (file.exists("~/.Rprofile")) source("~/.Rprofile", chdir = TRUE)

# Development Utilities
if (Sys.getenv("R_CONFIG_ACTIVE") == "dev") {
  r <- function(clear = FALSE, reset = FALSE, ...) {
    if (clear) {
      rm(list = ls(globalenv()), envir = globalenv())
      source(".Rprofile")
    }
    if (rstudioapi::isAvailable()) {
      rstudioapi::documentSaveAll()
    }
    pkgload::load_all(..., reset = reset)
  }
  dr <- function(clear = FALSE, reset = FALSE, ...) {
    devtools::document()
    r(clear = clear, reset = reset, ...)
  }
  ra <- function(clear = FALSE, reset = FALSE, ...) {
    r(clear = clear, reset = reset, ...)
    sync_addin()
  }
  rr <- function(clear = FALSE, reset = FALSE, ...) {
    r(clear = clear, reset = reset, ...)
    productive_app_run()
  }
}
