source('R/functions.R')
source_python("scrape.py")

## scrape_me is a df of games that are finished
## that are not on the server
games <- get_finished_games() %>%
  filter(!is.na(result)) %>%
  filter(season >= 2011)

scrape_me <- get_missing_games(games)

#testing only
#scrape_me <- scrape_me %>% filter(season == 2019 & week <= 2)

if (nrow(scrape_me) > 0) {
  
  #the actual scrape
  tictoc::tic(glue::glue('Scraped {nrow(scrape_me)} games'))
  for (j in 1 : nrow(scrape_me)) {
    
    #testing only
    #j = 3
    
    game = scrape_me %>% slice(j)
    
    t <- get_pbp_from_website(game$url)

    if (!is.null(t)) {
      tryCatch({
        json <- as.character(t) %>%
          jsonlite::fromJSON(flatten = T)
        
      }, error = function(e){cat("ERROR :",conditionMessage(e), "\n")})
      
      season = game$season
      week = game$week
      if (game$game_type == 'post') {
        week = week + 17
      }
      away = game$away_team
      home = game$home_team
      
      #save
      saveRDS(json, glue::glue('raw/{season}/{season}_{formatC(week, width=2, flag=\"0\")}_{away}_{home}.rds'))
      jsonlite::write_json(json, glue::glue('raw/{season}/{season}_{formatC(week, width=2, flag=\"0\")}_{away}_{home}.json'))
      system(glue::glue('gzip raw/{season}/{season}_{formatC(week, width=2, flag=\"0\")}_{away}_{home}.json'))
      
      message(glue::glue('Found a game ({season}/w{week}/{away}/{home}). Here is a play: {json$data$viewer$gameDetail$plays$playDescriptionWithJerseyNumbers[3]}'))
      
      #do some cleaning so server doesn't get clogged
      system('rm -r /home/ben/.seleniumwire/storage-*')
      system('killall chromedriver', ignore.stderr = T)
      system('killall chrome', ignore.stderr = T)
      
    } else {
      message(glue::glue('Nothing found for this game: {game$url}'))
    }
    
  }
  tictoc::toc()
  
  #clean up when you're done
  #prevents errors in future, hopefully
  system('killall chromedriver')
  system('killall chrome')
  system('')
  
  #thanks to Tan for the code
  git2r::add(data_repo,'raw/*') # add specific files to staging of commit
  git2r::commit(data_repo,message = glue::glue("Updating data at {Sys.time()}")) # commit the staged files with the chosen message
  git2r::pull(data_repo) # pull repo (and pray there are no merge commits)
  git2r::push(data_repo, credentials = git2r::cred_user_pass(username = 'guga31bb', password = paste(password))) # push commit
  
  message(paste('Successfully uploaded to GitHub at',Sys.time())) # I have cron set up to pipe this message to healthchecks.io
  
}

