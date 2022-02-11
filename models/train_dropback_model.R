library(tidyverse)
set.seed(2013)

model_vars <- readRDS('models/_dropback_model_data.rds')

# still need to set this
nrounds = 1121

params <-
  list(
    booster = "gbtree",
    objective = "binary:logistic",
    eval_metric = c("error", "logloss"),
    eta = .015,
    gamma = 2,
    subsample=0.8,
    colsample_bytree=0.8,
    max_depth = 7,
    min_child_weight = 0.9,
    base_score = mean(model_vars$label)
  )

full_train = xgboost::xgb.DMatrix(model.matrix(~.+0, data = model_vars %>% dplyr::select(-label)), label = as.integer(model_vars$label))

xpass_model <- xgboost::xgboost(params = params, data = full_train, nrounds = nrounds, verbose = 2)

save(xpass_model, file = 'models/xpass_model.Rdata')

importance <- xgboost::xgb.importance(feature_names = colnames(xpass_model), model = xpass_model)
xgboost::xgb.ggplot.importance(importance_matrix = importance)
