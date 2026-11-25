release_pbp <- function(season) {

  ids <- prepare_raw_pbp(season)
  pbp <- nflfastR::build_nflfastR_pbp(ids)

  n_pbp_ids <- length(unique(pbp$game_id))
  n_ids <- length(ids)

  if(
    (season == 1999 & n_pbp_ids == n_ids - 1L) |
    (season == 2000 & n_pbp_ids == n_ids - 2L) |
    (season >= 2001 & n_pbp_ids == n_ids)
  ){

    attr(pbp, "nflfastR_version") <- as.character(packageVersion("nflfastR"))

    nflversedata::nflverse_save(
      data_frame = pbp,
      file_name =  glue::glue("play_by_play_{season}"),
      nflverse_type = "play by play data",
      release_tag = "pbp",
      file_types = c("rds","csv","parquet", "csv.gz")
    )

    cli::cli_alert_success("Saved {season} pbp data.")
  } else {
    cli::cli_alert_warning(c(
      "The number of finished games is not equal to the number of games in the loaded data.\n",
      "Will not push this corrupted dataset to the repo."
    ))
  }
}
