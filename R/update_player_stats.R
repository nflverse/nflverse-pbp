
# OFFENSE -----------------------------------------------------------------

release_playerstats_offense <- function(season){
  cli::cli_progress_step("Starting {.fct nflfastR::calculate_player_stats} for {season}!")

  pbp <- nflreadr::load_pbp(season)

  # WEEK LEVEL SUMMARY #########################################################

  ps_weekly <- pbp |>
    nflfastR::calculate_player_stats(weekly = TRUE)
  attr(ps_weekly, "nflfastR_version") <- packageVersion("nflfastR")


  # SEASON LEVEL SUMMARY #######################################################

  ps_reg_season <- pbp |>
    dplyr::filter(season_type == "REG") |>
    nflfastR::calculate_player_stats(weekly = FALSE) |>
    dplyr::mutate(
      season_type = "REG"
    )

  ps_post_season <- pbp |>
    dplyr::filter(season_type == "POST") |>
    nflfastR::calculate_player_stats(weekly = FALSE) |>
    dplyr::mutate(
      season_type = "POST"
    )

  ps_all_season <- pbp |>
    nflfastR::calculate_player_stats(weekly = FALSE) |>
    dplyr::mutate(
      season_type = "REG+POST"
    )

  ps_season <- dplyr::bind_rows(ps_reg_season, ps_post_season, ps_all_season)

  attr(ps_season, "nflfastR_version") <- packageVersion("nflfastR")


  # RELEASE ####################################################################

  nflversedata::nflverse_save(
    data_frame = ps_weekly,
    file_name =  glue::glue("player_stats_{season}"),
    nflverse_type = "player stats: offense",
    release_tag = "player_stats",
    file_types = c("rds","csv","parquet","qs", "csv.gz")
  )

  nflversedata::nflverse_save(
    data_frame = ps_season,
    file_name =  glue::glue("player_stats_season_{season}"),
    nflverse_type = "player stats: offense (season)",
    release_tag = "player_stats",
    file_types = c("rds","csv","parquet","qs", "csv.gz")
  )

  cli::cli_progress_done()
  invisible(NULL)
}

release_playerstats_offense_combined <- function(...){
  cli::cli_progress_step("Release combined offensive player stats...")

  # COMBINE WEEK LEVEL STATS ###################################################

  stats_df_week <-
    purrr::map(
      seq(1999, nflreadr::most_recent_season()),
      ~ nflreadr::qs_from_url(glue::glue("https://github.com/nflverse/nflverse-data/releases/download/player_stats/player_stats_{.x}.qs"))
    ) |>
    purrr::list_rbind()

  attr(stats_df, "nflfastR_version") <- packageVersion("nflfastR")


  # COMBINE SEASON LEVEL STATS #################################################

  stats_df_season <-
    purrr::map(
      seq(1999, nflreadr::most_recent_season()),
      ~ nflreadr::qs_from_url(glue::glue("https://github.com/nflverse/nflverse-data/releases/download/player_stats/player_stats_season_{.x}.qs"))
    ) |>
    purrr::list_rbind()

  attr(stats_df_season, "nflfastR_version") <- packageVersion("nflfastR")

  # RELEASE ####################################################################

  nflversedata::nflverse_save(
    data_frame = stats_df,
    file_name =  "player_stats",
    nflverse_type = "player stats: offense",
    release_tag = "player_stats",
    file_types = c("rds","csv","parquet","qs", "csv.gz")
  )

  nflversedata::nflverse_save(
    data_frame = stats_df_season,
    file_name =  "player_stats_season",
    nflverse_type = "player stats: offense (season)",
    release_tag = "player_stats",
    file_types = c("rds","csv","parquet","qs", "csv.gz")
  )

  cli::cli_progress_done()
  invisible(NULL)

}


# DEFENSE -----------------------------------------------------------------

release_playerstats_defense <- function(season) {
  cli::cli_progress_step("Starting {.fct nflfastR::calculate_player_stats_def} for {season}!")

  pbp <- nflreadr::load_pbp(season)

  # WEEK LEVEL SUMMARY #########################################################

  ps_weekly <- pbp |>
    nflfastR::calculate_player_stats_def(weekly = TRUE)
  attr(ps_weekly, "nflfastR_version") <- packageVersion("nflfastR")


  # SEASON LEVEL SUMMARY #######################################################

  ps_reg_season <- pbp |>
    dplyr::filter(season_type == "REG") |>
    nflfastR::calculate_player_stats_def(weekly = FALSE) |>
    dplyr::mutate(
      season_type = "REG"
    )

  ps_post_season <- pbp |>
    dplyr::filter(season_type == "POST") |>
    nflfastR::calculate_player_stats_def(weekly = FALSE) |>
    dplyr::mutate(
      season_type = "POST"
    )

  ps_all_season <- pbp |>
    nflfastR::calculate_player_stats_def(weekly = FALSE) |>
    dplyr::mutate(
      season_type = "REG+POST"
    )

  ps_season <- dplyr::bind_rows(ps_reg_season, ps_post_season, ps_all_season)

  attr(ps_season, "nflfastR_version") <- packageVersion("nflfastR")


  # RELEASE ####################################################################

  nflversedata::nflverse_save(
    data_frame = ps_weekly,
    file_name = glue::glue("player_stats_def_{season}"),
    nflverse_type = "player stats: defense",
    release_tag = "player_stats",
    file_types = c("rds", "csv", "parquet", "qs", "csv.gz")
  )

  nflversedata::nflverse_save(
    data_frame = ps_season,
    file_name =  glue::glue("player_stats_def_season_{season}"),
    nflverse_type = "player stats: defense (season)",
    release_tag = "player_stats",
    file_types = c("rds","csv","parquet","qs", "csv.gz")
  )

  cli::cli_progress_done()
  invisible(NULL)
}

