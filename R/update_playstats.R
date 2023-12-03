save_playstats <- function(season) {

  playstats <- purrr::possibly(
    nflfastR:::build_playstats,
    otherwise = data.frame(),
    quiet = FALSE
  )(seasons = season)

  if(nrow(playstats) == 0){
    cli::cli_alert_warning("Download failed. Gonna abort")
    return(NULL)
  }

  attr(playstats,"nflfastR_version") <- packageVersion("nflfastR")

  nflversedata::nflverse_save(
    data_frame = playstats,
    file_name =  glue::glue("play_stats_{season}"),
    nflverse_type = "play by play stats",
    release_tag = "playstats",
    file_types = c("rds"),
    repo = "nflverse/nflverse-pbp"
  )

  cli::cli_alert_success("Saved {season} play stats data.")
}

future::plan(future::multisession)
if(Sys.getenv("NFLVERSE_REBUILD","false")=="true"){
  purrr::walk(1999:nflreadr::most_recent_season(), save_playstats)
} else {
  save_playstats(nflreadr::most_recent_season())
}
future::plan(future::sequential)
