Working with nflfastR rosters
================
Ben Baldwin
9/24/2020

At long last, there’s a way to merge the new play-by-play data with
roster information in nflfastR 3.0. First, install the upgrade from
CRAN:

``` r
install.packages("nflfastR")
```

And then load the library:

``` r
library(nflfastR)
library(tidyverse)
```

    ## -- Attaching packages -------------------------------------------------------------- tidyverse 1.3.0 --

    ## v ggplot2 3.3.2     v purrr   0.3.4
    ## v tibble  3.0.0     v dplyr   0.8.5
    ## v tidyr   1.0.2     v stringr 1.4.0
    ## v readr   1.3.1     v forcats 0.5.0

    ## -- Conflicts ----------------------------------------------------------------- tidyverse_conflicts() --
    ## x dplyr::filter() masks stats::filter()
    ## x dplyr::lag()    masks stats::lag()

The easy part is getting the rosters. There’s a new function called
`fast_scraper_roster`.

``` r
roster <- fast_scraper_roster(2019)

roster %>%
  filter(team == "SEA", position %in% c("WR", "TE"))
```

    ## # A tibble: 23 x 21
    ##    season team  position depth_chart_pos~ jersey_number status full_name
    ##     <dbl> <chr> <chr>    <chr>                    <int> <chr>  <chr>    
    ##  1   2019 SEA   TE       <NA>                        NA DEV    Wes Saxt~
    ##  2   2019 SEA   TE       <NA>                        48 ACT    Jacob Ho~
    ##  3   2019 SEA   TE       <NA>                        47 CUT    Jackson ~
    ##  4   2019 SEA   TE       <NA>                        82 ACT    Luke Wil~
    ##  5   2019 SEA   TE       <NA>                        88 RES    Will Dis~
    ##  6   2019 SEA   TE       <NA>                        86 RES    Justin J~
    ##  7   2019 SEA   TE       <NA>                        84 RES    Ed Dicks~
    ##  8   2019 SEA   TE       <NA>                        46 ACT    Tyrone S~
    ##  9   2019 SEA   WR       <NA>                        10 SUS    Josh Gor~
    ## 10   2019 SEA   WR       <NA>                        83 ACT    David Mo~
    ## # ... with 13 more rows, and 14 more variables: first_name <chr>,
    ## #   last_name <chr>, birth_date <chr>, height <chr>, weight <chr>,
    ## #   college <chr>, high_school <chr>, gsis_id <chr>, espn_id <int>,
    ## #   sportradar_id <chr>, yahoo_id <int>, rotowire_id <int>, update_dt <dttm>,
    ## #   headshot_url <chr>

Now let’s load play-by-play data from 2019:

``` r
games_2019 <- readRDS(url('https://raw.githubusercontent.com/guga31bb/nflfastR-data/master/data/play_by_play_2019.rds'))
```

Here is what the new player IDs look like:

``` r
games_2019 %>%
  filter(rush == 1 | pass == 1, posteam == "SEA") %>%
  select(desc, name, id)
```

    ## # A tibble: 1,204 x 3
    ##    desc                                           name    id                    
    ##    <chr>                                          <chr>   <chr>                 
    ##  1 (11:51) (Shotgun) 32-C.Carson left tackle to ~ C.Cars~ 32013030-2d30-3033-33~
    ##  2 (11:24) 3-R.Wilson pass incomplete deep left ~ R.Wils~ 32013030-2d30-3032-39~
    ##  3 (11:19) (Shotgun) 3-R.Wilson pass short left ~ R.Wils~ 32013030-2d30-3032-39~
    ##  4 (2:48) (Shotgun) 74-G.Fant reported in as eli~ C.Cars~ 32013030-2d30-3033-33~
    ##  5 (2:16) 74-G.Fant reported in as eligible.  3-~ R.Wils~ 32013030-2d30-3032-39~
    ##  6 (1:34) (Shotgun) 32-C.Carson left tackle to S~ C.Cars~ 32013030-2d30-3033-33~
    ##  7 (:40) (Shotgun) 3-R.Wilson pass short left to~ R.Wils~ 32013030-2d30-3032-39~
    ##  8 (:10) (Shotgun) 32-C.Carson left guard to CIN~ C.Cars~ 32013030-2d30-3033-33~
    ##  9 (15:00) 3-R.Wilson sacked at CIN 41 for -9 ya~ R.Wils~ 32013030-2d30-3032-39~
    ## 10 (14:15) (Shotgun) 3-R.Wilson pass short middl~ R.Wils~ 32013030-2d30-3032-39~
    ## # ... with 1,194 more rows

