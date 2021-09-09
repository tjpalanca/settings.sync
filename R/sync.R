#' @title Sync Addin
#'
#' @description
#' This Gadget syncs rstudio settings to a GitHub gist.
#'
#' @export
sync_addin <- function() {
  runGadget(
    sync_addin_ui(),
    sync_addin_server,
    viewer = dialogViewer("Sync Settings", width = 400, height = 300),
    stopOnCancel = FALSE
  )
}

#' @describeIn sync_addin Actual Sync Addin
#' @param request (rook) request
sync_addin_ui <- function(request) {

  miniPage(
    gadgetTitleBar(
      title = "Sync RStudio Settings",
      left  = NULL,
      right = miniTitleBarButton("close", "Close", primary = TRUE)
    ),
    miniContentPanel(
      textInput(
        inputId = "sync_gist_id",
        label = "Gist ID",
        width = "100%",
        value = sync_gist_id(),
        placeholder = "(e.g. 3e0daea34714d113bf26fc4477e7cb34)"
      )
    ),
    miniButtonBlock(
      borer = "bottom",
      actionButton(
        inputId  = "reset",
        label    = "Reset Gist ID",
        class    = "btn-danger"
      ),
      actionButton(
        inputId  = "sync",
        label    = "Start Sync",
        icon     = icon("sync"),
        class    = "btn-success"
      )
    )
  )

}

#' @describeIn sync_addin Server Function
#' @param input,output,session (shiny) arguments
sync_addin_server <- function(input, output, session) {

  observeEvent(input$close, {
    stopApp()
  })

  observeEvent(input$sync, {
    withProgress({
      incProgress(0.1, "Syncing settings", "Starting sync")
      if (!isTruthy(input$sync_gist_id)) {
        incProgress(0.1, "Syncing settings", "Creating a new gist")
        gist_id <- sync_new()
        updateTextInput(
          inputId = "sync_gist_id",
          value   = gist_id
        )
        showNotification("Created new gist!")
      } else {
        incProgress(0.1, "Syncing settings", "Syncing with existing gist")
        sync_existing(gist_id = input$sync_gist_id)
      }
      setProgress(1.0, "Syncing settings", "Complete")
    })
    showNotification("Syncing complete")
  })

  observeEvent(input$reset, {
    sync_gist_id_reset()
    updateTextInput(
      inputId = "sync_gist_id",
      value   = ""
    )
    showNotification("Gist ID has been reset.")
  })

}

#' @describeIn sync_addin Gist ID checker
#' If no value is supplied, then retrieves the stored gist ID. If a value is
#' supplied, then writes the Gist ID into a text file defined by the user
#' directory.
#' @param gist_id (str) Gist ID to sync with, NULL if none.
sync_gist_id <- function(gist_id = NULL) {

  sync_gist_id_file <- pkg_user("sync_gist_id")

  if (is.null(gist_id)) {
    if (!file_exists(sync_gist_id_file)) {
      return(NULL)
    } else {
      return(readLines(sync_gist_id_file))
    }
  } else {
    assert_string(gist_id)
    dir_create(pkg_user())
    writeLines(gist_id, sync_gist_id_file)
  }

  return(gist_id)

}

#' @describeIn sync_addin Reset the Gist ID
sync_gist_id_reset <- function() {

  sync_gist_id_file <- pkg_user("sync_gist_id")
  if (file_exists(sync_gist_id_file)) {
    file_delete(sync_gist_id_file)
  }

}

#' @describeIn sync_addin RStudio Config Directory
sync_config_dir <- function() {

  path.expand("~/.config/rstudio/")

}

