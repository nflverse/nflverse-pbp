source("R/save_pbp.R")
future::plan(future::multisession)
x <- nflreadr::most_recent_season()
save_pbp(x)

list.files("data", pattern = paste0("play_by_play_",x), full.names = TRUE) |> 
  nflversedata::nflverse_upload("pbp")
