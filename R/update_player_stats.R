ps_season <- function(season){
  cli::cli_process_start("Starting calculate_player_stats for {season}!")

  ps <- nflreadr::load_pbp(season) |>
    nflfastR::calculate_player_stats(weekly = TRUE)

  attr(ps, "nflfastR_version") <- packageVersion("nflfastR")
  
  nflversedata::nflverse_save(
    data_frame = ps,
    file_name =  glue::glue("player_stats_{season}"),
    nflverse_type = "player stats: offense",
    release_tag = "player_stats",
    file_types = c("rds","csv","parquet","qs", "csv.gz")
  )

  cli::cli_process_done(msg_done = "Finished calculating player weekly stats for {season}!")
  return(invisible(NULL))
}

if(Sys.getenv("NFLVERSE_REBUILD","false")=="true"){
  purrr::map(1999:nflreadr:::most_recent_season(), ps_season)
} else {
  ps_season(nflreadr:::most_recent_season())
}

cli::cli_alert_info("Saving combined data...")
stats_df <- purrr::map_dfr(
  1999:nflreadr::most_recent_season(), 
  ~nflreadr::rds_from_url(glue::glue("https://github.com/nflverse/nflverse-data/releases/download/player_stats/player_stats_{.x}.rds"))
)

attr(stats_df, "nflfastR_version") <- packageVersion("nflfastR")

  nflversedata::nflverse_save(
    data_frame = stats_df,
    file_name =  glue::glue("player_stats"),
    nflverse_type = "player stats: offense",
    release_tag = "player_stats",
    file_types = c("rds","csv","parquet","qs", "csv.gz")
  )
