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
      plays <- purrr::map_dfr(
        games$game_id,
        \(x) {
          pbp <- ngsscrapR::scrape_plays(x)
          p()
          return(pbp)
        }
      )
      return(plays)
    }

    progressr::with_progress({
      plays <- obtain_plays()
    })

    plays <- plays |>
      dplyr::mutate(
        game_id = as.character(game_id)
      ) |>
      dplyr::select(
        old_game_id = game_id,
        play_id,
        possession_team,
        players_on_play,
        offense_formation = offense_offense_formation,
        offense_personnel,
        defenders_in_box = defense_defenders_in_the_box,
        defense_personnel,
        number_of_pass_rushers = defense_number_of_pass_rushers
      ) |>
      tidyr::separate_rows(players_on_play,sep = ";") |>
      dplyr::left_join(
        nflreadr::load_players() |>
          dplyr::select(gsis_id,gsis_it_id) |>
          dplyr::mutate_at("gsis_it_id", as.character),
        by= c("players_on_play" = "gsis_it_id"),
        na_matches = "never"
      ) |>
      dplyr::left_join(
        # ideally season + week join?
        nflreadr::load_rosters(season) |> dplyr::select(gsis_id, team),
        by = "gsis_id",
        na_matches = "never"
      ) |>
      dplyr::group_by(old_game_id, play_id,
                      possession_team,
                      offense_formation, offense_personnel,
                      defenders_in_box, defense_personnel, number_of_pass_rushers
                      ) |>
      dplyr::summarise(
        offense_players = gsis_id[possession_team == team] |> na.omit() |> paste(collapse = ";"),
        defense_players = gsis_id[possession_team != team] |> na.omit() |> paste(collapse = ";")
      ) |>
      dplyr::ungroup()

    cli::cli_process_start("Uploading participation data to nflverse-data")

    nflversedata::nflverse_save(
      data_frame = plays,
      file_name = paste0("pbp_participation_",season),
      nflverse_type = "pbp participation",
      release_tag = "pbp_participation"
    )

    cli::cli_process_done()

  }


# future::plan(future::multisession)
pbp_participation(nflreadr:::most_recent_season())

# do this manually to build releases
#
# purrr::walk(
#   c(2016:2020),
#   pbp_participation
# )
