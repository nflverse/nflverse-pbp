library(tidyverse)
library(tidymodels)


# get data and split
model_vars <- readRDS('models/_dropback_model_data.rds')

dat_split <- initial_split(model_vars)
dat_train <- training(dat_split)
dat_test <- testing(dat_split)
qb_folds <- vfold_cv(dat_train)

# recipe
qb_recipe <- recipe(label ~ 
                      down + 
                      ydstogo + 
                      yardline_100 + 
                      score_differential + 
                      qtr + 
                      half_seconds_remaining +
                      posteam_timeouts_remaining +
                      defteam_timeouts_remaining +
                      wp +
                      vegas_wp +
                      home +
                      dome +
                      outdoors +
                      retractable,
                    data = dat_train)

# set model
qb_model <- 
  boost_tree(
    mtry = tune(),
    trees = 2000, 
    min_n = tune(),
    tree_depth = tune(),
    learn_rate = tune(),
    loss_reduction = tune(),                    
    sample_size = tune(),         
    stop_iter = 100
  ) %>% 
  set_engine("xgboost") %>% 
  set_mode("classification")

# add workflow
qb_workflow <- workflow() %>%
  add_recipe(qb_recipe) %>%
  add_model(qb_model)

# create the grid
xgb_grid <- grid_latin_hypercube(
  finalize(mtry(), dat_train),
  min_n(),
  tree_depth(),
  learn_rate(),
  loss_reduction(),
  sample_size = sample_prop(),
  size = 40
)

# tune (takes a long time)
xgb_res <- tune_grid(
  qb_workflow,
  resamples = qb_folds,
  grid = xgb_grid,
  control = control_grid(save_pred = TRUE)
)





