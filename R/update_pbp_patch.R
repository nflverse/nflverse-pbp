#### Build PBP ID patch file ####
build_pbp_patch <- function(season = nflreadr::most_recent_season()){

  games <- dplyr::bind_rows(
    ngsscrapR::scrape_schedule(season, seasonType = "REG"),
    ngsscrapR::scrape_schedule(season, seasonType = "POST")
  ) |>
    dplyr::filter(!is.na(score_phase)) |>
    dplyr::transmute(
      game_id = as.character(game_id),
      nflverse_game_id = paste(season,
                               stringr::str_pad(week,2,side = "left",0),
                               visitor_team_abbr,
                               home_team_abbr,
                               sep = "_")
    )

  progressr::with_progress({
    p <- progressr::progressor(steps = length(games$game_id))
    ngs_pbp <- furrr::future_map_dfr(
      games$game_id,
      ngsscrapR::scrape_plays |> nflreadr::progressively(p))
  })

  ngspbp_playerids <- ngs_pbp |>
    dplyr::select(game_id,play_id,matches("^club_code|^player_name|^gsis_id")) |>
    tidyr::pivot_longer(
      cols = -c(game_id,play_id),
      names_to = c(".value",NA),
      names_pattern = "(club_code|player_name|gsis_id)_(.+)",
      values_drop_na = TRUE
    ) |>
    dplyr::filter(gsis_id != "NA") |>
    tidyr::separate_rows(club_code, player_name, gsis_id, sep = ";") |>
    dplyr::distinct() |>
    dplyr::mutate(game_id = as.character(game_id)) |>
    dplyr::left_join(games, by = "game_id") |>
    dplyr::select(game_id = nflverse_game_id,
                  play_id,
                  name = player_name,
                  gsis_id,
                  club_code)

  nflversedata::nflverse_save(
    data_frame = ngspbp_playerids,
    file_name = glue::glue("pbp_patch_ids_{season}"),
    nflverse_type = "pbp gsis_id patch file",
    release_tag = "misc",
    file_types = "rds")

}

future::plan(future::multisession)
build_pbp_patch(nflreadr::most_recent_season())
