
<!-- README.md is generated from README.Rmd. Please edit that file -->

# settings.sync <img src='man/figures/logo.png' align="right" height="139" />

<!-- badges: start -->

[![R-CMD-check](https://github.com/tjpalanca/settings.sync/workflows/R-CMD-check/badge.svg)](https://github.com/tjpalanca/settings.sync/actions)
[![Codecov test
coverage](https://codecov.io/gh/tjpalanca/settings.sync/branch/master/graph/badge.svg)](https://codecov.io/gh/tjpalanca/settings.sync?branch=master)
[![Lifecycle:
stable](https://img.shields.io/badge/lifecycle-stable-brightgreen.svg)](https://lifecycle.r-lib.org/articles/stages.html#stable)
![GitHub R package
version](https://img.shields.io/github/r-package/v/tjpalanca/settings.sync)
[![License:
MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
<!-- badges: end -->

This is an RStudio addin to sync your RStudio settings to a GitHub gist.
This is useful if you have mulitple machines (or cloud instances) with
RStudio server and want to keep the settings in sync.

## Installations

Install this addin from [R Universe](https://tjpalanca.r-universe.dev):

``` r
install.packages("settings.sync", repos = "https://tjpalanca.r-universe.dev")
```

## Usage

Use this package by selecting it from your RStudio menu or running:

``` r
settings.sync::sync_addin()
```
