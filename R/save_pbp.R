library(dplyr)
save_pbp <- function(season) {
  ids <- nflfastR::fast_scraper_schedules(season) %>%
    dplyr::filter(!is.na(home_result)) %>%
    dplyr::pull(game_id)

  pbp <- nflfastR::build_nflfastR_pbp(ids, pp = TRUE)

  # rds
  saveRDS(pbp, glue::glue('data/play_by_play_{y}.rds'))
  # csv.gz
  readr::write_csv(pbp, glue::glue('data/play_by_play_{y}.csv.gz'))
  # .parquet
  arrow::write_parquet(pbp, glue::glue('data/play_by_play_{y}.parquet'))
  # .zip
  readr::write_csv(pbp, glue::glue("data/play_by_play_{y}.csv"))
  utils::zip(glue::glue("data/play_by_play_{y}.zip"), c(glue::glue("data/play_by_play_{y}.csv")))
  file.remove(glue::glue("data/play_by_play_{y}.csv"))
  return(invisible())
}
