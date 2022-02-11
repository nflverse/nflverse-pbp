rm(list = ls())
gc()
`%>%` <- magrittr::`%>%`
# future::plan("multicore")

cli::cli_alert_info("Read pbp...")

# pbp_df <- furrr::future_map_dfr(1999:nflfastR:::most_recent_season(), function(x){
#   qs::qread(glue::glue("data/play_by_play_{x}.qs"))
# })
#
# cli::cli_alert_info("Compute weekly stats...")
# stats_df <- nflfastR::calculate_player_stats(pbp_df, weekly = TRUE)

ps_season <- function(season){
  cli::cli_process_start("Starting calculate_player_stats for {season}!")

  ps <- qs::qread(glue::glue("data/play_by_play_{season}.qs")) |>
    nflfastR::calculate_player_stats(weekly = TRUE)

  saveRDS(ps,glue::glue("data/player_stats/player_stats_{season}.rds"))
  readr::write_csv(ps,glue::glue("data/player_stats/player_stats_{season}.csv.gz"))
  arrow::write_parquet(ps,glue::glue("data/player_stats/player_stats_{season}.parquet"))
  qs::qsave(ps, glue::glue('data/player_stats/player_stats_{season}.qs'),
            preset = "custom",
            algorithm = "zstd_stream",
            compress_level = 22,
            shuffle_control = 15)
  rm(ps)
  gc()

  cli::cli_process_done(msg_done = "Finished calculate_player_stats for {season}!")
  return(NULL)
}

# purrr::map(1999:2020, ps_season)

ps_season(nflreadr:::most_recent_season())

cli::cli_alert_info("Saving combined data...")

stats_df <- purrr::map_dfr(1999:nflreadr:::most_recent_season(),
                           ~qs::qread(glue::glue("data/player_stats/player_stats_{.x}.qs")))

# rds
saveRDS(stats_df, 'data/player_stats.rds')
# csv.gz
readr::write_csv(stats_df, 'data/player_stats.csv.gz')
# .parquet
arrow::write_parquet(stats_df, 'data/player_stats.parquet')
# .qs
qs::qsave(stats_df, 'data/player_stats.qs',
          preset = "custom",
          algorithm = "zstd_stream",
          compress_level = 22,
          shuffle_control = 15)

c("data/player_stats.qs",
  "data/player_stats.rds",
  "data/player_stats.csv.gz",
  "data/player_stats.parquet") |>
  nflversedata::nflverse_upload("player_stats")

list.files("data/player_stats", full.names = TRUE) |> nflversedata::nflverse_upload("player_stats")

# cli::cli_alert_info("Commit and finish...")
# message <- sprintf("Updated %s (ET) using nflfastR version %s", lubridate::now("America/New_York"), utils::packageVersion("nflfastR"))
#
# git <- function(..., echo_cmd = TRUE, echo = TRUE, error_on_status = FALSE) {
#   callr::run("git", c(...),
#              echo_cmd = echo_cmd, echo = echo,
#              error_on_status = error_on_status
#   )
# }
#
# git("commit", "-am", message)
