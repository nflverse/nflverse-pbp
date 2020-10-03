library(tidyverse)
source('https://raw.githubusercontent.com/mrcaseb/nflfastR/master/R/helper_add_nflscrapr_mutations.R')

# starting in 2006 since that's when scrambles started to be marked
seasons <- 2006:2019
pbp <- purrr::map_df(seasons, function(x) {
  readRDS(
    url(
      glue::glue("https://raw.githubusercontent.com/guga31bb/nflfastR-data/master/data/play_by_play_{x}.rds")
    )
  )
}) %>%
  filter(
    aborted_play == 0, 
    qb_kneel == 0,
    rush == 1 | pass == 1, 
    !is.na(posteam),
    !is.na(down),
    !is.na(defteam_timeouts_remaining), 
    !is.na(posteam_timeouts_remaining),
    !is.na(yardline_100),
    !is.na(score_differential),
    week <= 17
    ) %>%
  make_model_mutations() %>%
  mutate(label = pass) %>%
  select(
    label,
    down,
    ydstogo,
    yardline_100,
    qtr,
    wp,
    vegas_wp,
    era2, era3, era4,
    score_differential,
    home,
    half_seconds_remaining,
    posteam_timeouts_remaining,
    defteam_timeouts_remaining,
    outdoors, retractable, dome
  )

saveRDS(pbp, "models/_dropback_model_data.rds")

