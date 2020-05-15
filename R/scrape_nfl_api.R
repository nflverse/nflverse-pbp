library(tidyverse)
source('R/scraping_functions.R')

if (grepl("Documents",getwd())){
  path <- ".."
} else { ### server
  path <- "/home/ben"
}

################################################################################
### temporary storage
###################################

password = as.character(read.delim(glue::glue('{path}/gh.txt'))$pw)

token <- get_token()

#build 2019 data: reg
nothing_in_here <- map(1:17, function(x) {
  save_week(token, 2018, 'REG', x)
  message(glue::glue('Finished week {x}'))
  Sys.sleep(3)
})

#build 2017 data: post
#right now this fails for super bowls
nothing_in_here <- map(1:4, function(x) {
  save_week(token, 2019, 'POST', x)
  message(glue::glue('Finished week {x}'))
  Sys.sleep(3)
})


#thanks to Tan for the code
data_repo <- git2r::repository('./') # Set up connection to repository folder
git2r::add(data_repo,'raw/*') # add specific files to staging of commit
git2r::commit(data_repo,message = glue::glue("Updating data at {Sys.time()}")) # commit the staged files with the chosen message
git2r::pull(data_repo) # pull repo (and pray there are no merge commits)
git2r::push(data_repo, credentials = git2r::cred_user_pass(username = 'guga31bb', password = paste(password))) # push commit

message(paste('Successfully uploaded to GitHub values as of',Sys.time())) # I have cron set up to pipe this message to healthchecks.io so that I can keep track if something is broken
