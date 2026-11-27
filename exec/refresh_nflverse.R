# Update the nflverse packages in the docker image (see docker/Dockerfile)
# before releasing data.
#
# The image's repos (Rprofile.site) are nflverse r-universe Linux binaries
# followed by Posit Public Package Manager binaries, so this installs binaries
# only, nothing is built.
#
# The r-universe metadata doesn't say which commit a binary was built from and
# dev versions often don't change between commits. So we reinstall
# unconditionally, it's only a few MB. fastrmodels (17 MB, rarely changes)
# comes from the image, which is rebuilt weekly.
pkgs <- c("nflfastR", "nflreadr", "nflversedata")

# install.packages() only warns on failure. Don't fail the job (the image's
# versions still work), but make it visible in the workflow summary.
withCallingHandlers(
  install.packages(pkgs),
  warning = function(w) {
    cat("::warning title=Refreshing nflverse packages::", conditionMessage(w), "\n", sep = "")
    invokeRestart("muffleWarning")
  }
)

# install.packages() installs missing dependencies but doesn't upgrade
# outdated ones. If a new nflverse version requires a newer dependency than the
# image has, loading fails. pak resolves and upgrades what's needed (binaries
# from the same repos).
for (pkg in pkgs) {
  ok <- tryCatch({
    loadNamespace(pkg)
    TRUE
  }, error = function(e) FALSE)
  if (!ok) {
    cat("::warning title=Outdated docker image::", pkg, " needs newer ",
        "dependencies than the image has. Please run the Build Update Image ",
        "workflow.\n", sep = "")
    pak::pkg_install(pkgs, upgrade = FALSE)
    break
  }
}

for (pkg in pkgs) {
  cli::cli_alert_info("{.pkg {pkg}} {packageVersion(pkg)}")
}
