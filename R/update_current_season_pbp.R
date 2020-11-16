source("R/save_pbp.R")

y <- dplyr::if_else(
  lubridate::month(lubridate::today("America/New_York")) >= 9,
  lubridate::year(lubridate::today("America/New_York")) ,
  lubridate::year(lubridate::today("America/New_York")) - 1
)

save_pbp(y)
#
