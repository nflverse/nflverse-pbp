FROM rocker/r-ver:4.3.1

MAINTAINER Tan Ho <tan@tanho.ca>

RUN install2.r -e -r https://packagemanager.rstudio.com/cran/__linux__/focal/latest pak \
  && rm -rf \
        /var/lib/apt/lists/* \
        /tmp/downloaded_packages

# pak config variables to force system requirement install as needed
# see <https://pak.r-lib.org/reference/pak-config.html>
ENV PKG_SYSREQS=TRUE
ENV R_PKG_SYSREQS2=TRUE
ARG GITHUB_PAT

WORKDIR /nflverse
COPY DESCRIPTION .
RUN r -e "pak::local_install_deps('.'); pak::pak_cleanup(force = TRUE)" \
 && rm -rf /var/lib/apt/lists/*

COPY auto/update_multiple_laterals.R multiple_laterals
COPY auto/update_pbp.R pbp
COPY auto/update_pbp_participation.R participation
COPY auto/update_pbp_patch.R pbp_patch
COPY auto/update_player_stats.R ps_offense
COPY auto/update_player_stats_kicking.R ps_kicking

ENTRYPOINT ["Rscript"]
CMD ["-e","nflreadr::nflverse_sitrep()"]
