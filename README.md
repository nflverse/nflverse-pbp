# nflverse pbp data

[![Update PBP Related Data](https://github.com/nflverse/nflverse-pbp/actions/workflows/update_data.yaml/badge.svg)](https://github.com/nflverse/nflverse-pbp/actions/workflows/update_data.yaml)

This repository stores code and workflows for updating nflverse play by play, player stats, and kicking stat summaries. The data itself is now being automatically pushed to GitHub releases at https://github.com/nflverse/nflverse-data/releases, which reduces repository bloat. 


For more on why we use releases, see [Tan's talk  at rstudio::conf(2022).](https://github.com/tanho63/project_immortality)

We recommend using the [`nflreadr` R package](https://nflreadr.nflverse.com) to access the latest data or [`nfl-data-py` for Python](https://pypi.org/project/nfl-data-py/). If you would like to read directly from URLs, linking to nflverse-data release URLs is now the best way to do so. 

Data here will eventually be archived away from this repository (by August 2022) and we encourage everyone to shift to nflverse-data URLs for all projects. 

nflreadr v1.2.0+ will correctly reference files for these changes.
