# nflfastR-data
NFL play-by-play data scraped from the [`nflfastR` package](https://github.com/nflverse/nflfastR) going back to 1999. Each season contains both regular season and postseason data, with `game_type` or `week` denoting which.

Data are stored in the data folder, available as either compressed csv (.csv.gz) .rds, or .parquet.

___

## Load data using R

### nflreadr

The easiest way to load the play-by-play data in R is with `nflreadr`. So after running

```r
install.packages("nflreadr")
```

all you need to do to load a bunch of seasons is

```r
# define which seasons shall be loaded
seasons <- 2018:2020
pbp <- nflreadr::load_pbp(seasons)
```
___

## Load data using Python

If you are using Python (or anything else that isn't R) you can load the compressed csv data. The following example written by [Deryck](https://twitter.com/Deryck_SG) (thanks a lot!) loads the seasons 2017 to 2019 (binded into a single pandas dataframe) as well as rosters (from 2000 to latest season):
```Python
import pandas as pd 

#Enter desired years of data
YEARS = [2019,2018,2017]

data = pd.DataFrame()

for i in YEARS:  
    #low_memory=False eliminates a warning
    i_data = pd.read_csv('https://github.com/nflverse/nflfastR-data/blob/master/data/' \
                         'play_by_play_' + str(i) + '.csv.gz?raw=True',
                         compression='gzip', low_memory=False)

    #sort=True eliminates a warning and alphabetically sorts columns
    data = data.append(i_data, sort=True)

#Give each row a unique index
data.reset_index(drop=True, inplace=True)

```
