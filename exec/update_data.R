season <- Sys.getenv("NFLVERSE_UPDATE_SEASON", unset = NA_character_) |> as.integer()
# One or more comma separated types, e.g. "pbp,pbp_stats". Types in one job
# share the downloaded raw game files.
types <- Sys.getenv("NFLVERSE_UPDATE_TYPE", unset = NA_character_) |>
  strsplit(",", fixed = TRUE) |>
  unlist() |>
  trimws()
invalid <- setdiff(types, c("pbp", "pbp_stats", "stats"))
if (length(invalid) > 0 || length(types) == 0) {
  cli::cli_abort(
    "Invalid {.envvar NFLVERSE_UPDATE_TYPE}: {.val {invalid}}. \\
    Allowed: {.val {c('pbp', 'pbp_stats', 'stats')}}"
  )
}

# Run parallel
future::plan("multisession")
options(nflreadr.verbose = FALSE)
source("R/timestamps.R")
source("R/raw_pbp.R")
source("R/update_pbp.R")
source("R/update_playstats.R")
source("R/update_stats.R")

releases <- list(
  "pbp" = release_pbp,
  "pbp_stats" = release_pbp_stats,
  "stats" = release_stats
)

# Run every type even if an earlier one fails, then fail the job at the end
failed <- character()
for (type in types) {
  cli::cli_rule("{season} {type}")
  tryCatch(
    releases[[type]](season),
    error = function(e) {
      cli::cli_alert_danger("{season} {type} failed: {conditionMessage(e)}")
      failed <<- c(failed, type)
    }
  )
}

if (length(failed) > 0) {
  cli::cli_abort("{season}: {length(failed)} release{?s} failed: {.val {failed}}")
}
