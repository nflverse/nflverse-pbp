
library(tidyverse)

games <- readRDS(url("https://github.com/leesharpe/nfldata/blob/master/data/games.rds?raw=true")) %>%
  dplyr::select(game_id, season, game_type, week, gameday, weekday, gametime, away_team, 
                home_team, away_score, home_score, home_result = result, stadium, location, roof, surface, old_game_id)

write_old_games <- function(id) { # id = new game_id
  
  #testing
  #id = '2009_18_NYJ_CIN'
  
  if (id %in% c("2000_03_SD_KC", "2000_06_BUF_MIA")) {
    message(glue::glue("Warning: {id} is damaged in Nick's source and therefore missing!"))
  } else {
    game <- games %>% dplyr::filter(game_id == id)
    gameId <- game %>% dplyr::pull(old_game_id)
    season <- game %>% dplyr::pull(season)
    week <- game %>% dplyr::pull(week)
    away <- game %>% dplyr::pull(away_team)
    home <- game %>% dplyr::pull(home_team)
    
    message(glue::glue("Try loading {id} or {gameId}"))
    
    if (id %in% "2009_18_NYJ_CIN") {
      
      url <- glue::glue("https://github.com/BurntSushi/nflgame/blob/master/nflgame/gamecenter-json/{gameId}.json.gz?raw=true")
      download.file(url, glue::glue('{gameId}.json.gz'))
      
      R.utils::gunzip('2010010901.json.gz', remove=FALSE, overwrite = TRUE)
      json <- jsonlite::fromJSON('2010010901.json', flatten = TRUE)

    } else {
      url <- glue::glue("https://raw.githubusercontent.com/guga31bb/nfl_pbps/master/reg/{gameId}.json")
      json <- jsonlite::fromJSON(url, flatten = TRUE)
    }

    # save
    saveRDS(json, glue::glue('raw/{season}/{season}_{formatC(week, width=2, flag=\"0\")}_{away}_{home}.rds'))
    jsonlite::write_json(json, glue::glue('raw/{season}/{season}_{formatC(week, width=2, flag=\"0\")}_{away}_{home}.json'))
    system(glue::glue('gzip raw/{season}/{season}_{formatC(week, width=2, flag=\"0\")}_{away}_{home}.json'))
  }
}

#write_old_games('2009_01_TEN_PIT')


games %>% 
  dplyr::filter(dplyr::between(season, 1999, 2010)) %>%
  # utils::head(10) %>% # for testing
  dplyr::pull(game_id) %>%
  purrr::walk(write_old_games)



if (grepl("Documents",getwd())){
  path <- ".."
} else { ### server
  path <- "/home/ben"
}

password = as.character(read.delim(glue::glue('{path}/gh.txt'))$pw)

data_repo <- git2r::repository('./') # Set up connection to repository folder
git2r::add(data_repo, 'raw/*') # add specific files to staging of commit
git2r::commit(data_repo, message = glue::glue("Updating data at {Sys.time()}")) # commit the staged files with the chosen message
git2r::pull(data_repo) # pull repo (and pray there are no merge commits)
git2r::push(data_repo, credentials = git2r::cred_user_pass(username = 'guga31bb', password = paste(password))) # push commit

