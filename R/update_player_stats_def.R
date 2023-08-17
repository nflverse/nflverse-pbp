ps_season <- function(season) {
  cli::cli_progress_step("Starting {.fct nflfastR::calculate_player_stats_def} for {season}!")

  ps <- nflreadr::load_pbp(season) |>
    nflfastR::calculate_player_stats_def(weekly = TRUE)

  attr(ps, "nflfastR_version") <- packageVersion("nflfastR")

  nflversedata::nflverse_save(
    data_frame = ps,
    file_name = glue::glue("player_stats_def_{season}"),
    nflverse_type = "player stats: defense",
    release_tag = "player_stats",
    file_types = c("rds", "csv", "parquet", "qs", "csv.gz")
  )

  cli::cli_progress_done()

  invisible(NULL)
}

if (Sys.getenv("NFLVERSE_REBUILD", "false") == "true") {
  purrr::walk(1999:nflreadr:::most_recent_season(), ps_season)
} else {
  ps_season(nflreadr:::most_recent_season())
}

cli::cli_alert_info("Saving combined data...")
stats_df <-
  purrr::map(
    1999:nflreadr::most_recent_season(),
    ~ nflreadr::qs_from_url(glue::glue("https://github.com/nflverse/nflverse-data/releases/download/player_stats/player_stats_def_{.x}.qs"))
  ) |>
  purrr::list_rbind()

attr(stats_df, "nflfastR_version") <- packageVersion("nflfastR")

nflversedata::nflverse_save(
  data_frame = stats_df,
  file_name = "player_stats_def",
  nflverse_type = "player stats: defense",
  release_tag = "player_stats",
  file_types = c("rds", "csv", "parquet", "qs", "csv.gz")
)
