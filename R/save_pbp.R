library(dplyr)
save_pbp <- function(season) {

  ids <- nflreadr::load_schedules(season) |>
    dplyr::filter(!is.na(result)) |>
    dplyr::pull(game_id)

  pbp <- nflfastR::build_nflfastR_pbp(ids)

  n_pbp_ids <- length(unique(pbp$game_id))
  n_ids <- length(ids)

  attr(pbp, "nflverse_timestamp") <- Sys.time()
  attr(pbp, "nflverse_type") <- "play by play"
  attr(pbp, "nflfastR_version") <- packageVersion("nflfastR")

  if( (season == 1999 & n_pbp_ids == n_ids - 1L) |
      (season == 2000 & n_pbp_ids == n_ids - 2L) |
      (season >= 2001 & n_pbp_ids == n_ids)){

    # rds
    saveRDS(pbp, glue::glue('data/play_by_play_{season}.rds'))
    # csv
    data.table::fwrite(pbp, glue::glue("data/play_by_play_{season}.csv"))
    # csv.gz
    readr::write_csv(pbp, glue::glue('data/play_by_play_{season}.csv.gz'))
    # .parquet
    arrow::write_parquet(pbp, glue::glue('data/play_by_play_{season}.parquet'))
    # .qs
    qs::qsave(pbp, glue::glue('data/play_by_play_{season}.qs'),
              preset = "custom",
              algorithm = "zstd_stream",
              compress_level = 22,
              shuffle_control = 15)
    # .zip
    utils::zip(glue::glue("data/play_by_play_{season}.zip"), c(glue::glue("data/play_by_play_{season}.csv")))

    cli::cli_alert_success("Saved {season} pbp data.")
  } else {
    cli::cli_alert_warning(c(
      "The number of finished games is not equal to the number of games in the loaded data.\n",
      "Will not push this corrupted dataset to the repo."
      ))
  }
  return(invisible())
}
