source("R/save_pbp.R")

y <- dplyr::if_else(
  lubridate::month(lubridate::today("America/New_York")) >= 9,
  lubridate::year(lubridate::today("America/New_York")) ,
  lubridate::year(lubridate::today("America/New_York")) - 1
)

future::plan("multisession")
purrr::walk(1999:y, save_pbp)

list.files("data", pattern = "play_by_play") |> nflversedata::nflverse_upload("pbp", dir = "data")


