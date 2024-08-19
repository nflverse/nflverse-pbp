season <- Sys.getenv("NFLVERSE_UPDATE_SEASON", unset = NA_character_) |> as.integer()
type <- Sys.getenv("NFLVERSE_UPDATE_TYPE", unset = NA_character_)
type <- rlang::arg_match0(
  type,
  c("pbp", "pbp_stats", "ps_off", "ps_def", "ps_kick", "laterals",
    "participation", "ps_off_comb", "ps_def_comb", "ps_kick_comb")
)

# Run parallel
future::plan(future.mirai::mirai_multisession)
options(nflreadr.verbose = FALSE)
source("R/update_pbp.R")
source("R/update_playstats.R")
source("R/update_player_stats.R")
source("R/update_multiple_laterals.R")
source("R/update_pbp_participation.R")

release <- switch (
  type,
  "pbp" = release_pbp,
  "pbp_stats" = release_pbp_stats,
  "ps_off" = release_playerstats_offense,
  "ps_off_comb" = release_playerstats_offense_combined,
  "ps_def" = release_playerstats_defense,
  "ps_def_comb" = release_playerstats_defense_combined,
  "ps_kick" = release_playerstats_kicking,
  "ps_kick_comb" = release_playerstats_kicking_combined,
  "laterals" = release_lateral_yards,
  "participation" = release_pbp_participation
)
release(season)
