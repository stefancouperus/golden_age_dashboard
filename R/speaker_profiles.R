# Curated biography links, shared by Shiny and the future static export.
# Apply the metadata correction ledger before attaching these identities.
load_speaker_profiles <- function(path = "data/speaker_profiles.json") {
  registry <- jsonlite::fromJSON(path, simplifyVector = FALSE)
  if (!identical(registry$schema_version, 1L)) stop("Unsupported speaker profile schema.")
  people <- registry$people
  speeches <- registry$speeches
  values <- function(rows, key) vapply(rows, function(x) x[[key]], character(1))
  unique_keys <- function(x) length(x) > 0L && !anyNA(x) && all(nzchar(x)) && !anyDuplicated(x)
  ids <- values(people, "person_id")
  if (!unique_keys(ids) || !unique_keys(values(speeches, "speech_id"))) {
    stop("Speaker profiles require unique, non-empty person and speech IDs.")
  }
  if (!unique_keys(values(people, "display_name")) || !unique_keys(values(people, "profile_url"))) {
    stop("Speaker names and biography links must distinguish each reviewed person.")
  }
  if (!setequal(values(speeches, "person_id"), ids)) stop("Incomplete speaker profile references.")
  if (any(!grepl("^https://www[.]parlement[.]com/biografie/[a-z0-9-]+$", values(people, "profile_url")))) {
    stop("Speaker profiles require direct Parlement.com biography URLs.")
  }
  if (any(values(people, "status") != "verified")) stop("Unreviewed speaker profile.")
  registry
}

apply_speaker_profiles <- function(df, registry) {
  speech_ids <- vapply(registry$speeches, function(x) x$speech_id, character(1))
  if (anyDuplicated(df$speech_id) || !setequal(df$speech_id, speech_ids)) {
    stop("The speaker registry must cover the complete dataset exactly once.")
  }
  assignments <- registry$speeches[match(df$speech_id, speech_ids)]
  source_names <- if ("speaker_source_label" %in% names(df)) df$speaker_source_label else df$speaker
  for (i in seq_len(nrow(df))) {
    expected <- assignments[[i]]$expected
    for (nm in names(expected)) {
      if (!nm %in% names(df)) stop("Missing reviewed speaker field: ", nm)
      actual <- if (nm == "speaker") source_names[[i]] else df[[nm]][i]
      if (!metadata_value_equal(actual, expected[[nm]])) {
        stop("Speaker metadata differs from the reviewed record: ", df$speech_id[[i]], " / ", nm)
      }
    }
  }
  person_ids <- vapply(registry$people, function(x) x$person_id, character(1))
  selected_ids <- vapply(assignments, function(x) x$person_id, character(1))
  people <- registry$people[match(selected_ids, person_ids)]
  field <- function(key) vapply(people, function(x) x[[key]], character(1))
  df$speaker_source_label <- source_names
  df$speaker_person_id <- selected_ids
  df$speaker <- field("display_name")
  df$speaker_profile_url <- field("profile_url")
  df$speaker_profile_source <- field("source")
  df$speaker_profile_status <- field("status")
  df
}

speaker_role_label <- function(role) {
  switch(role,
    government = "Government speaker",
    mp = "Member of the Tweede Kamer",
    senator = "Member of the Eerste Kamer",
    mep = "Member of the European Parliament",
    "Role not recorded"
  )
}
