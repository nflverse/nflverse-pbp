season <- Sys.getenv("NFLVERSE_UPDATE_SEASON", unset = NA_character_)
type <- Sys.getenv("NFLVERSE_UPDATE_TYPE", unset = NA_character_)

if (any(is.na(season), is.na(type))) {
  cli::cli_abort("Can't find season {.val {season}} or type {.val {type}}")
} else if (type == "pbp") {
  source("R/update_pbp.R")
  save_pbp(season)
}