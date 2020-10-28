source("R/save_pbp.R")

y <- dplyr::if_else(
  lubridate::month(lubridate::today("America/New_York")) >= 9,
  lubridate::year(lubridate::today("America/New_York")) ,
  lubridate::year(lubridate::today("America/New_York")) - 1
)

purrr::walk(1999:(y-1), save_pbp)

# Any change in this script will trigger redownload of all seasons
# starting in 1999.
