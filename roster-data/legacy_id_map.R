library(tidyverse)
source("https://raw.githubusercontent.com/mrcaseb/nflfastR/master/R/helper_additional_functions.R")

# Load roster and filter players in both eras -----------------------------

roster <- readRDS(url("https://github.com/guga31bb/nflfastR-data/blob/master/roster-data/roster.rds?raw=true"))
# roster are very detailed so there are much more players in here than players
# appear in the id columns in the pbp data
both_eras <- roster %>%
  group_by(teamPlayers.gsisId) %>%
  summarise(
    name = first(teamPlayers.displayName),
    seasons = n(),
    first_year = first(team.season),
    last_year = last(team.season)
  ) %>%
  filter(first_year < 2011 & last_year >= 2011 & !is.na(teamPlayers.gsisId))


# Load legacy pbp 2011++ --------------------------------------------------

seasons <- 2011:2019
legacy_pbp <- purrr::map_df(seasons, function(x) {
  readRDS(
    url(
      glue::glue("https://raw.githubusercontent.com/guga31bb/nflfastR-data/master/legacy-data/play_by_play_{x}.rds")
    )
  )
})

legacy_pbp_players <- legacy_pbp %>%
  select(season, week, home_team, away_team, play_id, ends_with("player_id")) %>%
  mutate(week = if_else(week == 22, 21, week)) %>%
  pivot_longer(ends_with("player_id"),
               names_to = "player_desc",
               values_to = "gsis_id",
               values_drop_na = TRUE)

# Load new pbp 2011++ -----------------------------------------------------

pbp <- purrr::map_df(seasons, function(x) {
  readRDS(
    url(
      glue::glue("https://raw.githubusercontent.com/guga31bb/nflfastR-data/master/data/play_by_play_{x}.rds")
    )
  )
})

pbp_players <- pbp %>%
  select(season, week, home_team, away_team, play_id, ends_with("player_id")) %>%
  pivot_longer(ends_with("player_id"),
               names_to = "player_desc",
               values_to = "new_id",
               values_drop_na = TRUE)

# Join everything together ------------------------------------------------

both_eras_id_map <- legacy_pbp_players %>%
  left_join(
    pbp_players,
    by = c("season", "week", "home_team", "away_team", "play_id", "player_desc")
  ) %>%
  group_by(gsis_id) %>%
  mutate(new_id = custom_mode(new_id)) %>%
  ungroup() %>%
  select(gsis_id, new_id) %>%
  distinct() %>%
  left_join(
    both_eras %>% select(teamPlayers.gsisId, full_name = name),
    by = c("gsis_id" = "teamPlayers.gsisId")
  ) %>%
  select(full_name, gsis_id, new_id) %>%
  filter(gsis_id %in% both_eras$teamPlayers.gsisId) %>% 
  arrange(gsis_id)

saveRDS(both_eras_id_map, "roster-data/legacy_id_map.rds")
write_csv(both_eras_id_map, "roster-data/legacy_id_map.csv")

# both_eras_id_map %>%
#   group_by(gsis_id) %>%
#   summarise(n=n()) %>%
#   filter(n>1)
