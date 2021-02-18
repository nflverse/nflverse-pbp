`%>%` <- magrittr::`%>%`
future::plan("multisession")

pbp_df <- furrr::future_map_dfr(1999:nflfastR:::most_recent_season(), function(x){
  qs::qread(glue::glue("data/play_by_play_{x}.qs"))
})

stats_df <- nflfastR::calculate_player_stats(pbp_df, weekly = TRUE)

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

message <- sprintf("Updated %s (ET) using nflfastR version %s", lubridate::now("America/New_York"), utils::packageVersion("nflfastR"))

git <- function(..., echo_cmd = TRUE, echo = TRUE, error_on_status = FALSE) {
  callr::run("git", c(...),
             echo_cmd = echo_cmd, echo = echo,
             error_on_status = error_on_status
  )
}

git("commit", "-am", message)
