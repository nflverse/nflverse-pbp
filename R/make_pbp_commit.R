message <- sprintf("Updated %s (ET) using nflfastR version %s", lubridate::now("America/New_York"), utils::packageVersion("nflfastR"))

git <- function(..., echo_cmd = TRUE, echo = TRUE, error_on_status = TRUE) {
  callr::run("git", c(...),
             echo_cmd = echo_cmd, echo = echo,
             error_on_status = error_on_status
  )
}

git("commit", "-am", message)