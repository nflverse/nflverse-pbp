


#pick some random game and save token
get_token <- function() {
  
  html <-
    xml2::read_html("https://www.nfl.com/games/49ers-at-chiefs-2019-post-4") %>%
    rvest::html_text()
  
  token <- html %>%
    stringr::str_extract("access_token\":\"[:graph:]+\",\"token_type\"") %>%
    stringr::str_sub(16, -15)
  
  return(token)
}

#get game ids
get_week_games <- function(token, season, season_type, week) {

  #get detailed game info
  if(between(week, 1, 17) & season_type == "REG") {
    query <- glue::glue("%7B%22%24query%22%3A%7B%22week.season%22%3A{season}%2C%22week.seasonType%22%3A%22REG%22%2C%22week.week%22%3A{week}%7D%7D")
  } else if(between(week, 1, 4) & season_type == "POST") {
    query <- glue::glue("%7B%22%24query%22%3A%7B%22week.season%22%3A{season}%2C%22week.seasonType%22%3A%22POST%22%2C%22week.week%22%3A{week}%7D%7D")
  }
  
  url <- paste0("https://api.nfl.com/v1/games?s=",query)
  request <- httr::GET(url = url, httr::add_headers(Authorization = glue::glue("Bearer {token}")))
  raw_data <- request %>%
    httr::content(as = "text", encoding = "UTF-8") %>%
    jsonlite::fromJSON(flatten = TRUE)
  games_detail <- raw_data$data

  #get this other stuff (needed for home & away team abbr)
  if(between(week, 1, 17) & season_type == "REG") {
    url <- glue::glue("https://api.nfl.com/v3/shield/?query=query%7Bviewer%7Bleague%7Bgames(first%3A100%2Cweek_seasonValue%3A{season}%2Cweek_seasonType%3AREG%2Cweek_weekValue%3A{week}%2C)%7Bedges%7Bcursor%20node%7Bid%20esbId%20gameDetailId%20gameTime%20gsisId%20networkChannels%20radioLinks%20ticketUrl%20venue%7BfullName%20city%20state%7DawayTeam%7BnickName%20id%20abbreviation%20franchise%7BcurrentLogo%7Burl%7D%7D%7DhomeTeam%7BnickName%20id%20abbreviation%20franchise%7BcurrentLogo%7Burl%7D%7D%7Dslug%7D%7D%7D%7D%7D%7D&variables=null")
  } else if(between(week, 1, 4) & season_type == "POST") {
    url <- glue::glue("https://api.nfl.com/v3/shield/?query=query%7Bviewer%7Bleague%7Bgames(first%3A100%2Cweek_seasonValue%3A{season}%2Cweek_seasonType%3APOST%2Cweek_weekValue%3A{week}%2C)%7Bedges%7Bcursor%20node%7Bid%20esbId%20gameDetailId%20gameTime%20gsisId%20networkChannels%20radioLinks%20ticketUrl%20venue%7BfullName%20city%20state%7DawayTeam%7BnickName%20id%20abbreviation%20franchise%7BcurrentLogo%7Burl%7D%7D%7DhomeTeam%7BnickName%20id%20abbreviation%20franchise%7BcurrentLogo%7Burl%7D%7D%7Dslug%7D%7D%7D%7D%7D%7D&variables=null")
  }
  request <- httr::GET(url = url, httr::add_headers(Authorization = glue::glue("Bearer {token}")))
  raw_data <- request %>%
    httr::content(as = "text", encoding = "UTF-8") %>%
    jsonlite::fromJSON(flatten = TRUE)
  
  games <- raw_data$data$viewer$league$games$edges %>%
    dplyr::rename(
      away = node.awayTeam.abbreviation,
      home = node.homeTeam.abbreviation,
      game_id = node.gameDetailId
    ) %>%
    left_join(games_detail, by = c('node.id' = 'id')) %>%
    mutate(
      week = week,
      season_type = season_type,
      season = season
    ) %>%
    janitor::clean_names() %>%    
    tibble::as_tibble() %>%
    dplyr::mutate(
      game_date = 
        substr(node_game_time, 1, 10),
      game_year =
        substr(game_date, 1, 4),
      game_month =
        substr(game_date, 6, 7)
    )
  
  return(games)
  
}



save_week <- function(token, season, season_type, week) {
  
  #get the game IDs for that week
  game_ids <- get_week_games(token, season, season_type, week)
  
  #save all the json
  for (x in 1:nrow(game_ids)) {
    save_game(token, game_ids %>% slice(x))
  }
}


