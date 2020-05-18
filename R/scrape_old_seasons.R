source('R/scraping_functions.R')


################################################################################
### store raw data: completed seasons
### once this is finalized, should only need to run this one time
### and then once more for each additional season that has finished
###################################

token <- get_token()

#rebuild old seasons
#2000 seems to have games with missing plays section
#so let's start with 2001

i = 1
for (season in 2001:2019) {
  
  #scrape 3 seasons before getting a new token
  if (i == 4) {
    token <- get_token()
    i = 1
  } else {
    i = i + 1
  }
  
  #build data: reg + post
  walk(1:21, function(x) {
    save_week(token, season, x)
    message(glue::glue('Finished week {x}'))
    Sys.sleep(3)
  })
  
}


#thanks to Tan for the code
data_repo <- git2r::repository('./') # Set up connection to repository folder
git2r::add(data_repo,'raw/*') # add specific files to staging of commit
git2r::commit(data_repo,message = glue::glue("Updating data at {Sys.time()}")) # commit the staged files with the chosen message
git2r::pull(data_repo) # pull repo (and pray there are no merge commits)
git2r::push(data_repo, credentials = git2r::cred_user_pass(username = 'guga31bb', password = paste(password))) # push commit

message(paste('Successfully uploaded to GitHub values as of',Sys.time())) # I have cron set up to pipe this message to healthchecks.io so that I can keep track if something is broken
