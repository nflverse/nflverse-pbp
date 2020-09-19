library(nflfastR)
library(tidyverse)

## SCRAPE ONGOING SEASON

y <- dplyr::if_else(
  lubridate::month(lubridate::today("EST")) >= 9,
  lubridate::year(lubridate::today("EST")) ,
  lubridate::year(lubridate::today("EST")) - 1
)

# get existing pbp
# existing_pbp <- readRDS(url(
#     glue::glue("https://raw.githubusercontent.com/guga31bb/nflfastR-data/master/data/play_by_play_{y}.rds")
#   )) 

# get IDs of scraped games
# already_scraped <- existing_pbp %>% 
#   dplyr::pull(game_id) %>%
#   unique()

#get completed games
sched <- readRDS(url(
  "http://www.habitatring.com/games.rds"
)) %>%
  filter(season == y, !is.na(result)) %>%
  pull(game_id)

# figure out which games we need
# need_scrape <- sched[!sched %in% already_scraped]

# grab the games we need
# new_pbp <- fast_scraper(need_scrape, pp = FALSE) %>%
#   clean_pbp() %>%
#   add_qb_epa() %>%
#   add_xyac()
# 
# pbp <- bind_rows(
#   existing_pbp,
#   new_pbp
# )

pbp <- fast_scraper(sched, pp = TRUE) %>%
  clean_pbp() %>%
  add_qb_epa() %>%
  add_xyac()

# rds
saveRDS(pbp, glue::glue('data/play_by_play_{y}.rds'))
# csv.gz
write_csv(pbp, glue::glue('data/play_by_play_{y}.csv.gz'))
# .parquet
arrow::write_parquet(pbp, glue::glue('data/play_by_play_{y}.parquet'))
# .zip
write_csv(pbp, glue::glue("data/play_by_play_{y}.csv"))
utils::zip(glue::glue("data/play_by_play_{y}.zip"), c(glue::glue("data/play_by_play_{y}.csv")))
file.remove(glue::glue("data/play_by_play_{y}.csv"))


# data_repo <- git2r::repository('./') # Set up connection to repository folder
# git2r::add(data_repo, 'data/*') # add specific files to staging of commit
# git2r::commit(data_repo, message = glue::glue("Updated {Sys.time()} using nflfastR version {utils::packageVersion('nflfastR')}")) # commit the staged files with the chosen message
# git2r::pull(data_repo) # pull repo (and pray there are no merge commits)

# need to manually press the push button since git2r push doesn't work