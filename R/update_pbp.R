save_pbp <- function(season) {
    ids <- nflreadr::load_schedules(season) |>
      dplyr::filter(!is.na(result)) |>
      dplyr::pull(game_id)

    # nfl changed player IDs in the 2022 season
    # we probably can't decode them
    should_decode <- ifelse(season <= 2021, TRUE, FALSE)

    pbp <- nflfastR::build_nflfastR_pbp(ids, decode = should_decode)

    n_pbp_ids <- length(unique(pbp$game_id))
    n_ids <- length(ids)

    if(
      (season == 1999 & n_pbp_ids == n_ids - 1L) |
      (season == 2000 & n_pbp_ids == n_ids - 2L) |
      (season >= 2001 & n_pbp_ids == n_ids)
    ){

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

future::plan(future::multisession)
if(Sys.getenv("NFLVERSE_REBUILD","false")=="true"){
  purrr::map(1999:nflreadr:::most_recent_season(), save_pbp)
} else {
  save_pbp(nflreadr:::most_recent_season())
}
future::plan(future::sequential)