release_playerstats_defense_combined <- function(...){
  cli::cli_progress_step("Release combined defensive player stats...")

  # COMBINE WEEK LEVEL STATS ###################################################

  stats_df_week <-
    purrr::map(
      seq(1999, nflreadr::most_recent_season()),
      ~ nflreadr::qs_from_url(glue::glue("https://github.com/nflverse/nflverse-data/releases/download/player_stats/player_stats_def_{.x}.qs"))
    ) |>
    purrr::list_rbind()

  attr(stats_df, "nflfastR_version") <- packageVersion("nflfastR")


  # COMBINE SEASON LEVEL STATS #################################################

  stats_df_season <-
    purrr::map(
      seq(1999, nflreadr::most_recent_season()),
      ~ nflreadr::qs_from_url(glue::glue("https://github.com/nflverse/nflverse-data/releases/download/player_stats/player_stats_def_season_{.x}.qs"))
    ) |>
    purrr::list_rbind()

  attr(stats_df_season, "nflfastR_version") <- packageVersion("nflfastR")

  # RELEASE ####################################################################

  nflversedata::nflverse_save(
    data_frame = stats_df,
    file_name = "player_stats_def",
    nflverse_type = "player stats: defense",
    release_tag = "player_stats",
    file_types = c("rds", "csv", "parquet", "qs", "csv.gz")
  )

  nflversedata::nflverse_save(
    data_frame = stats_df_season,
    file_name = "player_stats_def_season",
    nflverse_type = "player stats: defense (season)",
    release_tag = "player_stats",
    file_types = c("rds", "csv", "parquet", "qs", "csv.gz")
  )

  cli::cli_progress_done()
  invisible(NULL)

}


# KICKING -----------------------------------------------------------------

release_playerstats_kicking <- function(season) {
  cli::cli_progress_step("Starting {.fct nflfastR::calculate_player_stats_kicking} for {season}!")

  pbp <- nflreadr::load_pbp(season)

  # WEEK LEVEL SUMMARY #########################################################

  ps_weekly <- pbp |>
    nflfastR::calculate_player_stats_kicking(weekly = TRUE)
  attr(ps_weekly, "nflfastR_version") <- packageVersion("nflfastR")


  # SEASON LEVEL SUMMARY #######################################################

  ps_reg_season <- pbp |>
    dplyr::filter(season_type == "REG") |>
    nflfastR::calculate_player_stats_kicking(weekly = FALSE) |>
    dplyr::mutate(
      season_type = "REG"
    )

  ps_post_season <- pbp |>
    dplyr::filter(season_type == "POST") |>
    nflfastR::calculate_player_stats_kicking(weekly = FALSE) |>
    dplyr::mutate(
      season_type = "POST"
    )

  ps_all_season <- pbp |>
    nflfastR::calculate_player_stats_kicking(weekly = FALSE) |>
    dplyr::mutate(
      season_type = "REG+POST"
    )

  ps_season <- dplyr::bind_rows(ps_reg_season, ps_post_season, ps_all_season)

  attr(ps_season, "nflfastR_version") <- packageVersion("nflfastR")


  # RELEASE ####################################################################

  nflversedata::nflverse_save(
    ps_weekly,
    file_name = glue::glue("player_stats_kicking_{season}"),
    nflverse_type = "player stats: kicking",
    release_tag = "player_stats",
    file_types = c("rds", "csv", "parquet", "qs", "csv.gz")
  )

  nflversedata::nflverse_save(
    ps_season,
    file_name = glue::glue("player_stats_kicking_season_{season}"),
    nflverse_type = "player stats: kicking (season)",
    release_tag = "player_stats",
    file_types = c("rds", "csv", "parquet", "qs", "csv.gz")
  )

  cli::cli_progress_done()
  invisible(NULL)
}

release_playerstats_kicking_combined <- function(...){
  cli::cli_progress_step("Release combined kicking stats...")

  # COMBINE WEEK LEVEL STATS ###################################################

  stats_df_week <-
    purrr::map(
      seq(1999, nflreadr::most_recent_season()),
      ~ nflreadr::qs_from_url(glue::glue("https://github.com/nflverse/nflverse-data/releases/download/player_stats/player_stats_kicking_{.x}.qs"))
    ) |>
    purrr::list_rbind()

  attr(stats_df, "nflfastR_version") <- packageVersion("nflfastR")


  # COMBINE SEASON LEVEL STATS #################################################

  stats_df_season <-
    purrr::map(
      seq(1999, nflreadr::most_recent_season()),
      ~ nflreadr::qs_from_url(glue::glue("https://github.com/nflverse/nflverse-data/releases/download/player_stats/player_stats_kicking_season_{.x}.qs"))
    ) |>
    purrr::list_rbind()

  attr(stats_df_season, "nflfastR_version") <- packageVersion("nflfastR")

  # RELEASE ####################################################################

  nflversedata::nflverse_save(
    data_frame = stats_df,
    file_name =  "player_stats_kicking",
    nflverse_type = "player stats: kicking",
    release_tag = "player_stats",
    file_types = c("rds", "csv", "parquet", "qs", "csv.gz")
  )

  nflversedata::nflverse_save(
    data_frame = stats_df_season,
    file_name =  "player_stats_kicking_season",
    nflverse_type = "player stats: kicking (season)",
    release_tag = "player_stats",
    file_types = c("rds", "csv", "parquet", "qs", "csv.gz")
  )

  cli::cli_progress_done()
  invisible(NULL)

}
