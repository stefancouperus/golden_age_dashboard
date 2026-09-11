# Export the updated research dataset directly. No correction overlay or
# biography matching is applied here. Translations join strictly by speech ID.
args <- commandArgs(trailingOnly = TRUE)
input <- if (length(args)) args[[1]] else "data/research/ge_final_45_24.csv"
if (!requireNamespace("jsonlite", quietly = TRUE)) stop("Install jsonlite to export the website data.")
read_csv <- function(path) read.csv(path, colClasses = "character", check.names = FALSE, na.strings = c("NA"), stringsAsFactors = FALSE)
df <- read_csv(input)
translations <- read_csv("df_snippets_translated.csv")
source_manifest <- jsonlite::fromJSON("data/research/source.json", simplifyVector = FALSE)
clean <- function(x) ifelse(is.na(x), "", x)
required <- c("speech_id", "speaker", "speaker_person_id", "speaker_profile_url", "speaker_original", "speaker_source_label", "sample_scope_note", "role", "party_ref", "text", "date", "temporal_grammar_code", "symbolic_work_code", "speaking_capacity", "government_position_nl", "government_position_start", "government_position_end", "government_metadata_source")
stopifnot(all(required %in% names(df)), nrow(df) == 447L, !anyDuplicated(df$speech_id), !anyDuplicated(translations$speech_id))
stopifnot(length(unique(df$speaker_person_id)) == 244L, all(nzchar(df$speaker_person_id)), all(grepl("^https://www[.]parlement[.]com/biografie/", df$speaker_profile_url)))
stopifnot(all(df$include_for_coding == "TRUE"), all(df$temporal_grammar_code %in% paste0("TG", 1:4)), all(df$symbolic_work_code %in% paste0("SW", 1:5)))
stopifnot(all(df$date >= "1945-01-01" & df$date <= "2024-12-31"))
government <- df$role == "government"
stopifnot(sum(government) == 70L, all(nzchar(clean(df$party_ref))), all(nzchar(clean(df$speaking_capacity[government]))), all(nzchar(clean(df$government_position_nl[government]))))
stopifnot(all(df$government_position_start[government] <= df$date[government]), all(df$date[government] < df$government_position_end[government]), all(df$government_metadata_source[government] == df$speaker_profile_url[government]))
translation_index <- match(df$speech_id, translations$speech_id)
stopifnot(!anyNA(translation_index))
translations <- translations[translation_index, ]

party_labels <- c(
  arp="ARP", bp="Boerenpartij", bbb="BBB", cda="CDA", cd="Centrumdemocraten", chu="CHU", christenunie="ChristenUnie", cpn="CPN", d66="D66", denk="DENK", ds70="DS’70", fvd="FVD", gpv="GPV", groenlinks="GroenLinks", ja21="JA21", knp="KNP", kvp="KVP", lpf="LPF", ppr="PPR", psp="PSP", pvda="PvdA", pvdd="Partij voor de Dieren", pvv="PVV", rpf="RPF", sgp="SGP", sp="SP", vvd="VVD",
  "groep bontes/van klaveren"="Groep Bontes/Van Klaveren", "groep van haga"="Groep Van Haga", groepvanoudenallen="Groep Van Oudenallen", "lid gündoğan"="Lid Gündoğan", unknown="No affiliation recorded"
)
party_key <- sub("^nl[.]p[.]", "", clean(df$party_ref))
party_key[!nzchar(party_key)] <- "unknown"
party_key[party_key == "gl"] <- "groenlinks"
stopifnot(all(party_key %in% names(party_labels)))

