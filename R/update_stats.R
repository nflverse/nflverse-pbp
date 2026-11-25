release_stats <- function(season){
  started <- Sys.time()

  # WEEK LEVEL SUMMARY #########################################################

  # Each step is closed before its uploads start, otherwise cli keeps redrawing
  # the open step below every upload message
  cli::cli_progress_step("Calculating {season} week level player and team stats")

  stats_week_player <- nflfastR::calculate_stats(
    seasons = season,
    summary_level = "week",
    stat_type = "player"
  )
  attr(stats_week_player, "nflfastR_version") <- as.character(packageVersion("nflfastR"))

  stats_week_team <- nflfastR::calculate_stats(
    seasons = season,
    summary_level = "week",
    stat_type = "team"
  )
  attr(stats_week_team, "nflfastR_version") <- as.character(packageVersion("nflfastR"))

  cli::cli_progress_done()

  if (nrow(stats_week_player) > 0){
    nflversedata::nflverse_save(
      data_frame = stats_week_player,
      file_name =  glue::glue("stats_player_week_{season}"),
      nflverse_type = "player stats: week level",
      release_tag = "stats_player",
      file_types = c("rds", "csv", "parquet", "csv.gz"),
      timestamp = FALSE
    )
  }

  if (nrow(stats_week_team) > 0){
    nflversedata::nflverse_save(
      data_frame = stats_week_team,
      file_name =  glue::glue("stats_team_week_{season}"),
      nflverse_type = "team stats: week level",
      release_tag = "stats_team",
      file_types = c("rds", "csv", "parquet", "csv.gz"),
      timestamp = FALSE
    )
  }

  # PLAYER SEASON LEVEL SUMMARY ################################################

  cli::cli_progress_step("Calculating {season} season level player stats (REG, POST, REG+POST)")

  stats_reg_player <- nflfastR::calculate_stats(
    seasons = season,
    summary_level = "season",
    stat_type = "player",
    season_type = "REG"
  )
  attr(stats_reg_player, "nflfastR_version") <- as.character(packageVersion("nflfastR"))

  stats_post_player <- nflfastR::calculate_stats(
    seasons = season,
    summary_level = "season",
    stat_type = "player",
    season_type = "POST"
  )
  attr(stats_post_player, "nflfastR_version") <- as.character(packageVersion("nflfastR"))

  stats_regpost_player <- nflfastR::calculate_stats(
    seasons = season,
    summary_level = "season",
    stat_type = "player",
    season_type = "REG+POST"
  )
  attr(stats_regpost_player, "nflfastR_version") <- as.character(packageVersion("nflfastR"))

  cli::cli_progress_done()

  if (nrow(stats_reg_player) > 0){
    nflversedata::nflverse_save(
      data_frame = stats_reg_player,
      file_name =  glue::glue("stats_player_reg_{season}"),
      nflverse_type = "player stats: REG season",
      release_tag = "stats_player",
      file_types = c("rds", "csv", "parquet", "csv.gz"),
      timestamp = FALSE
    )
  }

  if (nrow(stats_post_player) > 0){
    nflversedata::nflverse_save(
      data_frame = stats_post_player,
      file_name =  glue::glue("stats_player_post_{season}"),
      nflverse_type = "player stats: POST season",
      release_tag = "stats_player",
      file_types = c("rds", "csv", "parquet", "csv.gz"),
      timestamp = FALSE
    )
  }

  if (nrow(stats_regpost_player) > 0){
    nflversedata::nflverse_save(
      data_frame = stats_regpost_player,
      file_name =  glue::glue("stats_player_regpost_{season}"),
      nflverse_type = "player stats: REG+POST season",
      release_tag = "stats_player",
      file_types = c("rds", "csv", "parquet", "csv.gz"),
      timestamp = FALSE
    )
  }

  # TEAM SEASON LEVEL SUMMARY ##################################################

  cli::cli_progress_step("Calculating {season} season level team stats (REG, POST, REG+POST)")

  stats_reg_team <- nflfastR::calculate_stats(
    seasons = season,
    summary_level = "season",
    stat_type = "team",
    season_type = "REG"
  )
  attr(stats_reg_team, "nflfastR_version") <- as.character(packageVersion("nflfastR"))

  stats_post_team <- nflfastR::calculate_stats(
    seasons = season,
    summary_level = "season",
    stat_type = "team",
    season_type = "POST"
  )
  attr(stats_post_team, "nflfastR_version") <- as.character(packageVersion("nflfastR"))

  stats_regpost_team <- nflfastR::calculate_stats(
    seasons = season,
    summary_level = "season",
    stat_type = "team",
    season_type = "REG+POST"
  )
  attr(stats_regpost_team, "nflfastR_version") <- as.character(packageVersion("nflfastR"))

  cli::cli_progress_done()

  if (nrow(stats_reg_team) > 0){
    nflversedata::nflverse_save(
      data_frame = stats_reg_team,
      file_name =  glue::glue("stats_team_reg_{season}"),
      nflverse_type = "team stats: REG season",
      release_tag = "stats_team",
      file_types = c("rds", "csv", "parquet", "csv.gz"),
      timestamp = FALSE
    )
  }

  if (nrow(stats_post_team) > 0){
    nflversedata::nflverse_save(
      data_frame = stats_post_team,
      file_name =  glue::glue("stats_team_post_{season}"),
      nflverse_type = "team stats: POST season",
      release_tag = "stats_team",
      file_types = c("rds", "csv", "parquet", "csv.gz"),
      timestamp = FALSE
    )
  }

  if (nrow(stats_regpost_team) > 0){
    nflversedata::nflverse_save(
      data_frame = stats_regpost_team,
      file_name =  glue::glue("stats_team_regpost_{season}"),
      nflverse_type = "team stats: REG+POST season",
      release_tag = "stats_team",
      file_types = c("rds", "csv", "parquet", "csv.gz"),
      timestamp = FALSE
    )
  }

  # The datasets above were uploaded without the release timestamp files to
  # save requests against GitHub's secondary rate limit. Upload them once per
  # release instead of with every dataset.
  n_player <- nrow(stats_week_player) + nrow(stats_reg_player) +
    nrow(stats_post_player) + nrow(stats_regpost_player)
  n_team <- nrow(stats_week_team) + nrow(stats_reg_team) +
    nrow(stats_post_team) + nrow(stats_regpost_team)
  if (n_player > 0) nflversedata::nflverse_upload_timestamp(tag = "stats_player")
  if (n_team > 0) nflversedata::nflverse_upload_timestamp(tag = "stats_team")

  n_released <- sum(vapply(
    list(
      stats_week_player, stats_week_team,
      stats_reg_player, stats_post_player, stats_regpost_player,
      stats_reg_team, stats_post_team, stats_regpost_team
    ),
    nrow,
    integer(1)
  ) > 0)
  runtime <- format(round(difftime(Sys.time(), started), 1))
  cli::cli_alert_success(
    "Released {season} stats: {n_released} dataset{?s} in {runtime}."
  )
  invisible(NULL)
}
