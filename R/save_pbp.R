library(dplyr)
save_pbp <- function(season) {

  ids <- nflfastR::fast_scraper_schedules(season) %>%
    dplyr::filter(!is.na(home_result)) %>%
    dplyr::pull(game_id)

  pbp <- nflfastR::build_nflfastR_pbp(ids)

  n_pbp_ids <- length(unique(pbp$game_id))
  n_ids <- length(ids)

  if( (season == 1999 & n_pbp_ids == n_ids - 1L) |
      (season == 2000 & n_pbp_ids == n_ids - 2L) |
      (season >= 2001 & n_pbp_ids == n_ids)){
    # rds
    saveRDS(pbp, glue::glue('data/play_by_play_{season}.rds'))
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
    readr::write_csv(pbp, glue::glue("data/play_by_play_{season}.csv"))
    utils::zip(glue::glue("data/play_by_play_{season}.zip"), c(glue::glue("data/play_by_play_{season}.csv")))
    file.remove(glue::glue("data/play_by_play_{season}.csv"))

    usethis::ui_done("Saved {season} pbp data.")
  } else {
    usethis::ui_warn(c(
      "The number of finished games is not equal to the number of games in the loaded data.",
      "Will not push this corrupted dataset to the repo."
      ))
  }
  return(invisible())
}
