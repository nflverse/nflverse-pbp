rm(list = ls())
gc()
`%>%` <- magrittr::`%>%`

cli::cli_alert_info("Read pbp...")

ps_season <- function(season){
  cli::cli_process_start("Starting calculate_player_stats for {season}!")

  ps <- qs::qread(glue::glue("data/play_by_play_{season}.qs")) |>
    nflfastR::calculate_player_stats(weekly = TRUE)

  attr(ps, "nflverse_timestamp") <- Sys.time()
  attr(ps, "nflverse_type") <- "player stats: offense"
  attr(ps, "nflfastR_version") <- packageVersion("nflfastR")

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

attr(stats_df, "nflverse_timestamp") <- Sys.time()
attr(stats_df, "nflverse_type") <- "player stats: offense"
attr(stats_df, "nflfastR_version") <- packageVersion("nflfastR")

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

list.files("data/player_stats", full.names = TRUE) |>
  nflversedata::nflverse_upload("player_stats")
