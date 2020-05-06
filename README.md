# nflfastR-data
NFL play-by-play data scraped from the [`nflfastR` package](https://github.com/mrcaseb/nflfastR) going back to 2000. Each season contains both regular season and postseason data, with game_type denoting which.

Data are stored in the data folder, available as either compressed csv (.csv.gz) or .rds.

___

### Load data using R
We highly recommend loading the data in the binary .rds format. The following example shows how to load the seasons 2010 to 2019 (binded into a single dataframe) as well as rosters (from 2000 to latest season):

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

However, if you want to load the compressed csv data run this:
```R
# define which seasons shall be loaded
seasons <- 2010:2019
pbp <- purrr::map_df(seasons, function(x) {
  readr::read_csv(
    glue::glue("https://raw.githubusercontent.com/guga31bb/nflfastR-data/master/data/play_by_play_{x}.csv.gz")
  )
})

roster <- readr::read_csv("https://raw.githubusercontent.com/guga31bb/nflfastR-data/master/roster-data/roster.csv.gz")
```

___

### Load data using Python

TBA