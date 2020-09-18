
if (grepl("Documents",getwd())){
  path <- ".."
} else { ### server
  path <- "/home/ben"
}

password = as.character(read.delim(glue::glue('{path}/gh.txt'))$pw)

library(nflfastR)
library(tidyverse)

## SCRAPE ONGOING SEASON

y = 2020

# get existing pbp
existing_pbp <- readRDS(
  url(
    glue::glue("https://raw.githubusercontent.com/guga31bb/nflfastR-data/master/data/play_by_play_{y}.rds")
  )
) 

# get IDs of scraped games
already_scraped <- existing_pbp %>% 
  pull(game_id) %>%
  unique()

#get completed games
sched <- readRDS(url(
  "http://www.habitatring.com/games.rds"
)) %>%
  filter(season == 2020, !is.na(result)) %>%
  pull(game_id)

# figure out which games we need
need_scrape <- sched[!sched %in% already_scraped]

# grab the games we need
new_pbp <- fast_scraper(need_scrape, pp = TRUE) %>%
  clean_pbp() %>%
  add_qb_epa() %>%
  add_xyac()

pbp <- bind_rows(
  existing_pbp,
  new_pbp
)

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


data_repo <- git2r::repository('./') # Set up connection to repository folder
git2r::add(data_repo, 'data/*') # add specific files to staging of commit
git2r::commit(data_repo, message = glue::glue("Updated {Sys.time()} using nflfastR version {utils::packageVersion('nflfastR')}")) # commit the staged files with the chosen message
git2r::pull(data_repo) # pull repo (and pray there are no merge commits)
# git2r::push(data_repo, credentials = git2r::cred_user_pass(username = 'guga31bb', password = paste(password))) # push commit

# message(paste('Successfully uploaded to GitHub values as of',Sys.time())) # I have cron set up to pipe this message to healthchecks.io so that I can keep track if something is broken

