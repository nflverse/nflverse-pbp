source("R/save_pbp.R")

save_pbp(nflreadr::most_recent_season())

list.files("data", pattern = paste0("play_by_play_",y), full.names = TRUE) |> nflversedata::nflverse_upload("pbp")
