
seasons <- 2019
pbp <- purrr::map_df(seasons, function(x) {
  readRDS(
    url(
      glue::glue("https://raw.githubusercontent.com/guga31bb/nflfastR-data/master/data/play_by_play_{x}.rds")
    )
  )
})

pbp %>%
  add_xp() %>%
  select(desc, down, ydstogo, pass, xp, poe)



add_xp <- function(pbp) {
  
  # testing only
  # pbp <- g
  
  plays <- prepare_xp_data(pbp)
  
  if (!nrow(plays %>% dplyr::filter(.data$valid_play == 1)) == 0) {
    
    # uncomment when file is pushed
    # xpass_model <- NULL
    # suppressWarnings(
    #   # load the model from github because it is too big for the package
    #   try(
    #     load(url("https://github.com/guga31bb/nflfastR-data/blob/master/models/xpass_model.Rdata?raw=true")),
    #     silent = TRUE
    #   )
    # )
    
    pred <- stats::predict(xpass_model, as.matrix(plays %>% dplyr::select(-"valid_play"))) %>%
      tibble::as_tibble() %>%
      dplyr::rename(xp = "value") %>%
      dplyr::bind_cols(plays) %>%
      dplyr::select("xp", "valid_play")
    
    pbp <- pbp %>%
      dplyr::bind_cols(pred) %>%
      dplyr::mutate(
        xp = dplyr::if_else(
          .data$valid_play == 1, .data$xp, NA_real_
        ),
        poe = dplyr::if_else(!is.na(.data$xp), 100 * (.data$pass - .data$xp), NA_real_)
      ) %>%
      dplyr::select(-"valid_play")
    
    usethis::ui_done("added xp and poe")
  } else {
    pbp <- pbp %>%
      dplyr::mutate(
        xp = NA_real_,
        poe = NA_real_
      )
    usethis::ui_info("No non-NA values for xp calculation detected. xp and poe set to NA")
  }
  
  return(pbp)
}


prepare_xp_data <- function(pbp) {
  
  # valid pass play: at least -15 air yards, less than 70 air yards, has intended receiver, has pass location
  plays <- pbp %>%
    dplyr::mutate(
      valid_play = dplyr::if_else(
        season >= 2006 &
        !is.na(posteam) &
        !is.na(down) &
        !is.na(defteam_timeouts_remaining) &
        !is.na(posteam_timeouts_remaining) &
        !is.na(yardline_100) &
        !is.na(score_differential),
        1, 0
      )
    ) %>%
    make_model_mutations() %>%
    select(
      valid_play,
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
  
  return(plays)
}