But these IDs aren’t very useful. So we need to decode them using the
new function `decode_player_ids`:

``` r
games_2019 %>%
  filter(rush == 1 | pass == 1, posteam == "SEA") %>%
  nflfastR::decode_player_ids() %>%
  select(desc, name, id)
```

    ## Start decoding, please wait...

    ## Decoding completed.

    ## # A tibble: 1,204 x 3
    ##    desc                                                        name     id      
    ##    <chr>                                                       <chr>    <chr>   
    ##  1 (11:51) (Shotgun) 32-C.Carson left tackle to SEA 21 for 1 ~ C.Carson 00-0033~
    ##  2 (11:24) 3-R.Wilson pass incomplete deep left [97-G.Atkins]~ R.Wilson 00-0029~
    ##  3 (11:19) (Shotgun) 3-R.Wilson pass short left to 14-DK.Metc~ R.Wilson 00-0029~
    ##  4 (2:48) (Shotgun) 74-G.Fant reported in as eligible.  32-C.~ C.Carson 00-0033~
    ##  5 (2:16) 74-G.Fant reported in as eligible.  3-R.Wilson sack~ R.Wilson 00-0029~
    ##  6 (1:34) (Shotgun) 32-C.Carson left tackle to SEA 23 for 5 y~ C.Carson 00-0033~
    ##  7 (:40) (Shotgun) 3-R.Wilson pass short left to 32-C.Carson ~ R.Wilson 00-0029~
    ##  8 (:10) (Shotgun) 32-C.Carson left guard to CIN 32 for 3 yar~ C.Carson 00-0033~
    ##  9 (15:00) 3-R.Wilson sacked at CIN 41 for -9 yards (94-S.Hub~ R.Wilson 00-0029~
    ## 10 (14:15) (Shotgun) 3-R.Wilson pass short middle to 32-C.Car~ R.Wilson 00-0029~
    ## # ... with 1,194 more rows

So now we have the familiar GSIS IDs. Let’s apply this to the whole
dataframe:

``` r
decoded_pbp <- games_2019 %>%
  nflfastR::decode_player_ids()
```

    ## Start decoding, please wait...

    ## Decoding completed.

Now we’re ready to join to the roster data using these IDs:

``` r
joined <- decoded_pbp %>% 
  filter(!is.na(receiver_id)) %>%
  select(posteam, season, desc, receiver, receiver_id, epa) %>%
  left_join(roster, by = c('receiver_id' = 'gsis_id'))
```

Now we can do something like look at the most receiving EPA by the top 5
players at each position group:

``` r
#the real work is done, this just makes a table and has it look nice
joined %>%
  filter(position %in% c('WR', 'TE', 'RB')) %>%
  group_by(receiver_id, receiver, position) %>%
  summarize(tot_epa = sum(epa), n=n()) %>%
  arrange(-tot_epa) %>%
  ungroup() %>%
  group_by(position) %>%
  mutate(position_rank = 1:n()) %>%
  filter(position_rank <= 5) %>%
  dplyr::rename(Pos_Rank = position_rank, Player = receiver, Pos = position, Tgt = n, EPA = tot_epa) %>%
  select(Player, Pos, Pos_Rank, Tgt, EPA) %>%
  knitr::kable(digits = 0)
```

| Player      | Pos | Pos\_Rank | Tgt | EPA |
| :---------- | :-- | --------: | --: | --: |
| T.Kelce     | TE  |         1 | 179 | 100 |
| C.Godwin    | WR  |         1 | 123 |  87 |
| D.Adams     | WR  |         2 | 161 |  77 |
| T.Lockett   | WR  |         3 | 139 |  76 |
| J.Jones     | WR  |         4 | 164 |  72 |
| C.Kupp      | WR  |         5 | 145 |  71 |
| G.Kittle    | TE  |         2 | 129 |  56 |
| C.McCaffrey | RB  |         1 | 147 |  52 |
| D.Waller    | TE  |         3 | 123 |  45 |
| A.Ekeler    | RB  |         2 | 113 |  43 |
| J.Cook      | TE  |         4 |  75 |  43 |
| Z.Ertz      | TE  |         5 | 147 |  42 |
| J.White     | RB  |         3 | 105 |  27 |
| D.Cook      | RB  |         4 |  77 |  26 |
| M.Ingram    | RB  |         5 |  33 |  22 |

Not surprisingly, all 5 of the top 5 WRs in terms of EPA added come in
ahead of the top RB. Note that the number of targets won’t match
official stats because we’re including plays with penalties.
