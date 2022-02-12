library(reticulate)
library(tidyverse)
library(nflfastR)

#github setup stuff
if (grepl("Documents",getwd())){
  path <- ".."
} else { ### server
  path <- "/home/ben"
}
password = as.character(read.delim(glue::glue('{path}/gh.txt'))$pw)
data_repo <- git2r::repository('./') # Set up connection to repository folder

#get completed games
get_finished_games <- function() {
  
  names <- teams_colors_logos %>%
    select(team_nick, team_abbr)
  
  games <- readRDS(url("http://www.habitatring.com/games.rds")) %>%
    as_tibble() %>%
    select(game_id, result, season, game_type, week, away_team, home_team) %>%
    mutate(week = as.integer(week), 
           week = if_else(game_type == 'REG', week, as.integer(week - 17)),
           game_type = if_else(game_type == 'REG', 'reg', 'post')
    ) %>%
    left_join(names, by = c('home_team' = 'team_abbr')) %>%
    dplyr::rename(home_name = team_nick) %>%
    left_join(names, by = c('away_team' = 'team_abbr')) %>%
    dplyr::rename(away_name = team_nick) %>%
    mutate(
      url = paste0('https://www.nfl.com/games/',away_name,'-at-',home_name,'-',season,'-',game_type,'-',week)
    )
  
  return(games)
  
}

#function to get the completed games
#that are not present in the data repo
get_missing_games <- function(finished_games) {
  
  server <- list.files('raw', recursive = T) %>%
    as_tibble() %>%
    dplyr::rename(
      name = value
    ) %>%
    dplyr::mutate(
      name =
        stringr::str_extract(
          name, '[0-9]{4}\\_[0-9]{2}\\_[A-Z]{2,3}\\_[A-Z]{2,3}(?=.)'
        ),
      season =
        stringr::str_extract(
          name, '[0-9]{4}'
        ),
      week =
        as.integer(stringr::str_extract(name, '(?<=\\_)[0-9]{2}(?=\\_)'))
      ,
      away_team =
        stringr::str_extract(
          name, '(?<=[0-9]\\_)[A-Z]{2,3}(?=\\_)'
        ),
      home_team =
        stringr::str_extract(
          name, '(?<=[A-Z]\\_)[A-Z]{2,3}'
        ),
      season_type = dplyr::if_else(week <= 17, 'REG', 'POST')
    ) %>%
    dplyr::mutate(
      season = as.integer(season)
    ) %>%
    dplyr::arrange(season, week) %>%
    dplyr::rename(game_id = name) %>%
    dplyr::distinct() %>%
    arrange(game_id)
  
  server_ids <- unique(server$game_id)
  finished_ids <-unique(finished_games$game_id)
  
  need_scrape <- finished_games[!finished_ids %in% server_ids,]
  
  message(glue::glue('You have {nrow(finished_games[finished_ids %in% server_ids,])} games and need {nrow(need_scrape)}'))
  
  return(need_scrape)
  
}
