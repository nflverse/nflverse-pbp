"%>%" <- magrittr::`%>%`

current_season <- dplyr::if_else(
  lubridate::month(lubridate::today("GMT")) >= 9,
  lubridate::year(lubridate::today("GMT")),
  lubridate::year(lubridate::today("GMT")) - 1
)

games <- readRDS(url("https://github.com/leesharpe/nfldata/blob/master/data/games.rds?raw=true")) %>%
  dplyr::select(
    game_id, season, game_type, week, gameday, weekday, gametime, away_team,
    home_team, away_score, home_score,
    home_result = result, stadium, location, roof, surface, old_game_id
  )

save_sched <- function(s, all_games) {
  g <- all_games %>% dplyr::filter(season == s)
  saveRDS(g, glue::glue("schedules/sched_{s}.rds"))
}

save_sched(current_season, games)

# update all seasons in case bugs were fixed
# purrr::walk(1999:2020, save_sched, games)
