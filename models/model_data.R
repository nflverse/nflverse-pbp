################################################################################
# Author: Ben Baldwin
# Purpose: Prepare data for nflfastR models for EP, CP, Field Goals, and WP
# This takes a long time (especially finding next score half)
# Save a pre-prepared df
################################################################################

library(tidyverse)

########################################################################
#### helper function for building dataset to estimate EPA model ########
########################################################################

#original code
#https://github.com/ryurko/nflscrapR-models/blob/master/R/init_models/init_ep_fg_models.R

find_game_next_score_half <- function(pbp_dataset) {
  
  # Which rows are the scoring plays:
  score_plays <- which(pbp_dataset$sp == 1 & pbp_dataset$play_type != "no_play")
  
  # Define a helper function that takes in the current play index,
  # a vector of the scoring play indices, play-by-play data,
  # and returns the score type and drive number for the next score:
  find_next_score <- function(play_i, score_plays_i,pbp_df) {
    
    # Find the next score index for the current play
    # based on being the first next score index:
    next_score_i <- score_plays_i[which(score_plays_i >= play_i)[1]]
    
    # If next_score_i is NA (no more scores after current play)
    # or if the next score is in another half,
    # then return No_Score and the current drive number
    if (is.na(next_score_i) |
        (pbp_df$qtr[play_i] %in% c(1, 2) & pbp_df$qtr[next_score_i] %in% c(3, 4, 5)) |
        (pbp_df$qtr[play_i] %in% c(3, 4) & pbp_df$qtr[next_score_i] == 5)) {
      
      score_type <- "No_Score"
      
      # Make it the current play index
      score_drive <- pbp_df$drive[play_i]
      
      # Else return the observed next score type and drive number:
    } else {
      
      # Store the score_drive number
      score_drive <- pbp_df$drive[next_score_i]
      
      # Then check the play types to decide what to return
      # based on several types of cases for the next score:
      
      # 1: Return TD
      if (pbp_df$touchdown[next_score_i] == 1 & (pbp_df$td_team[next_score_i] != pbp_df$posteam[next_score_i])) {
        
        # For return touchdowns the current posteam would not have
        # possession at the time of return, so it's flipped:
        if (identical(pbp_df$posteam[play_i], pbp_df$posteam[next_score_i])) {
          
          score_type <- "Opp_Touchdown"
          
        } else {
          
          score_type <- "Touchdown"
          
        }
      } else if (identical(pbp_df$field_goal_result[next_score_i], "made")) {
        
        # 2: Field Goal
        # Current posteam made FG
        if (identical(pbp_df$posteam[play_i], pbp_df$posteam[next_score_i])) {
          
          score_type <- "Field_Goal"
          
          # Opponent made FG
        } else {
          
          score_type <- "Opp_Field_Goal"
          
        }
        
        # 3: Touchdown (returns already counted for)
      } else if (pbp_df$touchdown[next_score_i] == 1) {
        
        # Current posteam TD
        if (identical(pbp_df$posteam[play_i], pbp_df$posteam[next_score_i])) {
          
          score_type <- "Touchdown"
          
          # Opponent TD
        } else {
          
          score_type <- "Opp_Touchdown"
          
        }
        # 4: Safety (similar to returns)
      } else if (pbp_df$safety[next_score_i] == 1) {
        
        if (identical(pbp_df$posteam[play_i],pbp_df$posteam[next_score_i])) {
          
          score_type <- "Opp_Safety"
          
        } else {
          
          score_type <- "Safety"
          
        }
        # 5: Extra Points
      } else if (identical(pbp_df$extra_point_result[next_score_i], "good")) {
        
        # Current posteam Extra Point
        if (identical(pbp_df$posteam[play_i], pbp_df$posteam[next_score_i])) {
          
          score_type <- "Extra_Point"
          
          # Opponent Extra Point
        } else {
          
          score_type <- "Opp_Extra_Point"
          
        }
        # 6: Two Point Conversions
      } else if (identical(pbp_df$two_point_conv_result[next_score_i], "success")) {
        
        # Current posteam Two Point Conversion
        if (identical(pbp_df$posteam[play_i], pbp_df$posteam[next_score_i])) {
          
          score_type <- "Two_Point_Conversion"
          
          # Opponent Two Point Conversion
        } else {
          
          score_type <- "Opp_Two_Point_Conversion"
          
        }
        
        # 7: Defensive Two Point (like returns)
      } else if (identical(pbp_df$defensive_two_point_conv[next_score_i], 1)) {
        
        if (identical(pbp_df$posteam[play_i], pbp_df$posteam[next_score_i])) {
          
          score_type <- "Opp_Defensive_Two_Point"
          
        } else {
          
          score_type <- "Defensive_Two_Point"
          
        }
        
        # 8: Errors of some sort so return NA (but shouldn't take place)
      } else {
        
        score_type <- NA
        
      }
    }
    
    return(data.frame(Next_Score_Half = score_type,
                      Drive_Score_Half = score_drive))
  }
  
  # Using lapply and then bind_rows is much faster than
  # using map_dfr() here:
  lapply(c(1:nrow(pbp_dataset)), find_next_score,
         score_plays_i = score_plays, pbp_df = pbp_dataset) %>%
    bind_rows() %>%
    return
}

