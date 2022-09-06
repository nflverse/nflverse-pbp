laterals <- readr::read_csv(
  "lateral_yards/multiple_lateral_yards.csv",
  show_col_types = FALSE
)

nflversedata::nflverse_save(
  data_frame = laterals,
  file_name = "multiple_lateral_yards",
  nflverse_type = "multiple_lateral_yards",
  release_tag = "misc",
  file_types = c("rds", "csv")
)
