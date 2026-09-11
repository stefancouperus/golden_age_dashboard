# Explicit, sourced metadata repairs; also validate already corrected datasets.
load_metadata_corrections <- function(path = "data/metadata_corrections.json") {
  if (!file.exists(path)) stop("Missing metadata correction ledger: ", path)
  ledger <- jsonlite::fromJSON(path, simplifyVector = FALSE)
  if (!identical(ledger$schema_version, 1L)) stop("Unsupported metadata correction schema.")
  ids <- vapply(ledger$corrections, function(x) x$speech_id, character(1))
  if (anyNA(ids) || any(!nzchar(ids)) || anyDuplicated(ids)) {
    stop("Metadata corrections must have unique, non-empty speech IDs.")
  }
  ledger
}

metadata_value_equal <- function(actual, expected) {
  if (is.null(expected) || (length(expected) == 1L && is.na(expected))) {
    return(length(actual) == 1L && (is.na(actual) || !nzchar(trimws(as.character(actual)))))
  }
  length(actual) == 1L && !is.na(actual) &&
    identical(trimws(as.character(actual)), trimws(as.character(expected)))
}

apply_speech_metadata_corrections <- function(df, ledger, strict = TRUE) {
  if (!"speech_id" %in% names(df) || anyDuplicated(df$speech_id)) {
    stop("Speech metadata repairs require unique speech IDs.")
  }
  # Keep source values alongside corrected values for downstream exports.
  for (nm in intersect(c("speaker", "role", "party_ref", "member_ref", "function."), names(df))) {
    original_nm <- paste0(sub("[.]$", "", nm), "_original")
    if (!original_nm %in% names(df)) df[[original_nm]] <- df[[nm]]
  }
  for (nm in c("speaking_capacity", "parliamentary_group_as_recorded", "sample_scope_note", "source_url_verified", "metadata_correction_note")) {
    if (!nm %in% names(df)) df[[nm]] <- rep("", nrow(df))
  }
  for (entry in ledger$corrections) {
    idx <- match(entry$speech_id, as.character(df$speech_id))
    if (is.na(idx)) {
      if (strict) stop("Correction target absent: ", entry$speech_id)
      next
    }
    # Permit an already-applied correction, but reject unexpected source drift.
    for (nm in names(entry$expected)) {
      if (!nm %in% names(df)) {
        if (strict) stop("Expected metadata column absent: ", nm)
        next
      }
      # Published datasets use reviewed full names. Their intermediate source
      # label remains the target of the earlier OCR/attribution corrections.
      field <- if (nm == "speaker" && "speaker_source_label" %in% names(df)) "speaker_source_label" else nm
      valid <- metadata_value_equal(df[[field]][idx], entry$expected[[nm]])
      if (nm %in% names(entry$updates)) {
        valid <- valid || metadata_value_equal(df[[field]][idx], entry$updates[[nm]])
      }
      if (!valid) stop("Metadata differs from reviewed record: ", entry$speech_id, " / ", nm)
    }
    for (nm in names(entry$updates)) {
      if (!nm %in% names(df)) df[[nm]] <- rep(NA_character_, nrow(df))
      field <- if (nm == "speaker" && "speaker_source_label" %in% names(df)) "speaker_source_label" else nm
      df[[field]][idx] <- if (is.null(entry$updates[[nm]])) NA_character_ else entry$updates[[nm]]
    }
    df$source_url_verified[idx] <- entry$source_url
    df$metadata_correction_note[idx] <- entry$reason
  }
  df
}

apply_biography_metadata_corrections <- function(df, ledger) {
  if (!"speech_id" %in% names(df)) return(df)
  if (anyDuplicated(df$speech_id)) stop("Biography repairs require unique speech IDs.")
  for (entry in ledger$corrections) {
    if (is.null(entry$biography)) next
    idx <- match(entry$speech_id, as.character(df$speech_id))
    if (is.na(idx)) next
    bio <- entry$biography
    same_identity <- "speaker_bio_name" %in% names(df) &&
      metadata_value_equal(df$speaker_bio_name[idx], bio$name)
    # A wrong identity must not retain that other person's dates or offices.
    # Preserve existing details when the review confirms the same person.
    if (!same_identity) {
      for (nm in names(df)[startsWith(names(df), "speaker_bio_")]) {
        df[[nm]][idx] <- if (inherits(df[[nm]], "Date")) as.Date(NA) else ""
      }
    }
    replacement <- list(
      speaker_bio_name = bio$name,
      speaker_bio_url = bio$url,
      speaker_bio_source = "Source-verified metadata correction",
      speaker_bio_status = "verified",
      speaker_bio_parties = bio$parties
    )
    for (nm in names(replacement)) {
      if (!nm %in% names(df)) df[[nm]] <- rep("", nrow(df))
      df[[nm]][idx] <- replacement[[nm]]
    }
  }
  df
}

dashboard_party_label <- function(party_ref, role) {
  party <- trimws(sub("^nl\\.p\\.", "", ifelse(is.na(party_ref), "", as.character(party_ref))))
  missing <- tolower(party) %in% c("", "na", "n/a", "none", "unknown")
  role <- tolower(trimws(ifelse(is.na(role), "", as.character(role))))
  party[missing] <- ifelse(role[missing] == "government", "government", "unknown")
  party
}
