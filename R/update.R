#devtools::install_github("mrcaseb/nflfastR")

library(nflfastR)
library(tidyverse)
library(nflscrapR)

## STEP 1: SCRAPE OLD SEASONS
write_season <- function(y) {
  message(glue::glue('Year {y}: scraping play-by-play of {
                     nrow(fast_scraper_schedules(y) %>% filter(season_type %in% c("REG", "POST")))
                     } games'))
   
  # get reg and post games with scraper
  pbp <- fast_scraper_schedules(y) %>%
    filter(season_type %in% c("REG", "POST")) %>%
    pull(game_id) %>%
    fast_scraper(pp = TRUE) %>%
    clean_pbp() %>%
    fix_fumbles()
  
  # get reg and post gamesfrom rds
  # pbp <- readRDS(glue::glue('data/play_by_play_{y}.rds')) %>%
  #   clean_pbp() %>%
  #   fix_fumbles()
  
  message(glue::glue('Year {y}: writing to file'))
  write_csv(pbp, glue::glue('data/play_by_play_{y}.csv.gz'))
  saveRDS(pbp, glue::glue('data/play_by_play_{y}.rds'))
}

nothing_in_here <- lapply(2000:2019, write_season)


## STEP 2: SCRAPE ONGOING SEASON

y = 2020

#get reg and post games
sched <- fast_scraper_schedules(y) %>%
  filter(season_type %in% c("REG", "POST")) %>%
  select(game_id, week, season_type)

pbp <- sched %>% pull(game_id) %>%
  fast_scraper(source = 'gc', pp = TRUE) %>%
  mutate(game_id = as.numeric(game_id)) %>%
  clean_pbp() %>%
  fix_fumbles()
  #need to do this because week & season_type aren't in gc data
  #if we find a live-updating RS feed we can get rid of this part
  left_join(sched, by = "game_id")

write_csv(pbp, glue::glue('data/play_by_play_{y}.csv.gz'))
saveRDS(pbp, glue::glue('data/play_by_play_{y}.rds'))


## STEP 3: SCRAPE ROSTER

roster <- teams_colors_logos %>% pull(team_id) %>% fast_scraper_roster(1999:2019, TRUE)
write_csv(roster, glue::glue('roster-data/roster.csv.gz'))
saveRDS(roster, glue::glue('roster-data/roster.rds'))