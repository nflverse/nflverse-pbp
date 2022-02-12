source("R/save_pbp.R")

purrr::walk(1999:nflreadr::most_recent_season(), save_pbp)

list.files("data", pattern = "play_by_play", full.names = TRUE) |>
  nflversedata::nflverse_upload("pbp")


