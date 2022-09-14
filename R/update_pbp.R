save_pbp <- function(season) {
  ids <- nflreadr::load_schedules(season) |>
    dplyr::filter(!is.na(result)) |>
    dplyr::pull(game_id)

  pbp <- nflfastR::build_nflfastR_pbp(ids) |>
    .patch_gsis_ids(season = season)

  n_pbp_ids <- length(unique(pbp$game_id))
  n_ids <- length(ids)

  if(
    (season == 1999 & n_pbp_ids == n_ids - 1L) |
    (season == 2000 & n_pbp_ids == n_ids - 2L) |
    (season >= 2001 & n_pbp_ids == n_ids)
  ){

    attr(pbp,"nflfastR_version") <- packageVersion("nflfastR")

    nflversedata::nflverse_save(
      data_frame = pbp,
      file_name =  glue::glue("play_by_play_{season}"),
      nflverse_type = "play by play data",
      release_tag = "pbp",
      file_types = c("rds","csv","parquet","qs", "csv.gz")
    )

    cli::cli_alert_success("Saved {season} pbp data.")
  } else {
    cli::cli_alert_warning(c(
      "The number of finished games is not equal to the number of games in the loaded data.\n",
      "Will not push this corrupted dataset to the repo."
    ))
  }
}

.obtain_plays <- function(game_ids) {
  p <- progressr::progressor(steps = length(game_ids))
  plays <- furrr::future_map_dfr(
    game_ids,
    ngsscrapR::scrape_plays |> nflreadr::progressively(p))
  return(plays)
}

.patch_gsis_ids <- function(pbp, season){

  if(season < 2022) return(pbp)

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
    plays <- .obtain_plays(games$game_id)
  })

  ngsplay_playerids <- plays |>
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

  patch_ids <- pbp |>
    dplyr::select(game_id, play_id, matches("player_id|player_name"),
                  passer_id, passer_name = passer,
                  receiver_id, receiver_name = receiver,
                  rusher_id, rusher_name = rusher,
                  fantasy_id, fantasy_name = fantasy,
                  fantasy_player_name
                  ) |>
    tidyr::pivot_longer(
      cols = -c(game_id,play_id),
      names_to = c("stat",".value"),
      names_pattern = c("(.+)_(id|name)"),
      values_drop_na = TRUE
    ) |>
    dplyr::left_join(ngsplay_playerids, by = c("game_id","play_id","name")) |>
    dplyr::mutate(
      id = dplyr::coalesce(id,gsis_id),
      gsis_id = NULL,
      club_code = NULL,
      name = NULL) |>
    tidyr::pivot_wider(
      names_from = stat,
      values_from = id,
      names_glue = "{stat}_id"
    )

  patched_pbp <- pbp |>
    tibble::tibble() |>
    dplyr::rows_patch(patch_ids, by = c("game_id","play_id"))

  return(patched_pbp)
}

future::plan(future::multisession)
if(Sys.getenv("NFLVERSE_REBUILD","false")=="true"){
  purrr::map(1999:nflreadr:::most_recent_season(), save_pbp)
} else {
  save_pbp(nflreadr:::most_recent_season())
}
future::plan(future::sequential)
