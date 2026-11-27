# Update the nflverse packages in the docker image (see docker/Dockerfile) to
# their latest GitHub commit before releasing data.
#
# The image's repos (Rprofile.site) are nflverse r-universe Linux binaries
# followed by Posit Public Package Manager binaries. r-universe builds a
# package some time after a push to GitHub. To make sure a data update
# triggered right after a push uses that push, we compare the commit an
# installed package was built from (RemoteSha in its DESCRIPTION) with GitHub
# HEAD:
#   1. installed commit == HEAD: nothing to do
#   2. otherwise install the r-universe binary (no build)
#   3. still behind HEAD, i.e. r-universe hasn't built the push yet: install
#      from GitHub. These packages are pure R, building them takes seconds.
#
# fastrmodels (17 MB, rarely changes) comes from the image, which is rebuilt
# weekly.
#
# This step never fails the job. Problems are reported as GitHub Actions
# warning annotations and the job continues with what's installed.
repos <- c(
  "nflfastR" = "nflverse/nflfastR",
  "nflreadr" = "nflverse/nflreadr",
  "nflversedata" = "nflverse/nflverse-data"
)

warn <- function(title, ...) {
  cat("::warning title=", title, "::", ..., "\n", sep = "")
}

# gh reads GITHUB_PAT
github_head <- function(repo) {
  tryCatch(
    gh::gh(paste0("/repos/", repo, "/commits/HEAD"))$sha,
    error = function(e) {
      warn("GitHub API", "Can't get HEAD of ", repo, ": ", conditionMessage(e))
      NA_character_
    }
  )
}

installed_sha <- function(pkg) {
  sha <- tryCatch(
    suppressWarnings(utils::packageDescription(pkg, fields = "RemoteSha")),
    error = function(e) NA_character_
  )
  if (is.null(sha)) NA_character_ else as.character(sha)
}

# Unknown HEAD (API error) or unknown installed commit counts as behind
behind <- function(pkgs, heads) {
  Filter(function(pkg) {
    head <- heads[[pkg]]
    sha <- installed_sha(pkg)
    is.na(head) || is.na(sha) || head != sha
  }, pkgs)
}

# install.packages() only warns on failure
install_quietly <- function(expr) {
  withCallingHandlers(expr, warning = function(w) {
    warn("Refreshing nflverse packages", conditionMessage(w))
    invokeRestart("muffleWarning")
  })
}

pkgs <- names(repos)
heads <- vapply(repos, github_head, "")
names(heads) <- pkgs

todo <- behind(pkgs, heads)
if (length(todo) > 0) {
  cli::cli_alert_info("Installing r-universe binaries of {.pkg {todo}}")
  install_quietly(install.packages(todo))
}

# Only packages with a known HEAD can be compared after the install
todo <- behind(pkgs[!is.na(heads)], heads)
if (length(todo) > 0) {
  cli::cli_alert_info("r-universe hasn't built the latest commit of {.pkg {todo}} yet. Installing from GitHub.")
  install_quietly(pak::pkg_install(unname(repos[todo]), upgrade = FALSE))
}

# install.packages() installs missing dependencies but doesn't upgrade
# outdated ones. If a new nflverse version requires a newer dependency than the
# image has, loading fails. pak resolves and upgrades what's needed.
for (pkg in pkgs) {
  ok <- tryCatch({
    loadNamespace(pkg)
    TRUE
  }, error = function(e) FALSE)
  if (!ok) {
    warn(
      "Outdated docker image", pkg, " needs newer dependencies than the ",
      "image has. Please run the Build Update Image workflow."
    )
    # GitHub refs, so pak doesn't swap a package installed from GitHub above
    # for an older r-universe binary
    install_quietly(pak::pkg_install(unname(repos), upgrade = FALSE))
    break
  }
}

for (pkg in pkgs) {
  sha <- installed_sha(pkg)
  status <- if (is.na(heads[[pkg]])) {
    "GitHub HEAD unknown"
  } else if (identical(sha, heads[[pkg]])) {
    "GitHub HEAD"
  } else {
    "NOT GitHub HEAD"
  }
  if (status == "NOT GitHub HEAD") {
    warn("Refreshing nflverse packages", pkg, " is not at GitHub HEAD ", substr(heads[[pkg]], 1, 7))
  }
  cli::cli_alert_info("{.pkg {pkg}} {packageVersion(pkg)} @ {substr(sha, 1, 7)} ({status})")
}
