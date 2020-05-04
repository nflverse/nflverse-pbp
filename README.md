# nflfastR-data
NFL play-by-play data scraped from the [`nflfastR` package](https://github.com/mrcaseb/nflfastR) going back to 2000. Each season contains both regular season and postseason data, with game_type denoting which.

Data are stored in the data folder, available as either .csv or .rds.

We highly recommend loading the data in the binary .rds format. The following example shows how to load the seasons 2010 to 2019 and bind them into a single dataframe:

```R
# define which seasons shall be loaded
seasons <- 2010:2019
pbp <- purrr::map_df(seasons, function(x) {
  readRDS(
    url(
      glue::glue("https://raw.githubusercontent.com/guga31bb/nflfastR-data/master/data/play_by_play_{x}.rds")
    )
  )
})

roster <- readRDS(url("https://raw.githubusercontent.com/guga31bb/nflfastR-data/master/roster-data/roster.rds"))
```

However, if you want to load the data as .csv run this:
```R
# define which seasons shall be loaded
seasons <- 2010:2019
pbp <- purrr::map_df(seasons, function(x) {
  readr::read_csv(
    glue::glue("https://raw.githubusercontent.com/guga31bb/nflfastR-data/master/data/play_by_play_{x}.csv")
  )
})

roster <- readr::read_csv("https://raw.githubusercontent.com/guga31bb/nflfastR-data/master/roster-data/roster.csv")
```