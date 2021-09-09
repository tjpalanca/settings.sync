pkg_name <- "settings.sync"

pkg_vers <- function() {
  unname(read.dcf(
    system.file("DESCRIPTION", package = pkg_name),
    c("Version")
  )[1, 1])
}

pkg_inst <- function(...) {
  path(path_package(pkg_name), ...)
}

pkg_temp <- function(...) {

  temp_dir <- path(path_temp(), pkg_name)
  dir_create(temp_dir)
  path(temp_dir, ...)

}

pkg_user <- function(...) {

  user_dir <- tools::R_user_dir(pkg_name)
  dir_create(user_dir)
  path(user_dir, ...)

}

globalVariables(
  names = c("config_slug", ".", "config_path", "config_file_info",
            "is_new", "is_changed", "gist_updated_at", "config_file_updated_at",
            "upload_path", "is_new", "is_updated", "upload_full_path",
            "is_outdated"),
  package = pkg_name
)
