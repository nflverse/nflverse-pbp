cli::rule("Start teams data update process")

# Load currently released data
released <- data.table::fread(paste0(
  "https://github.com/nflverse/nflverse-data/",
  "releases/download/teams/teams_colors_logos.csv"
), na.strings = "")

# Load data in nflverse-pbp repo
repo_data <- data.table::fread("teams_colors_logos.csv", na.strings = "")

# The workflow should only trigger if the data changed but it doesn't hurt
# to make sure we only update the data if the comparison shows that something
# really has changed
if (!identical(released, repo_data)) {
  cli::cli_alert_info("Going to release updated teams data.")
  out <- dplyr::rows_upsert(released, repo_data, by = "team_abbr") |>
    dplyr::as_tibble()
  nflversedata::nflverse_save(
    data_frame = out,
    file_name = "teams_colors_logos",
    nflverse_type = "teams data",
    release_tag = "teams",
    file_types = c("rds", "csv", "parquet", "qs", "csv.gz"),
  )
} else {
  cli::cli_alert_success("Nothing changed. Teams data is up to date.")
}

cli::rule("Process complete")
