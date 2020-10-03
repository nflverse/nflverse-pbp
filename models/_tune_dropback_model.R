library(tidyverse)
set.seed(2013)

model_vars <- readRDS('models/_dropback_model_data.rds')

full_train = xgboost::xgb.DMatrix(model.matrix(~.+0, data = model_vars %>% dplyr::select(-label)), label = as.integer(model_vars$label))

#params
nrounds = 2000

x = c(7) #max depth
y = c(.015) #something else to tune

search <- map_df(cross2(x, y), function(x) {
  
  depth = x[[1]]
  eta = x[[2]]
  
  print(message(glue::glue('max depth {depth} and eta {eta}')))
  
  params <-
    list(
      booster = "gbtree",
      objective = "binary:logistic",
      eval_metric = c("error", "logloss"),
      eta = eta,
      gamma = 2,
      subsample=0.8,
      colsample_bytree=0.8,
      max_depth = 7,
      min_child_weight = 0.9,
      base_score = mean(model_vars$label)
    )
  
  #train
  xp_cv_model <- xgboost::xgb.cv(data = full_train, params = params, nrounds = nrounds,
                                 nfold = 10, metrics = list("error", "logloss"),
                                 early_stopping_rounds = 3, print_every_n = 10)
  
  iter = xp_cv_model$best_iteration
  
  result <- data.frame(
    'eta' = eta,
    'iter' = iter,
    'logloss' = xp_cv_model$evaluation_log[iter]$test_logloss_mean,
    'error' = xp_cv_model$evaluation_log[iter]$test_error_mean,
    'gamma' = 2,
    'max_depth' = 7,
    'min_child_weight' = 0.9,
    'subsample' = 0.8,
    'colsample' = 0.8
  ) %>%
    as_tibble()
  
  return(result)
  
})


search %>%
  arrange(logloss) 


# best
best <- search %>% 
  arrange(logloss) %>%
  dplyr::slice(1)

message(
  glue::glue("
  error: {best$error}
  loglos: {best$logloss}
  iter: {best$iter}
  eta: {best$eta}
  gamma: {best$gamma}
  depth: {best$max_depth}
  weight: {best$min_child_weight}
             ")
)
  
error: 0.289332
loglos: 0.5223975
iter: 722
eta: 0.025
gamma: 2
depth: 7
weight: 0.9


