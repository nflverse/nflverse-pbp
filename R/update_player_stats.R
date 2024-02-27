
# OFFENSE -----------------------------------------------------------------

release_playerstats_offense <- function(season){
  cli::cli_progress_step("Starting {.fct nflfastR::calculate_player_stats} for {season}!")

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

  cli::cli_progress_done()
  invisible(NULL)
}

release_playerstats_offense_combined <- function(...){
  cli::cli_progress_step("Release combined offensive player stats...")
  stats_df <-
    purrr::map(
      seq(1999, nflreadr::most_recent_season()),
      ~ nflreadr::qs_from_url(glue::glue("https://github.com/nflverse/nflverse-data/releases/download/player_stats/player_stats_{.x}.qs"))
    ) |>
    purrr::list_rbind()

  attr(stats_df, "nflfastR_version") <- packageVersion("nflfastR")

  nflversedata::nflverse_save(
    data_frame = stats_df,
    file_name =  "player_stats",
    nflverse_type = "player stats: offense",
    release_tag = "player_stats",
    file_types = c("rds","csv","parquet","qs", "csv.gz")
  )

  cli::cli_progress_done()
  invisible(NULL)

}


# DEFENSE -----------------------------------------------------------------

release_playerstats_defense <- function(season) {
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

release_playerstats_defense_combined <- function(...){
  cli::cli_progress_step("Release combined defensive player stats...")
  stats_df <-
    purrr::map(
      seq(1999, nflreadr::most_recent_season()),
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

  cli::cli_progress_done()
  invisible(NULL)

}


# KICKING -----------------------------------------------------------------

release_playerstats_kicking <- function(season) {
  cli::cli_progress_step("Starting {.fct nflfastR::calculate_player_stats_kicking} for {season}!")

  ps <- nflreadr::load_pbp(season) |>
    nflfastR::calculate_player_stats_kicking(weekly = TRUE)

  attr(ps, "nflfastR_version") <- packageVersion("nflfastR")

  nflversedata::nflverse_save(
    ps,
    file_name = glue::glue("player_stats_kicking_{season}"),
    nflverse_type = "player stats: kicking",
    release_tag = "player_stats",
    file_types = c("rds", "csv", "parquet", "qs", "csv.gz")
  )

  cli::cli_progress_done()
  invisible(NULL)
}

release_playerstats_kicking_combined <- function(...){
  cli::cli_progress_step("Release combined kicking stats...")
  stats_df <-
    purrr::map(
      seq(1999, nflreadr::most_recent_season()),
      ~ nflreadr::qs_from_url(glue::glue("https://github.com/nflverse/nflverse-data/releases/download/player_stats/player_stats_kicking_{.x}.qs"))
    ) |>
    purrr::list_rbind()

  attr(stats_df, "nflfastR_version") <- packageVersion("nflfastR")

  nflversedata::nflverse_save(
    data_frame = stats_df,
    file_name =  "player_stats_kicking",
    nflverse_type = "player stats: kicking",
    release_tag = "player_stats",
    file_types = c("rds", "csv", "parquet", "qs", "csv.gz")
  )

  cli::cli_progress_done()
  invisible(NULL)

}
