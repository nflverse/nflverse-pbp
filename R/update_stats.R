release_stats <- function(season){
  cli::cli_progress_step("Starting {.fct nflfastR::calculate_stats} for {season}!")

  # WEEK LEVEL SUMMARY #########################################################

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

  if (nrow(stats_week_player) > 0){
    nflversedata::nflverse_save(
      data_frame = stats_week_player,
      file_name =  glue::glue("stats_player_week_{season}"),
      nflverse_type = "player stats: week level",
      release_tag = "player_stats",
      file_types = c("rds", "csv", "parquet", "qs", "csv.gz")
    )
  }

  if (nrow(stats_week_team) > 0){
    nflversedata::nflverse_save(
      data_frame = stats_week_team,
      file_name =  glue::glue("stats_team_week_{season}"),
      nflverse_type = "team stats: week level",
      release_tag = "player_stats",
      file_types = c("rds", "csv", "parquet", "qs", "csv.gz")
    )
  }

  # PLAYER SEASON LEVEL SUMMARY ################################################

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

  if (nrow(stats_reg_player) > 0){
    nflversedata::nflverse_save(
      data_frame = stats_reg_player,
      file_name =  glue::glue("stats_player_reg_{season}"),
      nflverse_type = "player stats: season level",
      release_tag = "player_stats",
      file_types = c("rds", "csv", "parquet", "qs", "csv.gz")
    )
  }

  if (nrow(stats_post_player) > 0){
    nflversedata::nflverse_save(
      data_frame = stats_post_player,
      file_name =  glue::glue("stats_player_post_{season}"),
      nflverse_type = "team stats: season level",
      release_tag = "player_stats",
      file_types = c("rds", "csv", "parquet", "qs", "csv.gz")
    )
  }

  if (nrow(stats_regpost_player) > 0){
    nflversedata::nflverse_save(
      data_frame = stats_regpost_player,
      file_name =  glue::glue("stats_player_regpost_{season}"),
      nflverse_type = "team stats: season level",
      release_tag = "player_stats",
      file_types = c("rds", "csv", "parquet", "qs", "csv.gz")
    )
  }

  # TEAM SEASON LEVEL SUMMARY ##################################################

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

  if (nrow(stats_reg_team) > 0){
    nflversedata::nflverse_save(
      data_frame = stats_reg_team,
      file_name =  glue::glue("stats_team_reg_{season}"),
      nflverse_type = "player stats: season level",
      release_tag = "player_stats",
      file_types = c("rds", "csv", "parquet", "qs", "csv.gz")
    )
  }

  if (nrow(stats_post_team) > 0){
    nflversedata::nflverse_save(
      data_frame = stats_post_team,
      file_name =  glue::glue("stats_team_post_{season}"),
      nflverse_type = "team stats: season level",
      release_tag = "player_stats",
      file_types = c("rds", "csv", "parquet", "qs", "csv.gz")
    )
  }

  if (nrow(stats_regpost_team) > 0){
    nflversedata::nflverse_save(
      data_frame = stats_regpost_team,
      file_name =  glue::glue("stats_team_regpost_{season}"),
      nflverse_type = "team stats: season level",
      release_tag = "player_stats",
      file_types = c("rds", "csv", "parquet", "qs", "csv.gz")
    )
  }

  cli::cli_progress_done()
  invisible(NULL)
}
