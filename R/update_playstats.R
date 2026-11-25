release_pbp_stats <- function(season) {

  prepare_raw_pbp(season)

  playstats <- nflfastR:::build_playstats(seasons = season)

  if(nrow(playstats) == 0){
    cli::cli_alert_warning("Download failed. Gonna abort")
    return(NULL)
  }

  attr(playstats,"nflfastR_version") <- as.character(packageVersion("nflfastR"))

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
