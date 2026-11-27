# Update the nflverse packages in the docker image (see docker/Dockerfile) to
# their latest GitHub commit before releasing data. For each package we compare
# the commit it was built from (RemoteSha in its DESCRIPTION) with GitHub HEAD:
#   1. installed commit == HEAD: nothing to do
#   2. otherwise install the r-universe binary (no build)
#   3. still behind HEAD, i.e. r-universe hasn't built the push yet: install
#      from GitHub. These packages are pure R, building them takes seconds.
#
# fastrmodels (17 MB, rarely changes) comes from the image.
#
# This step never fails the job. Problems are reported as GitHub Actions
# warning annotations and the job continues with what's installed.
repos <- c(
  nflfastR = "nflverse/nflfastR",
  nflreadr = "nflverse/nflreadr",
  nflversedata = "nflverse/nflverse-data"
)
pkgs <- names(repos)

# Workflow commands end at a newline, so %, \r and \n must be escaped
warn <- function(title, ...) {
  msg <- cli::ansi_strip(paste0(...))
  msg <- gsub("%", "%25", msg, fixed = TRUE)
  msg <- gsub("\r", "%0D", msg, fixed = TRUE)
  msg <- gsub("\n", "%0A", msg, fixed = TRUE)
  cat("::warning title=", title, "::", msg, "\n", sep = "")
}

# Reports warnings (install.packages()) and errors (pak) as annotations
# instead of failing the job
annotate_failures <- function(expr) {
  tryCatch(
    withCallingHandlers(expr, warning = function(w) {
      warn("Refreshing nflverse packages", conditionMessage(w))
      invokeRestart("muffleWarning")
    }),
    error = function(e) warn("Refreshing nflverse packages", conditionMessage(e))
  )
  invisible()
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

# NA if the package or its RemoteSha field is missing
installed_sha <- function(pkg) {
  as.character(suppressWarnings(utils::packageDescription(pkg, fields = "RemoteSha")))
}

# Unknown HEAD (API error) or unknown installed commit counts as behind
behind <- function(pkgs, heads) {
  shas <- vapply(pkgs, installed_sha, character(1))
  pkgs[is.na(heads[pkgs]) | is.na(shas) | heads[pkgs] != shas]
}

# Loads pkg in a fresh R process. In this session a failed load leaves its
# outdated dependencies loaded, so a check after the repair below would fail
# again, and pak would install over loaded namespaces. NA if pkg loads,
# otherwise the error output.
load_error <- function(pkg) {
  out <- suppressWarnings(system2(
    file.path(R.home("bin"), "Rscript"),
    c("-e", shQuote(sprintf("loadNamespace('%s')", pkg))),
    stdout = TRUE,
    stderr = TRUE
  ))
  if (is.null(attr(out, "status"))) NA_character_ else paste(out, collapse = "\n")
}

load_errors <- function(pkgs) {
  errors <- vapply(pkgs, load_error, character(1))
  errors[!is.na(errors)]
}

# vapply keeps the package names of repos
heads <- vapply(repos, github_head, character(1))

todo <- behind(pkgs, heads)
if (length(todo) > 0) {
  cli::cli_alert_info("Installing r-universe binaries of {.pkg {todo}}")
  annotate_failures(install.packages(todo))
}

# Only packages with a known HEAD can be compared after the install
todo <- behind(pkgs[!is.na(heads)], heads)
if (length(todo) > 0) {
  cli::cli_alert_info("r-universe hasn't built the latest commit of {.pkg {todo}} yet. Installing from GitHub.")
  annotate_failures(pak::pkg_install(unname(repos[todo]), upgrade = FALSE))
}

# install.packages() installs missing dependencies but doesn't upgrade
# outdated ones. If a new nflverse version requires a newer dependency than the
# image has, loading fails. pak resolves and upgrades what's needed.
errors <- load_errors(pkgs)
if (length(errors) > 0) {
  for (pkg in names(errors)) {
    warn(
      "Outdated docker image", pkg, " can't be loaded, probably because it ",
      "needs newer dependencies than the image has. Please run the Build ",
      "Update Image workflow.\n", errors[[pkg]]
    )
  }
  # GitHub refs, so pak doesn't swap a package installed from GitHub above
  # for an older r-universe binary
  annotate_failures(pak::pkg_install(unname(repos), upgrade = FALSE))
  errors <- load_errors(names(errors))
  for (pkg in names(errors)) {
    warn("Refreshing nflverse packages", pkg, " still can't be loaded:\n", errors[[pkg]])
  }
}

for (pkg in pkgs) {
  sha <- installed_sha(pkg)
  head <- heads[[pkg]]
  if (is.na(head)) {
    status <- "GitHub HEAD unknown"
  } else if (identical(sha, head)) {
    status <- "GitHub HEAD"
  } else {
    status <- "NOT GitHub HEAD"
    warn("Refreshing nflverse packages", pkg, " is not at GitHub HEAD ", substr(head, 1, 7))
  }
  cli::cli_alert_info("{.pkg {pkg}} {packageVersion(pkg)} @ {substr(sha, 1, 7)} ({status})")
}
