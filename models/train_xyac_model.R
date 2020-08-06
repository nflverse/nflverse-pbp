################################################################################
# Author: Ben Baldwin
# Purpose: Estimate nflfastR models for EP, CP, Field Goals, and WP
################################################################################

library(tidyverse)
library(xgboost)
source('https://raw.githubusercontent.com/mrcaseb/nflfastR/master/R/helper_add_ep_wp.R')
source('https://raw.githubusercontent.com/mrcaseb/nflfastR/master/R/helper_add_cp_cpoe.R')
source('https://raw.githubusercontent.com/mrcaseb/nflfastR/master/R/helper_add_nflscrapr_mutations.R')

set.seed(2013) #GoHawks

################################################################################
# Estimate EP model
################################################################################

# from local
pbp_data <- readRDS('models/cal_data.rds')


################################################################################
# Estimate xYAC model
################################################################################

model_vars <- pbp_data %>%
  make_model_mutations() %>%
  filter(season >= 2006, complete_pass == 1, !is.na(yards_after_catch),
         yards_after_catch >= -20, air_yards < yardline_100) %>%
  dplyr::mutate(
    distance_to_goal = yardline_100 - air_yards,
    pass_middle = dplyr::if_else(pass_location == 'middle', 1, 0),
    air_is_zero= dplyr::if_else(air_yards == 0,1,0),
    distance_to_sticks = air_yards - ydstogo,
    yards_after_catch = dplyr::case_when(
      yards_after_catch < -5 ~ -5,
      yards_after_catch > 70 ~ 70,
      TRUE ~ yards_after_catch
    ),
    label = yards_after_catch + 5
  ) %>%
  dplyr::filter(!is.na(air_yards) & air_yards >= -15 & air_yards <70 & !is.na(pass_location)) %>%
  dplyr::select(
    label, air_yards, yardline_100, ydstogo, distance_to_goal,
    down1, down2, down3, down4, air_is_zero, pass_middle,
    era2, era3, era4, qb_hit, home,
    outdoors, retractable, dome, distance_to_sticks
  )

nrounds = 500
params <-
  list(
    booster = "gbtree",
    objective = "multi:softprob",
    eval_metric = c("mlogloss"),
    num_class = 76,
    eta = .025,
    gamma = 2,
    subsample=0.8,
    colsample_bytree=0.8,
    max_depth = 4,
    min_child_weight = 1
  )

full_train = xgboost::xgb.DMatrix(model.matrix(~.+0, data = model_vars %>% dplyr::select(-label)), label = as.integer(model_vars$label))

xyac_model <- xgboost::xgboost(params = params, data = full_train, nrounds = nrounds, verbose = 2)

save(xyac_model, 'models/xyac_model.Rdata')



