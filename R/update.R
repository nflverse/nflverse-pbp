
#devtools::install_github("mrcaseb/nflfastR")

library(nflfastR)
library(tidyverse)

## STEP 1: SCRAPE OLD SEASONS
write_season <- function(y) {
  message(glue::glue('Year {y}: scraping play-by-play of {nrow(fast_scraper_schedules(y) %>% filter(game_type != "PRE"))} games'))
  
  #get reg and post games
  pbp <- fast_scraper_schedules(y) %>%
    filter(game_type != 'PRE') %>%
    pull(game_id) %>%
    fast_scraper(pp = TRUE)
  
  message(glue::glue('Year {y}: writing to file'))
  write_csv(pbp, glue::glue('data/play_by_play_{y}.csv'))
  saveRDS(pbp, glue::glue('data/play_by_play_{y}.rds'))
}

nothing_in_here <- lapply(2000:2019, write_season)


#read_csv(glue::glue('data/play_by_play_{y}.csv'))
#readRDS(glue::glue('data/play_by_play_{y}.rds'))

## STEP 2: SCRAPE ONGOING SEASON

y = 2020

#get reg and post games
sched <- fast_scraper_schedules(y) %>%
  filter(game_type != 'PRE') %>%
  select(game_id, week, game_type)

pbp <- sched %>% pull(game_id) %>%
  fast_scraper(source = 'gc', pp = TRUE) %>%
  mutate(game_id = as.numeric(game_id)) %>%
  #need to do this because week & game_type aren't in gc data
  left_join(sched, by = "game_id")

write_csv(pbp, glue::glue('data/play_by_play_{y}.csv'))
saveRDS(pbp, glue::glue('data/play_by_play_{y}.rds'))





