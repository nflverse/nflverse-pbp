season <- Sys.getenv("NFLVERSE_UPDATE_SEASON", unset = NA_character_) |> as.integer()
type <- Sys.getenv("NFLVERSE_UPDATE_TYPE", unset = NA_character_)
type <- rlang::arg_match0(
  type,
  c("pbp", "pbp_stats", "stats")
)

# Run parallel
future::plan("multisession")
options(nflreadr.verbose = FALSE)
source("R/update_pbp.R")
source("R/update_playstats.R")
source("R/update_stats.R")

release <- switch (
  type,
  "pbp" = release_pbp,
  "pbp_stats" = release_pbp_stats,
  "stats" = release_stats
)
release(season)