################################################################################
# DATA PREP
################################################################################

#read in data from data repo
pbp_data <- purrr::map_df(1999 : 2019, function(x) {
  readRDS(
    
    # from repo
    # url(glue::glue("https://raw.githubusercontent.com/guga31bb/nflfastR-data/master/data/play_by_play_{x}.rds"))
    
    # local
    glue::glue("data/play_by_play_{x}.rds")
    
  ) %>% filter(season_type == 'REG')
}) %>%
  mutate(
    Winner = if_else(home_score > away_score, home_team,
                     if_else(home_score < away_score, away_team, "TIE"))
  )

#get next score half using the provided function
pbp_next_score_half <- map_dfr(unique(pbp_data$game_id),
                               function(x) {
                                 pbp_data %>%
                                   filter(game_id == x) %>%
                                   find_game_next_score_half()
                               })

#bind to original df
pbp_data <- bind_cols(pbp_data, pbp_next_score_half)

#for estimating the models, apply some filters
pbp_data <- pbp_data %>%
  filter(Next_Score_Half %in% c("Opp_Field_Goal", "Opp_Safety", "Opp_Touchdown",
                                "Field_Goal", "No_Score", "Safety", "Touchdown") &
           play_type %in% c("field_goal", "no_play", "pass", "punt", "run",
                            "qb_spike") & is.na(two_point_conv_result) & is.na(extra_point_result) &
           !is.na(down) & !is.na(game_seconds_remaining)) %>%
  #to keep file size manageable
  select(
    game_id,
    Next_Score_Half,
    Drive_Score_Half,
    play_type,
    game_seconds_remaining,
    half_seconds_remaining,
    yardline_100,
    roof,
    posteam,
    defteam,
    home_team,
    ydstogo,
    season,
    qtr,
    down,
    week,
    drive,
    ep,
    score_differential,
    posteam_timeouts_remaining,
    defteam_timeouts_remaining,
    desc,
    receiver_player_name,
    pass_location,
    air_yards,
    yards_after_catch,
    complete_pass, incomplete_pass, interception,
    qb_hit,
    extra_point_result,
    field_goal_result,
    sp,
    Winner,
    spread_line
  )

#for doing calibation etc
saveRDS(pbp_data, 'models/cal_data.rds')

################################################################################
# DATA PREP FOR NFLSCRAPR COMPARISON
# This is only used in the readme describing the models
# Where we compare nflscrapR and nflfastR calibration errors
################################################################################

pbp_data <- purrr::map_df(2000 : 2019, function(x) {
  readRDS(
    url(
      glue::glue("https://raw.githubusercontent.com/guga31bb/nflfastR-data/master/legacy-data/play_by_play_{x}.rds")
    )
  ) %>% filter(season_type == 'REG')
})

games <- readRDS(url("http://www.habitatring.com/games.rds")) %>%
  filter(!is.na(result)) %>%
  mutate(
    game_id = as.numeric(old_game_id),
    Winner = if_else(home_score > away_score, home_team,
                     if_else(home_score < away_score, away_team, "TIE"))
  ) %>%
  select(game_id, Winner, result, roof)

pbp_data <- pbp_data %>%
  left_join(
    games, by = c('game_id')
  )

#get next score half using the provided function
pbp_next_score_half <- map_dfr(unique(pbp_data$game_id),
                               function(x) {
                                 pbp_data %>%
                                   filter(game_id == x) %>%
                                   find_game_next_score_half()
                               })

#bind to original df
pbp_data <- bind_cols(pbp_data, pbp_next_score_half)

#apply filters
pbp_data <- pbp_data %>%
  filter(Next_Score_Half %in% c("Opp_Field_Goal", "Opp_Safety", "Opp_Touchdown",
                                "Field_Goal", "No_Score", "Safety", "Touchdown") &
           play_type %in% c("field_goal", "no_play", "pass", "punt", "run",
                            "qb_spike") & is.na(two_point_conv_result) & is.na(extra_point_result) &
           !is.na(down) & !is.na(game_seconds_remaining)) %>%
  select(posteam, wp, qtr, Winner, td_prob, opp_td_prob, fg_prob, opp_fg_prob, safety_prob, opp_safety_prob, no_score_prob, Next_Score_Half)

#for doing calibation etc
saveRDS(pbp_data, 'models/cal_data_nflscrapr.rds')
