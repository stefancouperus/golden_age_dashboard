# Run from the repository root: Rscript --vanilla tests/speaker_profiles.R
source("R/metadata_corrections.R")
source("R/speaker_profiles.R")
source("tests/baseline_data.R")
raw <- read_baseline_data()
fixed <- apply_speech_metadata_corrections(raw, load_metadata_corrections())
registry <- load_speaker_profiles()
enriched <- apply_speaker_profiles(fixed, registry)
stopifnot(length(registry$people) == 244L, nrow(enriched) == 447L)
stopifnot(length(unique(enriched$speaker_person_id)) == 244L)
stopifnot(all(enriched$speaker_profile_status == "verified"))
stopifnot(identical(enriched$speaker_source_label, fixed$speaker))
for (nm in setdiff(names(fixed), "speaker")) stopifnot(identical(enriched[[nm]], fixed[[nm]]))
stopifnot(identical(apply_speaker_profiles(enriched, registry), enriched))

# Same surname, different people: party and office dates decide the match.
expect_person <- function(source_name, party, person) {
  rows <- enriched[tolower(enriched$speaker_source_label) == tolower(source_name) & !is.na(enriched$party_ref) & enriched$party_ref == party, ]
  stopifnot(nrow(rows) > 0L, all(rows$speaker == person))
}
expect_person("Cornelissen", "nl.p.kvp", "Dien Cornelissen")
expect_person("De Graaf", "nl.p.cda", "Jan de Graaf")
expect_person("De Koning", "nl.p.bp", "Jan de Koning")
expect_person("De Koning", "nl.p.d66", "Marijn de Koning")
stopifnot(setequal(enriched$speaker[enriched$speaker_source_label == "Bakker"], c("Marcus Bakker", "Bert Bakker")))
stopifnot(setequal(enriched$speaker[grepl("Diepenhorst", enriched$speaker_source_label)], c("I.N.Th. Diepenhorst", "Isaäc Diepenhorst")))

# Member references changed between source vintages, while the person did not.
for (person in c("Martin Bosma", "Sandra Beckerman", "Tunahan Kuzu")) {
  rows <- enriched[enriched$speaker == person, ]
  stopifnot(length(unique(rows$member_ref)) == 2L, length(unique(rows$speaker_person_id)) == 1L)
}
verbeek <- enriched[enriched$speech_id == "nl.proc.sgd.d.198319840000028.6.15.1", ]
stopifnot(verbeek$speaker == "Jan Verbeek", verbeek$role == "senator")
stopifnot(verbeek$sample_scope_note == "", verbeek$speaking_capacity == "")

# Published RDS and CSV downloads carry the same names and reviewed metadata.
published <- readRDS("ge_final_45_24.rds")
csv <- read.csv("ge_final_45_24.csv", colClasses = "character", check.names = FALSE, na.strings = "NA")
stopifnot(identical(published, enriched))
for (nm in c("speech_id", "speaker", "speaker_original", "speaker_source_label",
             "speaker_person_id", "speaker_profile_url", "sample_scope_note", "role", "party_ref")) {
  expected <- ifelse(is.na(published[[nm]]), "", as.character(published[[nm]]))
  actual <- ifelse(is.na(csv[[nm]]), "", csv[[nm]])
  stopifnot(identical(expected, actual))
}
stopifnot(identical(apply_speech_metadata_corrections(published, load_metadata_corrections()), published))

# A reviewed match cannot silently follow a changed date or a new observation.
drift <- fixed
drift$date[[1]] <- as.Date("2024-01-01")
stopifnot(inherits(try(apply_speaker_profiles(drift, registry), silent = TRUE), "try-error"))
stopifnot(inherits(try(apply_speaker_profiles(fixed[-1, ], registry), silent = TRUE), "try-error"))

app_env <- new.env(parent = globalenv())
sys.source("app.R", envir = app_env)
stopifnot(!exists("fetch_wikipedia_infobox", envir = app_env, inherits = FALSE))
shiny::testServer(app_env$server, {
  # Exercise the actual profile builder for every contribution, without a
  # biography fetch or fallback. A government speaker retains their speech role.
  for (i in seq_len(nrow(app_env$df_dash))) {
    sp <- app_env$df_dash[i, ]
    prof <- build_speaker_profile(sp)
    stopifnot(prof$source == "Parlement.com", prof$match_status == "verified")
    stopifnot(prof$profile_url == sp$speaker_profile_url, prof$speaker_name == sp$speaker)
    stats <- build_speaker_dataset_profile(sp)
    stopifnot(stats$n_total == sum(app_env$df_dash$speaker_person_id == sp$speaker_person_id))
  }
  sp <- app_env$df_dash[app_env$df_dash$role == "senator", ]
  stopifnot(build_speaker_profile(sp)$role == "Member of the Eerste Kamer")
  show_speaker_modal(sp)
})
cat("PASS: all 447 contributions have verified links for 244 people; homonyms, changed member IDs, role labels and profile integration checked.\n")
