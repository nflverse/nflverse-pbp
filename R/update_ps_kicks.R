update_kicks <- function(season){
  `%>%` <- magrittr::`%>%`
  cli::cli_process_start("Calculating kicking stats for {season}")
  pbp <- nflreadr::load_pbp(season)

  base_kicks <- pbp %>%
    dplyr::filter(field_goal_attempt == 1 | extra_point_attempt == 1) %>%
    dplyr::select(
      season,
      week,
      season_type,
      team = posteam,
      player_name = kicker_player_name,
      player_id = kicker_player_id,
      kick_distance,
      field_goal_attempt,
      extra_point_attempt,
      field_goal_result,
      extra_point_result
    ) %>%
    dplyr::group_by(season,week,season_type,team,player_name,player_id) %>%
    dplyr::summarise(
      fg_made = sum(field_goal_result == "made", na.rm = TRUE),
      fg_missed = sum(field_goal_result == "missed", na.rm = TRUE),
      fg_blocked = sum(field_goal_result == "blocked", na.rm = TRUE),
      fg_long = max(as.numeric(field_goal_result == "made") * kick_distance,0, na.rm = TRUE),
      fg_att = sum(field_goal_attempt,na.rm = TRUE),
      fg_pct = round(fg_made /fg_att, 3),
      pat_made = sum(extra_point_result == "good", na.rm = TRUE),
      pat_missed = sum(extra_point_result == "failed", na.rm = TRUE),
      pat_blocked = sum(extra_point_result == "blocked", na.rm = TRUE),
      pat_att = sum(extra_point_attempt, na.rm = TRUE),
      pat_pct = round(pat_made/pat_att, 3),
      fg_made_distance = sum(as.numeric(field_goal_result == "made") * kick_distance, na.rm = TRUE),
      fg_missed_distance = sum(as.numeric(field_goal_result == "missed") * kick_distance, na.rm = TRUE),
      fg_blocked_distance = sum(as.numeric(field_goal_result == "blocked") * kick_distance, na.rm = TRUE),
      fg_made_0_19 = sum(as.numeric(field_goal_result == "made") * dplyr::between(kick_distance,0,19), na.rm = TRUE),
      fg_made_20_29 = sum(as.numeric(field_goal_result == "made") * dplyr::between(kick_distance,20,29), na.rm = TRUE),
      fg_made_30_39 = sum(as.numeric(field_goal_result == "made") * dplyr::between(kick_distance,30,39), na.rm = TRUE),
      fg_made_40_49 = sum(as.numeric(field_goal_result == "made") * dplyr::between(kick_distance,40,49), na.rm = TRUE),
      fg_made_50_59 = sum(as.numeric(field_goal_result == "made") * dplyr::between(kick_distance,50,59), na.rm = TRUE),
      fg_made_60_ = sum(as.numeric(field_goal_result == "made") * (kick_distance >=60), na.rm = TRUE),
      fg_missed_0_19 = sum(as.numeric(field_goal_result == "missed") * dplyr::between(kick_distance,0,19), na.rm = TRUE),
      fg_missed_20_29 = sum(as.numeric(field_goal_result == "missed") * dplyr::between(kick_distance,20,29), na.rm = TRUE),
      fg_missed_30_39 = sum(as.numeric(field_goal_result == "missed") * dplyr::between(kick_distance,30,39), na.rm = TRUE),
      fg_missed_40_49 = sum(as.numeric(field_goal_result == "missed") * dplyr::between(kick_distance,40,49), na.rm = TRUE),
      fg_missed_50_59 = sum(as.numeric(field_goal_result == "missed") * dplyr::between(kick_distance,50,59), na.rm = TRUE),
      fg_missed_60_ = sum(as.numeric(field_goal_result == "missed") * (kick_distance >=60), na.rm = TRUE),
      fg_made_list = kick_distance[field_goal_result == "made"] %>% na.omit() %>%  paste(collapse = ";"),
      fg_missed_list = kick_distance[field_goal_result == "missed"] %>% na.omit() %>% paste(collapse = ";"),
      fg_blocked_list = kick_distance[field_goal_result == "blocked"] %>% na.omit() %>% paste(collapse = ";")
    ) %>%
    dplyr::ungroup()

  game_winners <- pbp %>%
    dplyr::group_by(game_id,posteam) %>%
    dplyr::filter(fixed_drive == max(fixed_drive)) %>%
    dplyr::ungroup() %>%
    dplyr::filter(field_goal_attempt == 1, dplyr::between(score_differential,-2,0)) %>%
    dplyr::select(
      season,
      week,
      season_type,
      team = posteam,
      qtr,
      game_seconds_remaining,
      score_differential,
      desc,
      player_name = kicker_player_name,
      player_id = kicker_player_id,
      kick_distance,
      field_goal_attempt,
      extra_point_attempt,
      field_goal_result,
      extra_point_result
    ) %>%
    dplyr::group_by(season,week,season_type,team,player_name,player_id) %>%
    dplyr::summarise(
      gwfg_att = dplyr::n(),
      gwfg_distance = kick_distance,
      gwfg_made = sum(field_goal_result == "made", na.rm = TRUE),
      gwfg_missed = sum(field_goal_result == "missed", na.rm = TRUE),
      gwfg_blocked = sum(field_goal_result == "blocked", na.rm = TRUE),
    ) %>%
    dplyr::ungroup()

  full_kicks <- base_kicks %>%
    dplyr::left_join(
      game_winners,
      by = c("season", "week", "season_type", "team", "player_name", "player_id")) %>%
    dplyr::mutate(
      dplyr::across(dplyr::starts_with("gwfg"), tidyr::replace_na,0)
    ) %>%
    dplyr::relocate(
      dplyr::starts_with("gwfg"),
      .after = fg_blocked_distance
    )

  attr(full_kicks, "nflverse_timestamp") <- Sys.time()
  attr(full_kicks, "nflverse_type") <- "player stats: kicking"
  attr(full_kicks, "nflfastR_version") <- packageVersion("nflfastR")

  saveRDS(full_kicks, glue::glue('data/player_stats_kicking/player_stats_kicking_{season}.rds'))
  # csv.gz
  data.table::fwrite(full_kicks, glue::glue('data/player_stats_kicking/player_stats_kicking_{season}.csv'))
  readr::write_csv(full_kicks, glue::glue('data/player_stats_kicking/player_stats_kicking_{season}.csv.gz'))
  # .parquet
  arrow::write_parquet(full_kicks, glue::glue('data/player_stats_kicking/player_stats_kicking_{season}.parquet'))
  # .qs
  qs::qsave(full_kicks, glue::glue('data/player_stats_kicking/player_stats_kicking_{season}.qs'),
            preset = "custom",
            algorithm = "zstd_stream",
            compress_level = 22,
            shuffle_control = 15)

  cli::cli_process_done(msg_done = "Calculating kicking stats for {season}...done! {Sys.time()}")
}