source_link <- function(sid, source) {
  source <- clean(source)
  if (grepl("^https://zoek[.]officielebekendmakingen[.]nl/", source)) return(sub("[.]xml$", ".html", source))
  if (grepl("^https?://", source)) return(source)
  if (grepl("^nl[.]proc[.]ob[.]d[.]h-tk-", sid)) {
    doc <- strsplit(sub("^nl[.]proc[.]ob[.]d[.]", "", sid), ".", fixed = TRUE)[[1]][[1]]
    return(paste0("https://zoek.officielebekendmakingen.nl/", doc, ".html"))
  }
  if (grepl("^nl[.]proc[.]sgd[.]d[.]", sid)) {
    doc <- strsplit(sub("^nl[.]proc[.]sgd[.]d[.]", "", sid), ".", fixed = TRUE)[[1]][[1]]
    if (nchar(doc) %in% c(11L, 15L) && grepl("^[0-9]+$", doc)) {
      split <- nchar(doc) - 7L
      return(paste0("https://resolver.kb.nl/resolve?urn=sgd:mpeg21:", substr(doc, 1L, split), ":", substr(doc, split + 1L, nchar(doc)), ":pdf"))
    }
  }
  stop("Unresolved source document: ", sid)
}
split_evidence <- function(x) trimws(strsplit(clean(x), " || ", fixed = TRUE)[[1]])
evidence <- function(i, dimension) {
  nl <- split_evidence(translations[[paste0(dimension, "_sentences")]][[i]])
  en <- split_evidence(translations[[paste0(dimension, "_sentences_en")]][[i]])
  if (!length(nl) || length(nl) != length(en) || any(!nzchar(nl)) || any(!nzchar(en))) stop("Unpaired evidence: ", df$speech_id[[i]], "/", dimension)
  lapply(seq_along(nl), function(j) list(id = paste0(ifelse(dimension == "temporal_grammar", "tg", "sw"), "-", j), nl = nl[[j]], en = en[[j]]))
}
speeches <- lapply(seq_len(nrow(df)), function(i) list(
  id = df$speech_id[[i]], date = df$date[[i]], year = as.integer(substr(df$date[[i]], 1L, 4L)),
  speaker = df$speaker[[i]], speakerId = df$speaker_person_id[[i]], biography = df$speaker_profile_url[[i]],
  originalSpeaker = df$speaker_original[[i]], sourceSpeaker = df$speaker_source_label[[i]],
  party = party_key[[i]], partyLabel = unname(party_labels[party_key[[i]]]), partyRef = clean(df$party_ref[[i]]),
  role = df$role[[i]], capacity = clean(df$speaking_capacity[[i]]), group = clean(df$parliamentary_group_as_recorded[[i]]),
  governmentPosition = clean(df$government_position_nl[[i]]), governmentPositionStart = clean(df$government_position_start[[i]]), governmentPositionEnd = clean(df$government_position_end[[i]]), governmentMetadataSource = clean(df$government_metadata_source[[i]]),
  scopeNote = clean(df$sample_scope_note[[i]]), source = source_link(df$speech_id[[i]], df$source_file[[i]]),
  text = df$text[[i]], tg = df$temporal_grammar_code[[i]], sw = df$symbolic_work_code[[i]],
  tgRationale = clean(df$temporal_grammar_rationale[[i]]), swRationale = clean(df$symbolic_work_rationale[[i]]),
  inclusionRationale = clean(df$inclusion_rationale[[i]]), notes = clean(df$notes[[i]]),
  evidence = list(tg = evidence(i, "temporal_grammar"), sw = evidence(i, "symbolic_work"))
))
payload <- list(schemaVersion = 1L, source = source_manifest, period = c(1945L, 2024L), speeches = speeches)
dir.create("public/data", recursive = TRUE, showWarnings = FALSE)
jsonlite::write_json(payload, "public/data/corpus.json", auto_unbox = TRUE, pretty = FALSE, na = "null")
# Remove the retired CSV download if an older export left it behind.
if (file.exists("public/data/research.csv")) unlink("public/data/research.csv")
cat("Exported", length(speeches), "speeches and paired evidence for", length(unique(df$speaker_person_id)), "people from the updated research CSV.\n")
cat("Corpus JSON:", round(file.info("public/data/corpus.json")$size / 1e6, 2), "MB.\n")
