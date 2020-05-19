source('R/scraping_functions.R')
token <- get_token()


#which season are we getting?
if (month(Sys.Date()) > 4) {
  year = year(Sys.Date())
} else {
  year = year(Sys.Date()) - 1
}

#testing only
#year = 2020

#connect to repo and make sure it's up to date
data_repo <- git2r::repository('./') # Set up connection to repository folder
git2r::pull(data_repo) # pull repo (and pray there are no merge commits)


################################################################################
### store raw json data: ongoing seasons
###################################

dates <- readRDS(url("http://www.habitatring.com/games.rds")) %>%
  filter(season == year) %>%
  group_by(week) %>%
  summarize(first_game = as.Date(min(gameday)), last_game = as.Date(max(gameday))) %>%
  mutate(
    first_date = first_game,
    last_date = dplyr::lead(first_game),
    first_date = if_else(week == 1, as.Date('2020-05-16'), first_date),
    last_date = if_else(is.na(last_date), as.Date('2050-05-16'), last_date)
  ) %>%
  select(week, first_date, last_date)

current_week = dates %>% filter(Sys.Date() >= first_date & Sys.Date() <= last_date) %>% pull(week)

#testing only
#current_week = 10

#get missing games and save them
missing <- get_missing_games(token, year, current_week)
for (x in 1:nrow(missing)) {
  save_game(token, missing %>% slice(x))
}

#thanks to Tan for the code
git2r::add(data_repo,'raw/*') # add specific files to staging of commit
git2r::commit(data_repo,message = glue::glue("Updating data at {Sys.time()}")) # commit the staged files with the chosen message
git2r::pull(data_repo) # pull repo (and pray there are no merge commits)
git2r::push(data_repo, credentials = git2r::cred_user_pass(username = 'guga31bb', password = paste(password))) # push commit

message(paste('Successfully uploaded to GitHub values as of',Sys.time())) # I have cron set up to pipe this message to healthchecks.io
