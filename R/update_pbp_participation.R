release_pbp_participation <- function(season) {
    if (season < 2016){
      cli::cli_alert_warning("No participation data for {.val {season}} season. Abort.")
      return(NULL)
    } else if (season <= 2023){
      cli::cli_alert_warning("It seems like the {.val {season}} season is gone from the api. Skip to avoid loss of data.")
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

  if (season <= 2023) {
    # this code no longer works as the endpoint is no longer available. I am keeping it around for posterity's sake
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
      plays <- purrr::possibly(obtain_plays)()
    })

    if (nrow(plays) == 0){
      cli::cli_alert_warning("Can't access data. Quitting here.")
      return(invisible(FALSE))
    }

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
  } else if (season >= 2024) {
    plays <- nflreadr::load_from_url(
      glue::glue(
        "https://github.com/nflverse/nflverse-ftn/releases/download/raw/ftn_participation_{season}.rds"
      )
    )

    ftn_data <- nflreadr::load_from_url(
      "https://github.com/nflverse/nflverse-ftn/releases/download/raw/full_ftn_data.rds"
    )

    plays <- plays |>
      dplyr::left_join(
        ftn_data,
        by = dplyr::join_by(
          pid == ftn_play_id
        ),
        na_matches = "never"
      ) |> # some plays are missing from `ftn_data`, so we use information from other games to grab this info
      dplyr::group_by(gameId) |>
      dplyr::mutate(
        nflverse_game_id = data.table::fcoalesce(
          nflverse_game_id,
          nflreadr::stat_mode(nflverse_game_id, na.rm = TRUE)
        )
      ) |>
      dplyr::ungroup() |>
      dplyr::left_join(
        nflreadr::load_pbp(seasons = season),
        by = dplyr::join_by(nflverse_game_id == game_id, nflplayid == play_id),
        na_matches = "never",
        relationship = "one-to-one"
      ) |>
      dplyr::mutate(posteam = data.table::fcoalesce(posteam, ""))

    collapse_pos <- function(x) {
      table(x) |>
        tibble::enframe() |>
        (\(x) paste(x$value, x$name))() |>
        paste0(collapse = ", ")
    }

    personnel <- plays |>
      dplyr::filter(posteam != "") |>
      dplyr::select(
        gameId,
        nflplayid,
        posteam,
        dplyr::starts_with("items"),
        dplyr::starts_with("tmabbr"),
        dplyr::starts_with("tmjers"),
        dplyr::starts_with("gsisid"),
      ) |>
      dplyr::rename_with(\(x) gsub("items.", "", x, fixed = TRUE)) |>
      tidyr::pivot_longer(
        cols = -c(nflplayid, gameId, posteam),
        values_transform = as.character
      ) |>
      tidyr::separate_wider_delim(
        name,
        names = c("name", "player_num"),
        delim = "_"
      ) |>
      tidyr::pivot_wider(id_cols = c(nflplayid, gameId, player_num, posteam)) |>
      dplyr::arrange(position) |>
      dplyr::group_by(
        gameId,
        nflplayid
      ) |>
      dplyr::summarize(
        offense_personnel = collapse_pos(position[posteam == tmabbr]),
        defense_personnel = collapse_pos(position[posteam != tmabbr]),
        players_on_play = paste0(gsisid, collapse = ";"),
        offense_players = paste0(gsisid[posteam == tmabbr], collapse = ";"),
        defense_players = paste0(gsisid[posteam != tmabbr], collapse = ';'),
        n_offense = sum(posteam == tmabbr, na.rm = TRUE),
        n_defense = sum(posteam != tmabbr, na.rm = TRUE),
        offense_names = paste0(name[posteam == tmabbr], collapse = ";"),
        defense_names = paste0(name[posteam != tmabbr], collapse = ";"),
        offense_positions = paste0(position[posteam == tmabbr], collapse = ";"),
        defense_positions = paste0(position[posteam != tmabbr], collapse = ";"),
        offense_numbers = paste0(
          uniformNumber[posteam == tmabbr],
          collapse = ";"
        ),
        defense_numbers = paste0(
          uniformNumber[posteam != tmabbr],
          collapse = ";"
        ),
        .groups = "drop"
      )

    plays <- plays |>
      dplyr::left_join(personnel, by = dplyr::join_by(gameId, nflplayid)) |>
      dplyr::mutate(
        ngs_air_yards = NA_real_,
        route = stringi::stri_trans_toupper(
          gsub("[0-9]{1,} - ", "", route)
        ),
        defense_coverage_type = dplyr::case_when(
          defense_coverage_type == "0" ~ "COVER_0",
          defense_coverage_type == "1" ~ "COVER_1",
          defense_coverage_type == "2" ~ "COVER_2",
          defense_coverage_type == "2M" ~ "2_MAN",
          defense_coverage_type == "3" ~ "COVER_3",
          defense_coverage_type == "4" ~ "COVER_4",
          defense_coverage_type == "6" ~ "COVER_6",
          defense_coverage_type == "9" ~ "COVER_9",
          defense_coverage_type == "C" ~ "COMBO",
          defense_coverage_type == "N" ~ "BLOWN",
          TRUE ~ NA_character_
        )
      ) |>
      dplyr::select(
        nflverse_game_id,
        old_game_id,
        play_id = nflplayid,
        possession_team = posteam,
        offense_formation,
        offense_personnel,
        defenders_in_box,
        defense_personnel,
        number_of_pass_rushers = n_pass_rushers,
        players_on_play,
        offense_players,
        defense_players,
        n_offense,
        n_defense,
        ngs_air_yards,
        time_to_throw,
        was_pressure,
        route,
        defense_man_zone_type,
        defense_coverage_type,
        offense_names,
        defense_names,
        offense_positions,
        defense_positions,
        offense_numbers,
        defense_numbers,
      )
  }

  current_participation <- nflreadr::load_participation(season)
  if (nrow(current_participation)) {
    plays <- current_participation |>
      dplyr::rows_upsert(plays, by = c("nflverse_game_id", "play_id"))
  }

  cli::cli_process_start("Uploading participation data to nflverse-data")

  nflversedata::nflverse_save(
    data_frame = plays,
    file_name = paste0("pbp_participation_", season),
    nflverse_type = "Participation Data provided by FTNData.com",
    file_types = c("rds", "parquet", "csv", "qs"),
    release_tag = "pbp_participation"
  )

  cli::cli_process_done()
}