#' @describeIn sync_addin Sync a new gist
#' This is used by the addin if there is no gist ID specified. It creates a new
#' gist and uploads the files into the gist. It does this in a weird way
#' (one-by-one) because sometimes the gist contents are truncated.
sync_new <- function() {

  upload_dir <-
    pkg_temp("settings", "upload") %T>%
    unlink() %>%
    dir_create()

  config_files <-
    dir_info(
      path = sync_config_dir(),
      type = "file",
      recurse = TRUE
    ) %>%
    mutate(
      upload_path = path %>%
        str_remove(sync_config_dir()) %>%
        str_remove("^/+") %>%
        str_replace_all("/", "*||*"),
      upload_full_path = file.path(upload_dir, upload_path)
    )

  config_files %>%
    mutate(
      copy_file = map2(
        path, upload_full_path,
        ~file_copy(.x, .y, overwrite = TRUE)
      )
    )

  settings.gist <-
    gist_create(
      files = config_files$upload_full_path[1],
      description = "Settings Sync",
      browse = FALSE,
      public = FALSE
    )

  config_files$upload_full_path %>%
    .[2:length(.)] %>%
    map(
      function(file, gist) {
        gist %>%
          add_files(file) %>%
          update()
      },
      gist = settings.gist
    )

  sync_gist_id(settings.gist$id)

}

#' @describeIn sync_addin Sync and existing Gist
#' This is used when there is an existing configuraiton. It uses the last
#' modified timestamp of each file to determine whether it is more or less
#' updated than the gist file, and then syncs those changes.
sync_existing <- function(gist_id = NULL) {

  download_dir <-
    pkg_temp("settings", "download") %T>%
    unlink() %>%
    dir_create()

  upload_dir <-
    pkg_temp("settings", "upload") %T>%
    unlink() %>%
    dir_create()

  settings.gist <-
    sync_gist_id(gist_id = gist_id) %>%
    gist()

  settings.gist$files %>%
    map(quietly(function(file) {
      file_path <- file.path(download_dir, file$filename)
      message(file_path)
      if (!file$truncated) {
        writeLines(file$content, file_path)
      } else {
        download.file(file$raw_url, file_path, quiet = TRUE, cacheOK = FALSE)
      }
    }))

  config_files <-
    dir_info(download_dir) %>%
    mutate(
      config_slug = path %>%
        str_remove(download_dir) %>%
        str_remove("^/"),
      config_path = config_slug %>%
        { file.path(sync_config_dir(), .) } %>%
        str_replace_all("\\*\\|\\|\\*", "/")
    ) %>%
    mutate(
      is_new = unname(!file_exists(config_path)),
      config_file_info = map(config_path, file_info),
      config_file_updated_at =
        map_dbl(config_file_info, "modification_time") %>%
        as_datetime(),
      gist_updated_at = as_datetime(settings.gist$updated_at),
      is_changed = pmap_lgl(
        list(path, config_path, is_new),
        function(path, config_path, is_new) {
          if (is_new) return(FALSE)
          !identical(
            readLines(path, warn = FALSE),
            readLines(config_path, warn = FALSE)
          )
        }
      ),
      is_outdated = is_changed & gist_updated_at > config_file_updated_at,
      is_updated  = is_changed & config_file_updated_at > gist_updated_at
    ) %>%
    mutate(
      upload_path = config_path %>%
        str_remove(sync_config_dir()) %>%
        str_remove("^/+") %>%
        str_replace_all("/", "*||*"),
      upload_full_path =
        file.path(upload_dir, upload_path)
    )

  if (any(config_files$is_new)) {

    config_files %>%
      filter(is_new) %>%
      mutate(
        copy_file = map2(
          path, config_path,
          ~file_copy(.x, .y, overwrite = TRUE)
        )
      )

  }

  if (any(config_files$is_outdated)) {

    config_files %>%
      filter(is_outdated) %>%
      mutate(
        copy_file = map2(
          path, config_path,
          ~file_copy(.x, .y, overwrite = TRUE)
        )
      )

  }

  if (any(config_files$is_updated)) {

    config_files %>%
      filter(is_updated) %>%
      mutate(
        copy_file = map2(
          config_path, upload_full_path,
          ~file_copy(.x, .y, overwrite = TRUE)
        )
      ) %>%
      pull(upload_full_path) %>%
      map(
        function(path, gist) {
          gist %>%
            update_files(path) %>%
            update()
        },
        gist = settings.gist
      )

  }

  return(config_files)

}
