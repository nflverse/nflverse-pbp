release_pbp_participation <- function(season) {
    if (season < 2016){
      cli::cli_alert_warning("No participation data for {.val {season}} season. Abort.")
      return(NULL)
    }

    plays_template <- tibble::tibble(
      nflverse_game_id = character(0),
      old_game_id = character(0),
      play_id = integer(0),
      possession_team = character(0),
      offense_formation = character(0),
      offense_personnel = character(0),
      defenders_in_box = integer(0),
      defense_personnel = character(0),
      number_of_pass_rushers = integer(0),
      players_on_play = character(0),
      offense_players = character(0),
      defense_players = character(0),
      n_offense = integer(0),
      n_defense = integer(0),
      ngs_air_yards = double(0),
      time_to_throw = double(0),
      was_pressure = logical(0),
      route = character(0),
      defense_man_zone_type = character(0),
      defense_coverage_type = character(0)
    )

    cli::cli_alert_info("Obtaining schedules...")
    games <- dplyr::bind_rows(
      ngsscrapR::scrape_schedule(season, seasonType = "REG"),
      ngsscrapR::scrape_schedule(season, seasonType = "POST")
    ) |>
      dplyr::filter(!is.na(score_phase)) |>
      dplyr::transmute(
        game_id = as.character(game_id),
        # SB exception
        week = dplyr::case_when(!!season <  2021 & week == 22 ~ 21,
                                !!season >= 2021 & week == 23 ~ 22,
                                TRUE ~ week),
        nflverse_game_id = paste(season,
                                 stringr::str_pad(week,2,side = "left",0),
                                 visitor_team_abbr,
                                 home_team_abbr,
                                 sep = "_")
      )

    cli::cli_alert_info("Scraping participation data for {season}...")
    obtain_plays <- function() {
      p <- progressr::progressor(steps = length(games$game_id))
      plays <- furrr::future_map_dfr(games$game_id,
                              ngsscrapR::scrape_plays |>
                                nflreadr::progressively(p)
      )
      return(plays)
    }

    progressr::with_progress({
      plays <- obtain_plays()
    })

    plays <- plays |>
      dplyr::mutate(
        game_id = as.character(game_id),
        # SB exception
        week = dplyr::case_when(!!season <  2021 & week == 22 ~ 21,
                                !!season >= 2021 & week == 23 ~ 22,
                                TRUE ~ week),
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
      # oak -> lv exception
      # dplyr::mutate(tmp_possession_team = nflreadr::clean_team_abbrs(possession_team, current_location = TRUE, keep_non_matches = TRUE)) |>
      dplyr::summarise(
        offense_players = gsis_id[possession_team == team] |> na.omit() |> paste(collapse = ";"),
        n_offense = gsis_id[possession_team == team] |> na.omit() |> length(),
        defense_players = gsis_id[possession_team != team] |> na.omit() |> paste(collapse = ";"),
        n_defense = gsis_id[possession_team != team] |> na.omit() |> length(),
        .groups = "drop"
      ) |>
      dplyr::ungroup() |>
      dplyr::left_join(
        games |> dplyr::mutate(old_game_id = as.character(game_id)),
        by = c("old_game_id" = "old_game_id")
      ) |>
      dplyr::left_join(
        plays |> dplyr::mutate(old_game_id = as.character(game_id)) |>
          dplyr::select(old_game_id, play_id, pass_info, rec_info, dplyr::any_of(
            c('defense_man_zone_type', 'defense_coverage_type')
          )) |> tidyr::unnest(pass_info) |> tidyr::unnest(rec_info) |> janitor::clean_names(),
        by = c("old_game_id" = "old_game_id", "play_id" = "play_id")
      ) |>
      dplyr::select(
        nflverse_game_id,
        old_game_id,
        play_id,
        possession_team,
        offense_formation,
        offense_personnel,
        defenders_in_box,
        defense_personnel,
        number_of_pass_rushers,
        players_on_play,
        offense_players,
        defense_players,
        n_offense,
        n_defense,
        ngs_air_yards = air_yards,
        time_to_throw,
        was_pressure,
        route,
        dplyr::any_of(c('defense_man_zone_type','defense_coverage_type'))
      )

    current_participation <- nflreadr::load_participation(season) |>
      dplyr::anti_join(plays, by = c("nflverse_game_id"))

    plays <- dplyr::bind_rows(plays_template, current_participation, plays) |>
      dplyr::arrange(nflverse_game_id)

    cli::cli_process_start("Uploading participation data to nflverse-data")

    nflversedata::nflverse_save(
      data_frame = plays,
      file_name = paste0("pbp_participation_", season),
      nflverse_type = "pbp participation",
      release_tag = "pbp_participation"
    )

    cli::cli_process_done()
  }

# if (Sys.getenv("NFLVERSE_REBUILD", "false") == "true") {
#   future::plan(future::multisession)
#   purrr::walk(c(2016:nflreadr:::most_recent_season()),
#               pbp_participation)
# } else {
#   pbp_participation(nflreadr:::most_recent_season())
# }