save_game <- function(token, df) {
  
  game_id = df$game_id
  season = df$season
  season_type = df$season_type
  home = df$home
  away = df$away
  
  if (season_type == 'POST') {
    week = df$week + 17
  } else {
    week = df$week
  }
  
  url <- glue::glue("https://api.nfl.com/v3/shield/?query=query%7Bviewer%7BgameDetail(id%3A%22{game_id}%22)%7Bid%20attendance%20distance%20down%20gameClock%20goalToGo%20homePointsOvertime%20homePointsTotal%20homePointsQ1%20homePointsQ2%20homePointsQ3%20homePointsQ4%20homeTeam%7Babbreviation%20nickName%7DhomeTimeoutsUsed%20homeTimeoutsRemaining%20period%20phase%20playReview%20possessionTeam%7Babbreviation%20nickName%7Dredzone%20scoringSummaries%7BplayId%20playDescription%20patPlayId%20homeScore%20visitorScore%7Dstadium%20startTime%20visitorPointsOvertime%20visitorPointsOvertimeTotal%20visitorPointsQ1%20visitorPointsQ2%20visitorPointsQ3%20visitorPointsQ4%20visitorPointsTotal%20visitorTeam%7Babbreviation%20nickName%7DvisitorTimeoutsUsed%20visitorTimeoutsRemaining%20homePointsOvertimeTotal%20visitorPointsOvertimeTotal%20possessionTeam%7BnickName%7Dweather%7BcurrentFahrenheit%20location%20longDescription%20shortDescription%20currentRealFeelFahrenheit%7DyardLine%20yardsToGo%20drives%7BquarterStart%20endTransition%20endYardLine%20endedWithScore%20firstDowns%20gameClockEnd%20gameClockStart%20howEndedDescription%20howStartedDescription%20inside20%20orderSequence%20playCount%20playIdEnded%20playIdStarted%20playSeqEnded%20playSeqStarted%20possessionTeam%7Babbreviation%20nickName%20franchise%7BcurrentLogo%7Burl%7D%7D%7DquarterEnd%20realStartTime%20startTransition%20startYardLine%20timeOfPossession%20yards%20yardsPenalized%7Dplays%7BclockTime%20down%20driveNetYards%20drivePlayCount%20driveSequenceNumber%20driveTimeOfPossession%20endClockTime%20endYardLine%20firstDown%20goalToGo%20nextPlayIsGoalToGo%20nextPlayType%20orderSequence%20penaltyOnPlay%20playClock%20playDeleted%20playDescription%20playDescriptionWithJerseyNumbers%20playId%20playReviewStatus%20isBigPlay%20playType%20playStats%7BstatId%20yards%20team%7Bid%20abbreviation%7DplayerName%20gsisPlayer%7Bid%7D%7DpossessionTeam%7Babbreviation%20nickName%20franchise%7BcurrentLogo%7Burl%7D%7D%7DprePlayByPlay%20quarter%20scoringPlay%20scoringPlayType%20scoringTeam%7Bid%20abbreviation%20nickName%7DshortDescription%20specialTeamsPlay%20stPlayType%20timeOfDay%20yardLine%20yards%20yardsToGo%20latestPlay%7D%7D%7D%7D&variables=null")
  request <- httr::GET(url = url, httr::add_headers(Authorization = glue::glue("Bearer {token}")))
  raw_data <- request %>%
    httr::content(as = "text", encoding = "UTF-8") %>%
    jsonlite::fromJSON(flatten = TRUE)
  
  #shoving all the gathered info from games here
  raw_data$sched_info <- df
  
  saveRDS(raw_data, glue::glue('raw/{season}_{formatC(week, width=2, flag=\"0\")}_{away}_{home}.rds'))
  
  # save compressed JSON so non-R users can work with it
  request %>%
    httr::content(as = "text", encoding = "UTF-8") %>%
    jsonlite::fromJSON(flatten = TRUE) %>%
    jsonlite::write_json(glue::glue('raw/{season}_{formatC(week, width=2, flag=\"0\")}_{away}_{home}.json'))
  system(glue::glue('gzip raw/{season}_{formatC(week, width=2, flag=\"0\")}_{away}_{home}.json'))
  # read those files with
  # df <- jsonlite::fromJSON("raw/{alt_game_id}.json.gz")
  
  message(glue::glue('Saved {season}_{formatC(week, width=2, flag=\"0\")}_{away}_{home}'))
}