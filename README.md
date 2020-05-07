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

If you are using Python you can load the compressed csv data. The following example written by [Deryck](https://twitter.com/Deryck_SG) (thanks a lot!) loads the seasons 2017 to 2019 (binded into a single pandas dataframe) as well as rosters (from 2000 to latest season):
```Python
import pandas as pd 

#Enter desired years of data
YEARS = [2019,2018,2017]

data = pd.DataFrame()

for i in YEARS:  
    #low_memory=False eliminates a warning
    i_data = pd.read_csv('https://github.com/guga31bb/nflfastR-data/blob/master/' \
                         'data/play_by_play_' + str(i) + '.csv.gz?raw=true',
                         compression='gzip', low_memory=False)

    #sort=True eliminates a warning and alphabetically sorts columns
    data = data.append(i_data, sort=True)
    
roster = pd.read_csv('https://raw.githubusercontent.com/guga31bb/nflfastR-data/master/' \ 
                     'roster-data/roster.csv.gz', compression='gzip', low_memory=False)
```
