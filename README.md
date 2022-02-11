# nflfastR-data

This repository stores code and workflows for updating nflverse play by play, player stats, and kicking stat summaries. The data itself is now being automatically pushed to GitHub releases at https://github.com/nflverse/nflverse-data/releases, which reduces repository bloat. For more information on this change, please see: {blogpost TBD}

We recommend using the `nflreadr` R package to access the latest data: https://nflreadr.nflverse.com, or `nfl-data-py`: https://pypi.org/project/nfl-data-py/. If you must read directly from URLs, linking to nflverse-data release URLs is now the best way to do so. 

Data here will eventually be archived away from this repository (by August 2022) and we encourage everyone to shift to nflverse-data URLs for all future projects. 

nflreadr v1.2.0+ will correctly reference files for these changes.
