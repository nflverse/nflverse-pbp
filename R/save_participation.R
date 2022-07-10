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
        players_on_play,
        offense_formation = offense_offense_formation,
        offense_personnel,
        defenders_in_box = defense_defenders_in_the_box,
        defense_personnel,
        number_of_pass_rushers = defense_number_of_pass_rushers
      )

    cli::cli_process_start("Uploading participation data to nflverse-data")

    nflversedata::nflverse_save(
      data_frame = plays,
      file_name = paste0("pbp_participation_",season),
      nflverse_type = "pbp participation",
      release_tag = "pbp_participation"
    )

    cli::cli_process_done()

  }

pbp_participation(nflreadr:::most_recent_season())

# do this manually to build releases

# purrr::walk(
#   c(2020:nflreadr:::most_recent_season()),
#   pbp_participation
# )
