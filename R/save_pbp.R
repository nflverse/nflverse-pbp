library(dplyr)
save_pbp <- function(season) {
  ids <- nflfastR::fast_scraper_schedules(season) %>%
    dplyr::filter(!is.na(home_result)) %>%
    dplyr::pull(game_id)

  pbp <- nflfastR::build_nflfastR_pbp(ids, pp = TRUE)

  # rds
  saveRDS(pbp, glue::glue('data/play_by_play_{season}.rds'))
  # csv.gz
  readr::write_csv(pbp, glue::glue('data/play_by_play_{season}.csv.gz'))
  # .parquet
  arrow::write_parquet(pbp, glue::glue('data/play_by_play_{season}.parquet'))
  # .zip
  readr::write_csv(pbp, glue::glue("data/play_by_play_{season}.csv"))
  utils::zip(glue::glue("data/play_by_play_{season}.zip"), c(glue::glue("data/play_by_play_{season}.csv")))
  file.remove(glue::glue("data/play_by_play_{season}.csv"))
  closeAllConnections()
  usethis::ui_done("Saved {season} pbp data.")
  return(invisible())
}
