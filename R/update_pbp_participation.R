pbp_participation <-
  function(season) {
    stopifnot(season >= 2016)
    
    cli::cli_alert_info("Obtaining schedules...")
    games <- dplyr::bind_rows(
      ngsscrapR::scrape_schedule(season, seasonType = "REG"),
      ngsscrapR::scrape_schedule(season, seasonType = "POST")
    )
    
    cli::cli_alert_info("Scraping participation data for {season}...")
    obtain_plays <- function() {
      p <- progressr::progressor(steps = length(games$game_id))
      plays <- purrr::map_dfr(games$game_id,
                              \(x) {
                                pbp <- ngsscrapR::scrape_plays(x)
                                p()
                                return(pbp)
                              })
      return(plays)
    }
    
    progressr::with_progress({
      plays <- obtain_plays()
    })
    
    plays <- plays |>
      dplyr::mutate(game_id = as.character(game_id),
                    players_on_play2 = players_on_play) |>
      dplyr::select(
        old_game_id = game_id,
        week,
        play_id,
        possession_team,
        players_on_play,
        players_on_play2,
        offense_formation = offense_offense_formation,
        offense_personnel,
        defenders_in_box = defense_defenders_in_the_box,
        defense_personnel,
        number_of_pass_rushers = defense_number_of_pass_rushers
      ) |>
      tidyr::separate_rows(players_on_play2, sep = ";") |>
      dplyr::left_join(
        nflreadr::load_players() |>
          dplyr::select(gsis_id, gsis_it_id) |>
          dplyr::mutate_at("gsis_it_id", as.character) |>
          dplyr::distinct(),
        by = c("players_on_play2" = "gsis_it_id"),
        na_matches = "never"
      ) |>
      dplyr::left_join(
        nflreadr::load_rosters_weekly(season) |> dplyr::select(gsis_id, week, team) |> dplyr::distinct(),
        by = c("gsis_id", "week"),
        na_matches = "never"
      ) |>
      dplyr::group_by(
        old_game_id,
        play_id,
        possession_team,
        offense_formation,
        offense_personnel,
        defenders_in_box,
        defense_personnel,
        number_of_pass_rushers,
        players_on_play
      ) |>
      dplyr::summarise(
        offense_players = gsis_id[possession_team == team] |> na.omit() |> paste(collapse = ";"),
        n_offense = gsis_id[possession_team == team] |> na.omit() |> length(),
        defense_players = gsis_id[possession_team != team] |> na.omit() |> paste(collapse = ";"),
        n_defense = gsis_id[possession_team != team] |> na.omit() |> length(),
        .groups = "drop"
      ) |>
      dplyr::ungroup()
    
    cli::cli_process_start("Uploading participation data to nflverse-data")
    
    nflversedata::nflverse_save(
      data_frame = plays,
      file_name = paste0("pbp_participation_", season),
      nflverse_type = "pbp participation",
      release_tag = "pbp_participation"
    )
    
    cli::cli_process_done()
  }

if (Sys.getenv("NFLVERSE_REBUILD", "false") == "true") {
  purrr::walk(c(2016:nflreadr:::most_recent_season()),
              pbp_participation)
} else {
  pbp_participation(nflreadr:::most_recent_season())
}