combine_kicks <- function(season = 1999:nflreadr:::most_recent_season()){

  cli::cli_process_start("Combining kicking data into one file")

  full_kicks <- purrr::map_dfr(season,~qs::qread(paste0("data/player_stats_kicking/player_stats_kicking_",.x,".qs")))

  attr(full_kicks, "nflverse_timestamp") <- Sys.time()
  attr(full_kicks, "nflverse_type") <- "player stats: kicking"
  attr(full_kicks, "nflfastR_version") <- packageVersion("nflfastR")

  saveRDS(full_kicks, glue::glue('data/player_stats_kicking.rds'))
  
  # csv.gz
  data.table::fwrite(full_ckicks, glue::glue('data/player_stats_kicking.csv.gz')) 
  readr::write_csv(full_kicks, glue::glue('data/player_stats_kicking.csv.gz'))
  # .parquet
  arrow::write_parquet(full_kicks, glue::glue('data/player_stats_kicking.parquet'))
  # .qs
  qs::qsave(full_kicks, glue::glue('data/player_stats_kicking.qs'),
            preset = "custom",
            algorithm = "zstd_stream",
            compress_level = 22,
            shuffle_control = 15)

  cli::cli_process_done()

}

update_kicks(nflreadr:::most_recent_season())
combine_kicks()

c("data/player_stats_kicking.qs",
  "data/player_stats_kicking.rds",
  "data/player_stats_kicking.csv",
  "data/player_stats_kicking.csv.gz",
  "data/player_stats_kicking.parquet") |>
  nflversedata::nflverse_upload("player_stats")

list.files("data/player_stats_kicking", full.names = TRUE) |> nflversedata::nflverse_upload("player_stats")
