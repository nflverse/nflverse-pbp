source('R/scraping_functions.R')
year = 2020

################################################################################
### store raw data: ongoing seasons
###################################

token <- get_token()

dates <- read_csv(url("http://www.habitatring.com/games.csv")) %>%
  filter(season == year) %>%
  group_by(week) %>%
  summarize(first_game = min(gameday), last_game = max(gameday)) %>%
  mutate(
    first_date = first_game,
    last_date = dplyr::lead(first_game) - 1,
    first_date = if_else(week == 1, as.Date('2020-05-16'), first_date),
    last_date = if_else(is.na(last_date), as.Date('2050-05-16'), last_date)
  ) %>%
  select(week, first_date, last_date)

current_week = dates %>% filter(Sys.Date() >= first_date & Sys.Date() <= last_date) %>% pull(week)

#get missing games and save them
missing <- get_missing_games(token, year, current_week)
for (x in 1:nrow(missing)) {
  save_game(token, missing %>% slice(x))
}

#thanks to Tan for the code
data_repo <- git2r::repository('./') # Set up connection to repository folder
git2r::add(data_repo,'raw/*') # add specific files to staging of commit
git2r::commit(data_repo,message = glue::glue("Updating data at {Sys.time()}")) # commit the staged files with the chosen message
git2r::pull(data_repo) # pull repo (and pray there are no merge commits)
git2r::push(data_repo, credentials = git2r::cred_user_pass(username = 'guga31bb', password = paste(password))) # push commit

message(paste('Successfully uploaded to GitHub values as of',Sys.time())) # I have cron set up to pipe this message to healthchecks.io so that I can keep track if something is broken
