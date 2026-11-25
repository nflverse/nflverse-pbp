# Whether the release_*() functions upload the release timestamp files
# (timestamp.txt and timestamp.json).
#
# The update workflow runs many seasons in parallel jobs. Every job uploading
# the same timestamp files to the same release is wasteful and the jobs race
# each other replacing them. So the workflow sets
# NFLVERSE_UPLOAD_TIMESTAMPS=false for its matrix jobs and uploads the
# timestamps once per release in a final job. Local runs keep uploading them.
upload_timestamps <- function() {
  !identical(tolower(Sys.getenv("NFLVERSE_UPLOAD_TIMESTAMPS", "true")), "false")
}
