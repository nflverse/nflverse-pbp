# Download the raw game files of a season once per R session and return the
# IDs of all finished games of that season.
#
# release_pbp() and release_pbp_stats() both need the same raw files. When they
# run in the same job, the second call reuses the local copies instead of
# downloading the whole season again.
.raw_pbp_ids <- new.env(parent = emptyenv())

prepare_raw_pbp <- function(season) {
  key <- as.character(season)
  if (!is.null(.raw_pbp_ids[[key]])) return(.raw_pbp_ids[[key]])

  raw_dir <- file.path(tempdir(check = TRUE), "pbp")
  if (!dir.exists(raw_dir)) dir.create(raw_dir)
  options("nflfastR.raw_directory" = raw_dir)

  # The directory starts empty, so this returns all finished games of the season
  ids <- nflfastR::missing_raw_pbp(seasons = season)
  if (length(ids) > 0) nflfastR::save_raw_pbp(ids)

  .raw_pbp_ids[[key]] <- ids
  ids
}
