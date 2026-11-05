# run_all.R
# Owner: Sultan
# Runs every numbered script in R/ in order (00_, 01_, 02_, ...), prints how
# long each one took, and stops at the first error.
# Each script runs in its own environment, so it cannot rely on variables left
# behind by an earlier script. It has to read what it needs from data/processed/.
#
# Run from the project root (open C421_Project.Rproj first):
#   source("R/run_all.R")
#
# To skip a script, for example the download when data/raw/ is already filled:
#   skip_scripts <- "01_download_data.R"
#   source("R/run_all.R")

if (!file.exists("R/00_setup.R")) {
  stop("Run this from the project root. Open C421_Project.Rproj in RStudio first.")
}

if (!exists("skip_scripts")) skip_scripts <- character()

script_files <- list.files("R", pattern = "^[0-9]{2}_.*\\.R$")
script_files <- setdiff(script_files, skip_scripts)

timings <- data.frame(script = character(), seconds = numeric())

for (f in script_files) {
  message("---- Running ", f, " ----")
  start <- Sys.time()
  ok <- tryCatch({
    sys.source(file.path("R", f), envir = new.env())
    TRUE
  }, error = function(e) {
    message("STOPPED at ", f, ": ", conditionMessage(e))
    FALSE
  })
  if (!ok) stop("run_all stopped at ", f, ". Fix that script and run again.", call. = FALSE)
  seconds <- round(as.numeric(difftime(Sys.time(), start, units = "secs")), 1)
  timings <- rbind(timings, data.frame(script = f, seconds = seconds))
  message(f, " finished in ", seconds, " seconds")
}

message("---- All done ----")
print(timings, row.names = FALSE)
