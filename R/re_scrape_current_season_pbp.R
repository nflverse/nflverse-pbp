
# if you need to update data repo

library(nflfastR)
library(tidyverse)

data_repo <- git2r::repository('./') # Set up connection to repository folder
git2r::pull(data_repo) # pull repo (and pray there are no merge commits)

write_season <- function(y) {
  message(glue::glue('Year {y}: scraping play-by-play of {
                     nrow(fast_scraper_schedules(y))
                     } games'))
  
  # get reg and post games with scraper
  pbp <- fast_scraper_schedules(y) %>%
    pull(game_id) %>%
    fast_scraper(pp = TRUE) %>%
    clean_pbp() %>%
    add_qb_epa() %>%
    add_xyac()
  
  message(glue::glue('Year {y}: writing to file'))
  
  # rds
  saveRDS(pbp, glue::glue('data/play_by_play_{y}.rds'))
  # csv.gz
  write_csv(pbp, glue::glue('data/play_by_play_{y}.csv.gz'))
  # .parquet
  arrow::write_parquet(pbp, glue::glue('data/play_by_play_{y}.parquet'))
  # .zip
  write_csv(pbp, glue::glue("data/play_by_play_{x}.csv"))
  utils::zip(glue::glue("data/play_by_play_{x}.zip"), c(glue::glue("data/play_by_play_{x}.csv")))
  file.remove(glue::glue("data/play_by_play_{x}.csv"))
  
}

write_season(2020)

git2r::add(data_repo, 'data/*') # add specific files to staging of commit
git2r::commit(data_repo, message = glue::glue("Updated {Sys.time()} using nflfastR version {utils::packageVersion('nflfastR')}")) # commit the staged files with the chosen message

