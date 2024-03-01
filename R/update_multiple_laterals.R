release_lateral_yards <- function(...){
  cli::cli_progress_step("Release multiple lateral yards data...")
  all_stat_ids <-
    purrr::map(
      seq(1999, nflreadr::most_recent_season()),
      ~ nflreadr::rds_from_url(glue::glue("https://github.com/nflverse/nflverse-pbp/releases/download/playstats/play_stats_{.x}.rds")),
      .progress = TRUE
    ) |>
    purrr::list_rbind()

  multiple_laterals <- all_stat_ids |>
    dplyr::filter(stat_id %in% c(12, 13, 23, 24)) |>
    dplyr::group_by(game_id, play_id) |>
    dplyr::filter(dplyr::n() > 1) |>
    dplyr::ungroup() |>
    dplyr::mutate(
      type = dplyr::if_else(stat_id %in% 12:13, "lateral_rushing", "lateral_receiving", missing = NA_character_)
    ) |>
    dplyr::select(tidyselect::any_of(c(
      "game_id", "play_id", "stat_id", "type", "yards",
      "team_abbr", "player_name", "gsis_player_id"
    )))

  nflversedata::nflverse_save(
    data_frame = multiple_laterals,
    file_name = "multiple_lateral_yards",
    nflverse_type = "multiple_lateral_yards",
    release_tag = "misc",
    file_types = c("rds", "csv")
  )

  cli::cli_progress_done()
  invisible(NULL)

}
