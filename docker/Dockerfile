# Runtime image for .github/workflows/update_data.yaml
# R + gh cli + all R dependencies of this repo preinstalled, so update jobs
# don't spend a minute or more installing R and packages.
# Built and pushed to ghcr by .github/workflows/build_image.yaml

# rocker/r-ver:latest = latest R release on Ubuntu LTS, with CRAN set to
# Posit Public Package Manager binaries
FROM rocker/r-ver:latest

# gh cli is used by nflversedata to upload release assets
RUN apt-get update \
  && apt-get install -y --no-install-recommends ca-certificates curl gpg \
  && curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg \
     -o /usr/share/keyrings/githubcli-archive-keyring.gpg \
  && echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" \
     > /etc/apt/sources.list.d/github-cli.list \
  && apt-get update \
  && apt-get install -y --no-install-recommends gh \
  && rm -rf /var/lib/apt/lists/*

RUN Rscript -e 'install.packages("pak", repos = sprintf("https://r-lib.github.io/p/pak/stable/%s/%s/%s", .Platform$pkgType, R.Version()$os, R.Version()$arch))'

# nflverse packages come as Linux binaries from r-universe. The plain
# https://nflverse.r-universe.dev repo serves source packages on Linux (pak
# would e.g. compile gsisdecoder), the binaries live under
# /bin/linux/<ubuntu codename>-<arch>/<R minor version>/. rocker sets the CRAN
# repo (Posit Public Package Manager binaries) in Rprofile.site, we put
# r-universe in front of it. The refresh step in update_data.yaml uses the same
# repos.
RUN . /etc/os-release && export VERSION_CODENAME \
  && RUNIVERSE=$(Rscript -e 'cat(sprintf("https://nflverse.r-universe.dev/bin/linux/%s-%s/%s.%s", Sys.getenv("VERSION_CODENAME"), R.version$arch, R.version$major, sub("[.].*", "", R.version$minor)))') \
  && echo "options(repos = c(nflverse = '$RUNIVERSE', getOption('repos')))" \
     >> "$(R RHOME)/etc/Rprofile.site" \
  && Rscript -e 'print(getOption("repos"))'

# pak (not install.packages) because it also installs the system libraries
# the binaries need. Only DESCRIPTION is copied so code changes don't
# invalidate this layer.
# pak replaces RemoteSha (the GitHub commit r-universe built a package from)
# with the version number. exec/refresh_nflverse.R compares RemoteSha with
# GitHub HEAD, so we reinstall the nflverse packages it refreshes with
# install.packages(), which keeps r-universe's DESCRIPTION as is.
COPY DESCRIPTION /tmp/build/DESCRIPTION
RUN Rscript -e ' \
    pak::pkg_install(c("nflfastR", "nflreadr", "nflversedata", "fastrmodels")); \
    pak::local_install_deps("/tmp/build"); \
    pak::cache_clean(); \
    install.packages(c("nflfastR", "nflreadr", "nflversedata")); \
  ' \
  && rm -rf /tmp/build /tmp/Rtmp* /var/lib/apt/lists/*

# Smoke test: fail the build if anything the update scripts need is missing
RUN gh --version \
  && Rscript -e ' \
    pkgs <- c("nflfastR", "nflreadr", "nflversedata", "fastrmodels", \
              "gsisdecoder", "cli", "glue", "future", "dplyr", "data.table", \
              "arrow", "gh", "pak"); \
    for (p in pkgs) { \
      loadNamespace(p); \
      cat(p, format(packageVersion(p)), packageDescription(p)$RemoteSha, "\n") \
    }; \
    for (p in c("nflfastR", "nflreadr", "nflversedata")) { \
      sha <- packageDescription(p, fields = "RemoteSha"); \
      if (!grepl("^[0-9a-f]{40}$", sha)) { \
        stop(p, " has RemoteSha ", sha, " instead of a commit. ", \
             "Did the install.packages() reinstall fail?") \
      } \
    } \
  '

CMD ["R"]
