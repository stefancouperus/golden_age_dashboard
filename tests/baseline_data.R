# The pre-publication RDS remains in Git history. Tests compare every research
# field against it instead of treating the corrected download as raw input.
read_baseline_data <- function() {
  path <- tempfile(fileext = ".rds")
  on.exit(unlink(path))
  status <- system2("git", c("show", "a619446:ge_final_45_24.rds"), stdout = path)
  if (status != 0L) stop("These preservation checks require repository Git history.")
  readRDS(path)
}
