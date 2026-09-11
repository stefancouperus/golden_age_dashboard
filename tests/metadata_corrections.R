# Run from the repository root: Rscript tests/metadata_corrections.R
source("R/metadata_corrections.R")
ledger <- load_metadata_corrections()
raw <- readRDS("ge_final_45_24.rds")
bio_raw <- readRDS("df_final_speaker_bio_map.rds")
fixed <- apply_speech_metadata_corrections(raw, ledger)
bio <- apply_biography_metadata_corrections(bio_raw, ledger)

stopifnot(nrow(fixed) == 447L, identical(fixed$speech_id, raw$speech_id))
editable <- c("speaker", "role", "party_ref", "member_ref", "function.")
for (nm in setdiff(names(raw), editable)) stopifnot(identical(fixed[[nm]], raw[[nm]]))
reviewed <- vapply(ledger$corrections, function(x) x$speech_id, character(1))
stopifnot(length(reviewed) == 11L)
for (nm in editable) {
  keep <- !raw$speech_id %in% reviewed
  stopifnot(identical(fixed[[nm]][keep], raw[[nm]][keep]))
}
row_for <- function(sid) fixed[match(sid, fixed$speech_id), , drop = FALSE]
stopifnot(
  row_for("nl.proc.sgd.d.195019510000563.7.2")$speaker == "Welter",
  row_for("nl.proc.sgd.d.195919600002136.2.21")$party_ref == "nl.p.pvda",
  row_for("nl.proc.sgd.d.196419650000782.5.6")$role == "government",
  row_for("nl.proc.sgd.d.196819690000711.6.2")$role == "government",
  row_for("nl.proc.ob.d.h-tk-20112012-52-9.1.12.1")$role == "mep",
  row_for("nl.proc.ob.d.h-tk-20172018-93-4.1.71.1")$role == "mp",
  row_for("nl.proc.ob.d.h-tk-20002001-338-357.1.9.1")$parliamentary_group_as_recorded == "RPF/GPV",
  grepl("committee", row_for("nl.proc.ob.d.h-tk-19961997-637-661.1.6.18")$speaking_capacity)
)
stopifnot(
  sum(fixed$role == "government") == 70L,
  sum(fixed$role == "mp") == 375L,
  sum(fixed$role == "mep") == 1L,
  sum(fixed$role == "senator") == 1L,
  sum(is.na(fixed$party_ref) & fixed$role != "government") == 0L
)

# Missing affiliation cannot manufacture a government role or label.
stopifnot(identical(
  dashboard_party_label(c(NA, "", "unknown", NA, "nl.p.pvda"), c("mp", "mep", "unknown", "government", "mp")),
  c("unknown", "unknown", "unknown", "government", "pvda")
))
labels <- dashboard_party_label(fixed$party_ref, fixed$role)
stopifnot(sum(labels == "government") == 69L)

# The patch is repeatable and refuses unreviewed changes in the source record.
stopifnot(identical(apply_speech_metadata_corrections(fixed, ledger), fixed))
changed <- raw
changed$speaker[match(reviewed[[1]], changed$speech_id)] <- "An unexpected speaker"
stopifnot(inherits(try(apply_speech_metadata_corrections(changed, ledger), silent = TRUE), "try-error"))
missing <- raw[-match(reviewed[[1]], raw$speech_id), ]
stopifnot(inherits(try(apply_speech_metadata_corrections(missing, ledger), silent = TRUE), "try-error"))

# Verified replacements clear the other person's biography, including dates.
wrong_ids <- c(
  "nl.proc.sgd.d.196419650000782.5.6",
  "nl.proc.sgd.d.196819690000711.6.2",
  "nl.proc.ob.d.h-tk-20112012-52-9.1.12.1"
)
idx <- match(wrong_ids, bio$speech_id)
stopifnot(
  identical(bio$speaker_bio_name[idx], c("Ynso Scholten", "Carel Polak", "Gerben-Jan Gerbrandy")),
  all(bio$speaker_bio_status[idx] == "verified"),
  all(is.na(bio$speaker_bio_birth[idx])),
  all(is.na(bio$speaker_bio_death[idx]))
)
stopifnot(identical(apply_biography_metadata_corrections(bio, ledger), bio))
same_person <- match(c(
  "nl.proc.ob.d.h-tk-19961997-637-661.1.6.18",
  "nl.proc.ob.d.h-tk-20002001-338-357.1.9.1"
), bio$speech_id)
stopifnot(identical(bio$speaker_bio_birth[same_person], bio_raw$speaker_bio_birth[same_person]))
unreviewed_bios <- !bio_raw$speech_id %in% reviewed
stopifnot(identical(bio[unreviewed_bios, ], bio_raw[unreviewed_bios, ]))

# Load the real app: exercise its actual preparation and profile UI integration.
app_env <- new.env(parent = globalenv())
sys.source("app.R", envir = app_env)
stopifnot(
  nrow(app_env$df_dash) == 447L,
  sum(app_env$df_dash$party_clean == "government") == 69L,
  sum(app_env$df_dash$role == "mep") == 1L,
  all(app_env$df_dash$source_file[match(reviewed, app_env$df_dash$speech_id)] == fixed$source_url_verified[match(reviewed, fixed$speech_id)])
)
# Source checking should never trigger a network biography fallback for repaired IDs.
app_env$fetch_wikipedia_infobox <- function(...) stop("Unexpected biography network fallback")
shiny::testServer(app_env$server, {
  profile_rows <- app_env$df_dash[match(wrong_ids, app_env$df_dash$speech_id), ]
  for (i in seq_len(nrow(profile_rows))) {
    p <- build_speaker_profile(profile_rows[i, ])
    stopifnot(p$source == "Parlement.com", p$match_status == "verified")
  }
})
cat("PASS: eleven sourced metadata corrections; 447 texts and code assignments preserved; roles, party labels, biographies and app integration verified.\n")
