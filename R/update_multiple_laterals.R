save_lateral_yards <- function(s) {
  future::plan("multisession")

  games <- nflreadr::load_schedules(s) |>
    dplyr::filter(!is.na(result))

  if(length(games$game_id) == 0){
    cli::cli_alert_info("No games yet, nothing to do")
    return(invisible(NULL))
  }

  cli::cli_alert_info("Load {.val {length(games$game_id)}} game{?s} of {.val {s}}")

  load <- furrr::future_map_dfr(games$game_id, check_lateral_yards)

  cli::cli_alert_info("Process raw data...")

  all <-
    dplyr::bind_rows(
      readr::read_csv("lateral_yards/multiple_lateral_yards.csv", show_col_types = FALSE),
      load |>
        nflfastR::decode_player_ids() |>
        dplyr::group_by(game_id, play_id) |>
        dplyr::filter(dplyr::n() > 1) |>
        dplyr::ungroup() |>
        suppressMessages()
    ) |>
    dplyr::distinct() |>
    dplyr::arrange(game_id, play_id)

  cli::cli_alert_info("Save multiple lateral plays...")

  readr::write_csv(all, "lateral_yards/multiple_lateral_yards.csv")
  future::plan("sequential")
  cli::cli_alert_info("DONE!")
  return(invisible(all))
}

check_lateral_yards <- function(id){
  cli::cli_progress_step("Loading {id}")
  season <- substr(id, 1, 4)
  base_url <- "https://github.com/nflverse/nflfastR-raw/raw/master/raw"
  load_url <- file.path(base_url, season, paste0(id, ".rds"))
  raw_data <- nflreadr::rds_from_url(load_url)
  plays <- janitor::clean_names(raw_data[[1]][[1]]$gameDetail$plays) |>
    dplyr::select(play_id, play_stats)
  stats <- tidyr::unnest(plays, cols = c("play_stats")) |>
    janitor::clean_names() |>
    dplyr::filter(stat_id %in% c(12, 13, 23, 24)) |>
    dplyr::mutate(
      game_id = as.character(id),
      type = dplyr::if_else(stat_id %in% 12:13, "lateral_rushing", "lateral_receiving", missing = NA_character_)
    ) |>
    dplyr::select(
      "game_id",
      "play_id",
      "stat_id",
      "type",
      "yards",
      "team_abbr" = "team_abbreviation",
      "player_name",
      "gsis_player_id"
    )

  return(stats)
}

save_lateral_yards(nflreadr::most_recent_season())
