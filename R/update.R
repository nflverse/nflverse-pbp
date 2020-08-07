if (grepl("Documents",getwd())){
  path <- ".."
} else { ### server
  path <- "/home/ben"
}

password = as.character(read.delim(glue::glue('{path}/gh.txt'))$pw)

#devtools::install_github("mrcaseb/nflfastR")

library(nflfastR)
library(tidyverse)
path <- "../nflfastR-raw/raw"

write_season <- function(y) {
  message(glue::glue('Year {y}: scraping play-by-play of {
                     nrow(fast_scraper_schedules(y))
                     } games'))
  
  # get reg and post games with scraper
  pbp <- fast_scraper_schedules(y) %>%
    pull(game_id) %>%
    fast_scraper(pp = TRUE, dir = path) %>%
    clean_pbp() %>%
    add_qb_epa() %>%
    add_xyac()
  
  message(glue::glue('Year {y}: writing to file'))
  
  saveRDS(pbp, glue::glue('data/play_by_play_{y}.rds'))
  write_csv(pbp, glue::glue('data/play_by_play_{y}.csv.gz'))
  arrow::write_parquet(pbp, glue::glue('data/play_by_play_{y}.parquet'))
  
}


#don't leave this uncommented as this is probably going to be run periodically
walk(1999:2010, write_season)
closeAllConnections()
walk(2011:2019, write_season)


## STEP 2: SCRAPE ONGOING SEASON

y = 2020

#get reg and post games
sched <- fast_scraper_schedules(y) %>%
  filter(season_type %in% c("REG", "POST")) %>%
  select(game_id, week, season_type)

pbp <- sched %>% pull(game_id) %>%
  fast_scraper(pp = TRUE) %>%
  clean_pbp() %>%
  add_qb_epa() %>%
  add_xyac()

write_csv(pbp, glue::glue('data/play_by_play_{y}.csv.gz'))
saveRDS(pbp, glue::glue('data/play_by_play_{y}.rds'))
arrow::write_parquet(pbp, glue::glue('data/play_by_play_{y}.parquet'))


data_repo <- git2r::repository('./') # Set up connection to repository folder
git2r::add(data_repo, 'data/*') # add specific files to staging of commit
git2r::commit(data_repo, message = glue::glue("Updated {Sys.time()} using nflfastR version {utils::packageVersion('nflfastR')}")) # commit the staged files with the chosen message
git2r::pull(data_repo) # pull repo (and pray there are no merge commits)
git2r::push(data_repo, credentials = git2r::cred_user_pass(username = 'guga31bb', password = paste(password))) # push commit

message(paste('Successfully uploaded to GitHub values as of',Sys.time())) # I have cron set up to pipe this message to healthchecks.io so that I can keep track if something is broken


## STEP 3: SCRAPE ROSTER
#commenting out for now because it's broken

# roster <- teams_colors_logos %>% pull(team_id) %>% fast_scraper_roster(1999:2019, TRUE)
# write_csv(roster, glue::glue('roster-data/roster.csv.gz'))
# saveRDS(roster, glue::glue('roster-data/roster.rds'))

## STEP 4: Scrape schedule
games <- readRDS(url("https://github.com/leesharpe/nfldata/blob/master/data/games.rds?raw=true")) %>%
  select(game_id, season, game_type, week, gameday, weekday, gametime, away_team, 
         home_team, away_score, home_score, home_result = result, stadium, location, roof, surface, old_game_id)

max_s <- max(games$season)
min_s <- min(games$season)

write_season_schedule <- function(s){
  g <- games %>% filter(season == s)
  saveRDS(g, glue::glue('schedules/sched_{s}.rds'))
}

walk(min_s:max_s, write_season_schedule)