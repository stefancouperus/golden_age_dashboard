suppressPackageStartupMessages({
  library(shiny)
  library(bslib)
  library(ggplot2)
  library(dplyr)
  library(stringr)
  library(DT)
  library(htmltools)
})

source("R/metadata_corrections.R", local = TRUE)
source("R/speaker_profiles.R", local = TRUE)
metadata_corrections <- load_metadata_corrections()

if (!"localdocs" %in% names(shiny::resourcePaths())) {
  shiny::addResourcePath("localdocs", normalizePath(getwd(), winslash = "/", mustWork = TRUE))
}

detect_draft_pdf <- function() {
  pdfs <- list.files(getwd(), pattern = "(?i)\\.pdf$", full.names = FALSE)
  if (!length(pdfs)) return(NULL)
  preferred_names <- c("draftpaper.pdf", "draft_paper.pdf")
  preferred <- pdfs[tolower(pdfs) %in% preferred_names]
  if (length(preferred)) return(preferred[[1]])
  idx <- unique(c(
    grep("(?i)draft", pdfs, perl = TRUE),
    grep("(?i)golden.?\\s*age", pdfs, perl = TRUE),
    seq_along(pdfs)
  ))
  pdfs[[idx[[1]]]]
}

# ------------------------- Labels + Colors -------------------------
tg_labels <- c(
  TG1 = "continuity",
  TG2 = "return",
  TG3 = "break",
  TG4 = "struggle"
)

sw_labels <- c(
  SW1 = "legitimation",
  SW2 = "positioning",
  SW3 = "identity",
  SW4 = "morality",
  SW5 = "other"
)

tg_colors <- c(
  TG1 = "#001F4D",
  TG2 = "#0B4F8A",
  TG3 = "#4FA3D9",
  TG4 = "#EAF4FF"
)

sw_colors <- c(
  SW1 = "#7A2E00",
  SW2 = "#B34700",
  SW3 = "#FF8C1A",
  SW4 = "#FFC266",
  SW5 = "#FFF3E0"
)

seed_highlight_color <- "#fff4a8"

add_alpha <- function(hex, alpha = "66") paste0(hex, alpha)
escape_regex <- function(x) gsub("([][{}()+*^$|\\\\?.])", "\\\\\\\\1", x)

normalize_seed_term <- function(x) {
  y <- trimws(ifelse(is.na(x), "", as.character(x)))
  if (!nzchar(y)) return("")
  y <- gsub("_", " ", y, fixed = TRUE)
  y <- gsub("[[:space:]]+", " ", y, perl = TRUE)
  trimws(y)
}

load_seed_terms <- function(
    candidates = c(
      "gouden_eeuw_seed_dictionary_long.csv",
      "gouden_eeuw_seed_dictionary.csv",
      "seed dictionary_add.csv",
      "dictplusseed.csv"
    )) {
  terms <- character(0)
  for (f in candidates) {
    if (!file.exists(f)) next
    x <- tryCatch(utils::read.csv(f, stringsAsFactors = FALSE, check.names = FALSE), error = function(e) NULL)
    if (is.null(x) || !nrow(x)) next
    nms <- tolower(names(x))

    term_cols <- c("term", "voc", "lexical_labels", "fixed_anchors", "value_associations")
    use <- intersect(term_cols, nms)
    if (!length(use)) use <- names(x)[1]
    if (length(use) == 1L && use %in% nms) {
      col_name <- names(x)[match(use, nms)]
      raw <- as.character(x[[col_name]])
    } else if (length(use) > 1L) {
      col_names <- names(x)[match(use, nms)]
      raw <- unlist(lapply(col_names, function(cc) as.character(x[[cc]])), use.names = FALSE)
    } else {
      raw <- as.character(x[[1]])
    }
    terms <- c(terms, raw)
  }

  terms <- vapply(terms, normalize_seed_term, character(1))
  terms <- unique(terms[nzchar(terms)])
  terms <- terms[nchar(terms, type = "chars") >= 3L]
  terms[order(nchar(terms, type = "chars"), decreasing = TRUE)]
}

build_seed_regex <- function(term) {
  t <- normalize_seed_term(term)
  if (!nzchar(t)) return(NULL)
  toks <- unlist(strsplit(t, "\\s+", perl = TRUE))
  toks <- toks[nzchar(toks)]
  if (!length(toks)) return(NULL)
  tok_pat <- vapply(toks, function(tt) {
    z <- escape_regex(tt)
    z <- gsub("\\\\-", "[-‐‑‒–—]?", z)
    z
  }, character(1))
  paste0("(?<![[:alnum:]])", paste(tok_pat, collapse = "[[:space:]_\\-]+"), "(?![[:alnum:]])")
}

insert_seed_terms <- function(text_raw, seed_terms, style_css, start_idx = 1L) {
  if (!length(seed_terms) || !nzchar(text_raw)) return(list(text = text_raw, repl = list(), next_idx = start_idx))

  out <- text_raw
  repl <- list()
  idx <- start_idx

  for (tm in seed_terms) {
    if (idx - start_idx > 1200L) break
    pat <- build_seed_regex(tm)
    if (is.null(pat) || !nzchar(pat)) next

    repeat {
      if (idx - start_idx > 1200L) break
      m <- regexpr(pat, out, perl = TRUE, ignore.case = TRUE)
      if (m[[1]] <= 0L) break

      s <- m[[1]]
      e <- s + attr(m, "match.length") - 1L
      matched <- substr(out, s, e)
      ph <- sprintf("___TAG_SD_%05d___", idx)
      idx <- idx + 1L

      out <- paste0(substr(out, 1L, s - 1L), ph, substr(out, e + 1L, nchar(out, type = "chars")))
      repl[[ph]] <- sprintf(
        "<span class=\"seed-mark\" style=\"%s\" title=\"Golden Age seed term\">%s</span>",
        style_css,
        htmlEscape(matched)
      )
    }
  }

  list(text = out, repl = repl, next_idx = idx)
}

seed_terms <- load_seed_terms()

evidence_candidates <- function(snippet_raw) {
  if (!nzchar(trimws(snippet_raw))) return(character(0))
  parts <- unique(c(
    trimws(snippet_raw),
    trimws(unlist(strsplit(snippet_raw, "(\\n|;|\\||•)+", perl = TRUE)))
  ))
  parts <- parts[nzchar(parts)]
  parts[order(nchar(parts, type = "chars"), decreasing = TRUE)]
}

find_evidence_fragment <- function(text_raw, snippet_raw) {
  # Backward-compatible single-fragment helper.
  frags <- find_evidence_fragments(text_raw, snippet_raw, max_fragments = 1L)
  if (!length(frags)) return(NULL)
  frags[[1]]
}

expand_match_to_sentence <- function(text_raw, start_pos, end_pos) {
  n <- nchar(text_raw, type = "chars")
  if (is.na(n) || n <= 0 || is.na(start_pos) || is.na(end_pos)) return("")
  start_pos <- max(1L, min(as.integer(start_pos), n))
  end_pos <- max(start_pos, min(as.integer(end_pos), n))

  # Sentence boundaries around the matched span.
  left_part <- if (start_pos > 1L) substr(text_raw, 1L, start_pos - 1L) else ""
  left_marks <- if (nzchar(left_part)) gregexpr("[.!?;\\n]", left_part, perl = TRUE)[[1]] else -1L
  sent_start <- if (length(left_marks) && left_marks[[1]] > 0L) max(left_marks) + 1L else 1L

  right_part <- substr(text_raw, end_pos, n)
  right_mark <- regexpr("[.!?;\\n]", right_part, perl = TRUE)[[1]]
  sent_end <- if (!is.na(right_mark) && right_mark > 0L) end_pos + right_mark - 1L else n

  # Trim leading/trailing whitespace while keeping punctuation.
  while (sent_start < sent_end && grepl("[[:space:]]", substr(text_raw, sent_start, sent_start), perl = TRUE)) {
    sent_start <- sent_start + 1L
  }
  while (sent_end > sent_start && grepl("[[:space:]]", substr(text_raw, sent_end, sent_end), perl = TRUE)) {
    sent_end <- sent_end - 1L
  }

  if (sent_start > sent_end) return("")
  substr(text_raw, sent_start, sent_end)
}

find_evidence_fragments <- function(text_raw, snippet_raw, max_fragments = 24L) {
  if (!nzchar(trimws(snippet_raw)) || !nzchar(trimws(text_raw))) return(character(0))

  candidates <- evidence_candidates(snippet_raw)
  if (!length(candidates)) return(character(0))

  found <- character(0)
  add_fragment <- function(start_pos, match_len) {
    if (length(found) >= max_fragments) return(invisible(NULL))
    if (is.na(start_pos) || start_pos <= 0 || is.na(match_len) || match_len <= 0) return(invisible(NULL))
    end_pos <- start_pos + match_len - 1L
    expanded <- expand_match_to_sentence(text_raw, start_pos, end_pos)
    if (nzchar(expanded) && !expanded %in% found) found <<- c(found, expanded)
    invisible(NULL)
  }

  for (cand in candidates) {
    if (length(found) >= max_fragments) break
    if (!nzchar(cand)) next

    exact_hits <- gregexpr(escape_regex(cand), text_raw, ignore.case = TRUE, perl = TRUE)[[1]]
    exact_lens <- attr(exact_hits, "match.length")

    if (length(exact_hits) && exact_hits[[1]] > 0L) {
      for (i in seq_along(exact_hits)) {
        add_fragment(exact_hits[[i]], exact_lens[[i]])
        if (length(found) >= max_fragments) break
      }
      next
    }

    # Conservative fallback for OCR/noise: n-gram then token-level.
    tokens <- stringr::str_extract_all(tolower(cand), "[[:alnum:]]+")[[1]]
    tokens <- unique(tokens[nchar(tokens) >= 3])
    if (!length(tokens)) next

    found_for_candidate <- FALSE
    if (length(tokens) >= 3) {
      for (n in seq(min(8L, length(tokens)), 3L, by = -1L)) {
        if (found_for_candidate || length(found) >= max_fragments) break
        starts <- seq_len(length(tokens) - n + 1L)
        for (i in starts) {
          gram <- tokens[i:(i + n - 1L)]
          pat <- paste0("\\b", paste(vapply(gram, escape_regex, character(1)), collapse = "\\W+"), "\\b")
          hits <- gregexpr(pat, text_raw, ignore.case = TRUE, perl = TRUE)[[1]]
          lens <- attr(hits, "match.length")
          if (length(hits) && hits[[1]] > 0L) {
            for (j in seq_along(hits)) {
              add_fragment(hits[[j]], lens[[j]])
              if (length(found) >= max_fragments) break
            }
            found_for_candidate <- TRUE
            break
          }
        }
      }
    }

    if (!found_for_candidate && length(found) < max_fragments) {
      key_tokens <- tokens[nchar(tokens) >= 4]
      if (length(key_tokens)) {
        key_tokens <- key_tokens[order(nchar(key_tokens), decreasing = TRUE)]
        for (tok in key_tokens) {
          pat <- paste0("\\b", escape_regex(tok), "\\b")
          hits <- gregexpr(pat, text_raw, ignore.case = TRUE, perl = TRUE)[[1]]
          lens <- attr(hits, "match.length")
          if (length(hits) && hits[[1]] > 0L) {
            for (j in seq_along(hits)) {
              add_fragment(hits[[j]], lens[[j]])
              if (length(found) >= max_fragments) break
            }
            break
          }
        }
      }
    }
  }

  found
}

insert_underlined_fragments <- function(text_raw, fragments, style_css, tag_id, title_text = "", start_idx = 1L) {
  if (!length(fragments)) return(list(text = text_raw, repl = list(), next_idx = start_idx))

  out <- text_raw
  repl <- list()
  idx <- start_idx

  for (fragment in fragments) {
    if (is.null(fragment) || !nzchar(fragment)) next
    m <- regexpr(fragment, out, fixed = TRUE)
    if (m[[1]] <= 0) next

    s <- m[[1]]
    e <- s + attr(m, "match.length") - 1
    placeholder <- sprintf("___TAG_%s_%05d___", tag_id, idx)
    idx <- idx + 1L
    out <- paste0(substr(out, 1, s - 1), placeholder, substr(out, e + 1, nchar(out)))

    safe_title <- htmlEscape(ifelse(is.na(title_text), "", title_text), attribute = TRUE)
    cls <- sprintf("evidence-mark evidence-%s", tolower(tag_id))
    html <- sprintf("<span class=\"%s\" style=\"%s\" title=\"%s\">%s</span>", cls, style_css, safe_title, htmlEscape(fragment))
    repl[[placeholder]] <- html
  }

  list(text = out, repl = repl, next_idx = idx)
}

highlight_evidence <- function(
  text,
  tg_ev,
  sw_ev,
  tg_col,
  sw_col,
  tg_title = "",
  sw_title = "",
  active_type = "none",
  tg_idx = 1L,
  sw_idx = 1L,
  show_seed_terms = TRUE
) {
  out_raw <- ifelse(is.na(text), "", text)
  base_raw <- out_raw
  tg_ev <- ifelse(is.na(tg_ev), "", tg_ev)
  sw_ev <- ifelse(is.na(sw_ev), "", sw_ev)

  tg_style <- sprintf("background-color:%s; border-radius:2px; padding:0 1px;", add_alpha(tg_col, "55"))
  sw_style <- sprintf("background-color:%s; border-radius:2px; padding:0 1px;", add_alpha(sw_col, "55"))
  seed_style <- paste0("background-color:", seed_highlight_color, "; border-radius:2px; padding:0 1px;")

  replacements <- list()

  tg_frags <- find_evidence_fragments(base_raw, tg_ev)
  if (identical(active_type, "tg") && length(tg_frags)) {
    idx <- suppressWarnings(as.integer(tg_idx))
    if (is.na(idx) || idx < 1L) idx <- 1L
    idx <- ((idx - 1L) %% length(tg_frags)) + 1L
    tg_frags <- tg_frags[idx]
  } else {
    tg_frags <- character(0)
  }
  tg_ins <- insert_underlined_fragments(out_raw, tg_frags, tg_style, "TG", title_text = tg_title, start_idx = 1L)
  out_raw <- tg_ins$text
  if (length(tg_ins$repl)) replacements <- c(replacements, tg_ins$repl)

  sw_frags <- find_evidence_fragments(base_raw, sw_ev)
  if (identical(active_type, "sw") && length(sw_frags)) {
    idx <- suppressWarnings(as.integer(sw_idx))
    if (is.na(idx) || idx < 1L) idx <- 1L
    idx <- ((idx - 1L) %% length(sw_frags)) + 1L
    sw_frags <- sw_frags[idx]
  } else {
    sw_frags <- character(0)
  }
  sw_ins <- insert_underlined_fragments(out_raw, sw_frags, sw_style, "SW", title_text = sw_title, start_idx = tg_ins$next_idx)
  out_raw <- sw_ins$text
  if (length(sw_ins$repl)) replacements <- c(replacements, sw_ins$repl)

  if (isTRUE(show_seed_terms) && length(seed_terms)) {
    seed_ins <- insert_seed_terms(out_raw, seed_terms = seed_terms, style_css = seed_style, start_idx = sw_ins$next_idx)
    out_raw <- seed_ins$text
    if (length(seed_ins$repl)) replacements <- c(replacements, seed_ins$repl)
  }

  out_html <- htmlEscape(out_raw)
  if (length(replacements)) {
    ph_names <- names(replacements)
    for (pass in seq_len(4L)) {
      prev_html <- out_html
      for (ph in ph_names) {
        out_html <- gsub(ph, replacements[[ph]], out_html, fixed = TRUE)
      }
      if (identical(out_html, prev_html)) break
    }
  }
  # Hard safety net: never expose internal placeholder tokens.
  out_html <- gsub("___TAG_(TG|SW|SD)_[0-9]{5}___", "", out_html, perl = TRUE)
  out_html
}

get_active_evidence_info <- function(sp_row, active_type = "none", tg_idx = 1L, sw_idx = 1L) {
  if (is.null(sp_row) || !nrow(sp_row)) {
    return(list(type = "none", fragment = "", index = 0L, total = 0L, color = "#d9dce1", title = ""))
  }

  t_raw <- ifelse(is.na(sp_row$text[[1]]), "", as.character(sp_row$text[[1]]))
  a_type <- tolower(trimws(ifelse(is.null(active_type), "", as.character(active_type))))

  if (identical(a_type, "tg")) {
    frags <- find_evidence_fragments(t_raw, ifelse(is.na(sp_row$temporal_grammar_evidence[[1]]), "", as.character(sp_row$temporal_grammar_evidence[[1]])))
    n <- length(frags)
    if (n == 0L) return(list(type = "tg", fragment = "", index = 0L, total = 0L, color = "#d9dce1", title = ""))
    idx <- suppressWarnings(as.integer(tg_idx))
    if (is.na(idx) || idx < 1L) idx <- 1L
    idx <- ((idx - 1L) %% n) + 1L
    tg <- as.character(sp_row$temporal_grammar_code[[1]])
    return(list(
      type = "tg",
      fragment = frags[[idx]],
      index = idx,
      total = n,
      color = ifelse(is.na(unname(tg_colors[tg])), "#d9dce1", unname(tg_colors[tg])),
      title = ifelse(
        !is.na(sp_row$temporal_grammar_rationale[[1]]) && nzchar(trimws(as.character(sp_row$temporal_grammar_rationale[[1]]))),
        as.character(sp_row$temporal_grammar_rationale[[1]]),
        "No temporal grammar rationale available."
      )
    ))
  }

  if (identical(a_type, "sw")) {
    frags <- find_evidence_fragments(t_raw, ifelse(is.na(sp_row$symbolic_work_evidence[[1]]), "", as.character(sp_row$symbolic_work_evidence[[1]])))
    n <- length(frags)
    if (n == 0L) return(list(type = "sw", fragment = "", index = 0L, total = 0L, color = "#d9dce1", title = ""))
    idx <- suppressWarnings(as.integer(sw_idx))
    if (is.na(idx) || idx < 1L) idx <- 1L
    idx <- ((idx - 1L) %% n) + 1L
    sw <- as.character(sp_row$symbolic_work_code[[1]])
    return(list(
      type = "sw",
      fragment = frags[[idx]],
      index = idx,
      total = n,
      color = ifelse(is.na(unname(sw_colors[sw])), "#d9dce1", unname(sw_colors[sw])),
      title = ifelse(
        !is.na(sp_row$symbolic_work_rationale[[1]]) && nzchar(trimws(as.character(sp_row$symbolic_work_rationale[[1]]))),
        as.character(sp_row$symbolic_work_rationale[[1]]),
        "No symbolic work rationale available."
      )
    ))
  }

  list(type = "none", fragment = "", index = 0L, total = 0L, color = "#d9dce1", title = "")
}

split_snippet_parts <- function(x) {
  if (is.na(x) || !nzchar(trimws(as.character(x)))) return(character(0))
  parts <- unlist(strsplit(as.character(x), "\\s*\\|\\|\\s*", perl = TRUE))
  parts <- trimws(parts)
  parts[nzchar(parts)]
}

get_translated_evidence_from_row <- function(sp_row, evidence_info) {
  if (is.null(sp_row) || !nrow(sp_row)) return("")
  if (is.null(evidence_info$type) || !evidence_info$type %in% c("tg", "sw")) return("")

  col <- if (evidence_info$type == "tg") "temporal_grammar_sentences_en" else "symbolic_work_sentences_en"
  if (!col %in% names(sp_row)) return("")

  parts <- split_snippet_parts(sp_row[[col]][[1]])
  if (!length(parts)) return("")

  idx <- suppressWarnings(as.integer(evidence_info$index))
  if (is.na(idx) || idx < 1L) idx <- 1L
  idx <- ((idx - 1L) %% length(parts)) + 1L
  parts[[idx]]
}

translate_nl_to_en <- function(text, endpoint = NULL, timeout_sec = 25) {
  txt <- trimws(ifelse(is.na(text), "", as.character(text)))
  if (!nzchar(txt)) return(list(ok = FALSE, text = "", error = "Empty evidence snippet."))

  ep <- trimws(ifelse(is.null(endpoint), "", as.character(endpoint)))
  if (!nzchar(ep)) ep <- trimws(Sys.getenv("LIBRETRANSLATE_URL", ""))
  if (!nzchar(ep)) ep <- trimws(getOption("libretranslate.url", ""))
  if (!nzchar(ep)) ep <- "http://127.0.0.1:5000/translate"
  api_key <- trimws(Sys.getenv("LIBRETRANSLATE_API_KEY", ""))
  if (!nzchar(api_key)) api_key <- trimws(getOption("libretranslate.api_key", ""))

  if (!requireNamespace("httr", quietly = TRUE)) {
    return(list(ok = FALSE, text = "", error = "Package 'httr' is required for on-demand translation. Install with install.packages('httr').", endpoint = ep))
  }
  if (!requireNamespace("jsonlite", quietly = TRUE)) {
    return(list(ok = FALSE, text = "", error = "Package 'jsonlite' is required for on-demand translation. Install with install.packages('jsonlite').", endpoint = ep))
  }

  payload <- list(q = txt, source = "nl", target = "en", format = "text")
  if (nzchar(api_key)) payload$api_key <- api_key

  resp <- tryCatch(
    httr::POST(
      url = ep,
      body = payload,
      encode = "json",
      httr::timeout(timeout_sec)
    ),
    error = function(e) e
  )

  if (inherits(resp, "error")) {
    return(list(
      ok = FALSE,
      text = "",
      error = paste0("Could not reach LibreTranslate endpoint: ", conditionMessage(resp)),
      endpoint = ep
    ))
  }

  status <- httr::status_code(resp)
  body_txt <- tryCatch(httr::content(resp, as = "text", encoding = "UTF-8"), error = function(e) "")
  if (status < 200 || status >= 300) {
    msg <- sprintf("LibreTranslate returned HTTP %s.", status)
    if (status == 403) {
      msg <- paste0(
        msg,
        " This usually means the endpoint requires an API key. ",
        "Set Sys.setenv(LIBRETRANSLATE_API_KEY='...') or run a local instance without key protection."
      )
    }
    return(list(
      ok = FALSE,
      text = "",
      error = msg,
      details = substr(body_txt, 1, 260),
      endpoint = ep
    ))
  }

  parsed <- tryCatch(jsonlite::fromJSON(body_txt), error = function(e) NULL)
  tr <- if (!is.null(parsed) && !is.null(parsed$translatedText)) as.character(parsed$translatedText[[1]]) else ""
  if (!nzchar(trimws(tr))) {
    return(list(ok = FALSE, text = "", error = "Translation response did not include 'translatedText'.", endpoint = ep))
  }

  list(ok = TRUE, text = tr, endpoint = ep)
}

# ------------------------- Data Prep -------------------------
first_existing <- function(candidates, nms) {
  hit <- candidates[candidates %in% nms]
  if (length(hit) == 0) return(NA_character_)
  hit[[1]]
}

extract_code <- function(x, prefix, fallback) {
  z <- str_to_upper(ifelse(is.na(as.character(x)), "", as.character(x)))
  code <- str_match(z, paste0("(", prefix, "[1-4])"))[, 2]
  code[is.na(code)] <- fallback[((seq_along(code) - 1) %% length(fallback)) + 1][is.na(code)]
  code
}

as_true_flag <- function(x) {
  x_chr <- tolower(trimws(as.character(x)))
  !is.na(x) & x_chr %in% c("true", "t", "1", "yes", "y")
}

normalize_party_key <- function(x) {
  y <- tolower(trimws(ifelse(is.na(x), "", as.character(x))))
  y <- sub("^nl\\.p\\.", "", y)
  y <- gsub("[^a-z0-9 ]", " ", y)
  trimws(gsub("[[:space:]]+", " ", y))
}

normalize_input_data <- function(df) {
  nms <- names(df)

  date_col <- first_existing(c("date", "datum"), nms)
  speaker_col <- first_existing(c("speaker", "spreker"), nms)
  party_col <- first_existing(c("party_ref", "party", "partij"), nms)
  role_col <- first_existing(c("role", "speaker_role"), nms)
  text_col <- if ("text" %in% nms) "text" else NA_character_
  source_col <- first_existing(c("source_file", "source_url", "url"), nms)
  text_en_col <- first_existing(c("text_en", "translation_en"), nms)
  translation_model_col <- first_existing(c("translation_model"), nms)
  tg_lbl_col <- first_existing(c("temporal_grammar_label"), nms)
  sw_lbl_col <- first_existing(c("symbollic_work_label", "symbolic_work_label"), nms)
  tg_code_col <- first_existing(c("temporal_grammar_code"), nms)
  sw_code_col <- first_existing(c("symbolic_work_code", "symbollic_work_code"), nms)
  tg_rat_col <- first_existing(c("temporal_grammar_rationale"), nms)
  sw_rat_col <- first_existing(c("symbolic_work_rationale", "symbollic_work_rationale"), nms)
  tg_ev_col <- first_existing(c("temporal_grammar_evidence"), nms)
  sw_ev_col <- first_existing(c("symbolic_work_evidence", "symoblic_work_evidence"), nms)
  tg_ev_en_col <- first_existing(c("temporal_grammar_evidence_en", "tg_evidence_en"), nms)
  sw_ev_en_col <- first_existing(c("symbolic_work_evidence_en", "sw_evidence_en"), nms)
  include_col <- first_existing(c("include_for_coding"), nms)
  id_col <- first_existing(c("speech_id", "id", "doc_id"), nms)

  if (is.na(date_col) || is.na(text_col)) {
    stop("Input data must include columns 'date' and 'text'.")
  }

  out <- tibble(
    speech_id = if (!is.na(id_col)) as.character(df[[id_col]]) else sprintf("sp_%06d", seq_len(nrow(df))),
    date = as.Date(df[[date_col]]),
    speaker = if (!is.na(speaker_col)) as.character(df[[speaker_col]]) else "Unknown speaker",
    speaker_original = if ("speaker_original" %in% nms) as.character(df$speaker_original) else as.character(df[[speaker_col]]),
    speaker_source_label = if ("speaker_source_label" %in% nms) as.character(df$speaker_source_label) else as.character(df[[speaker_col]]),
    member_ref = if ("member_ref" %in% nms) as.character(df$member_ref) else NA_character_,
    party_ref = if (!is.na(party_col)) as.character(df[[party_col]]) else "unknown",
    role = if (!is.na(role_col)) as.character(df[[role_col]]) else "unknown",
    speaking_capacity = if ("speaking_capacity" %in% nms) as.character(df$speaking_capacity) else "",
    sample_scope_note = if ("sample_scope_note" %in% nms) as.character(df$sample_scope_note) else "",
    parliamentary_group_as_recorded = if ("parliamentary_group_as_recorded" %in% nms) as.character(df$parliamentary_group_as_recorded) else "",
    source_file = if (!is.na(source_col)) as.character(df[[source_col]]) else NA_character_,
    source_url_verified = if ("source_url_verified" %in% nms) as.character(df$source_url_verified) else "",
    include_for_coding = if (!is.na(include_col)) as_true_flag(df[[include_col]]) else TRUE,
    temporal_grammar_code_raw = if (!is.na(tg_code_col)) as.character(df[[tg_code_col]]) else NA_character_,
    symbolic_work_code_raw = if (!is.na(sw_code_col)) as.character(df[[sw_code_col]]) else NA_character_,
    temporal_grammar_label = if (!is.na(tg_lbl_col)) as.character(df[[tg_lbl_col]]) else NA_character_,
    symbollic_work_label = if (!is.na(sw_lbl_col)) as.character(df[[sw_lbl_col]]) else NA_character_,
    temporal_grammar_rationale = if (!is.na(tg_rat_col)) as.character(df[[tg_rat_col]]) else "",
    symbolic_work_rationale = if (!is.na(sw_rat_col)) as.character(df[[sw_rat_col]]) else "",
    temporal_grammar_evidence = if (!is.na(tg_ev_col)) as.character(df[[tg_ev_col]]) else "",
    symbolic_work_evidence = if (!is.na(sw_ev_col)) as.character(df[[sw_ev_col]]) else "",
    temporal_grammar_evidence_en = if (!is.na(tg_ev_en_col)) as.character(df[[tg_ev_en_col]]) else NA_character_,
    symbolic_work_evidence_en = if (!is.na(sw_ev_en_col)) as.character(df[[sw_ev_en_col]]) else NA_character_,
    text = as.character(df[[text_col]]),
    text_en = if (!is.na(text_en_col)) as.character(df[[text_en_col]]) else NA_character_,
    translation_model = if (!is.na(translation_model_col)) as.character(df[[translation_model_col]]) else NA_character_
  ) %>%
    mutate(
      temporal_grammar_code_raw = str_to_upper(trimws(ifelse(is.na(temporal_grammar_code_raw), "", temporal_grammar_code_raw))),
      symbolic_work_code_raw = str_to_upper(trimws(ifelse(is.na(symbolic_work_code_raw), "", symbolic_work_code_raw)))
    ) %>%
    filter(
      !is.na(date),
      include_for_coding,
      temporal_grammar_code_raw != "",
      temporal_grammar_code_raw != "NA",
      temporal_grammar_code_raw != "TG5",
      symbolic_work_code_raw != "",
      symbolic_work_code_raw != "NA"
    ) %>%
    mutate(
      temporal_grammar_code = temporal_grammar_code_raw,
      symbolic_work_code = symbolic_work_code_raw,
      symbollic_work_code = symbolic_work_code,
      temporal_grammar_label = ifelse(
        is.na(unname(tg_labels[temporal_grammar_code])),
        temporal_grammar_code,
        unname(tg_labels[temporal_grammar_code])
      ),
      symbollic_work_label = ifelse(
        is.na(unname(sw_labels[symbolic_work_code])),
        symbolic_work_code,
        unname(sw_labels[symbolic_work_code])
      ),
      year = as.integer(format(date, "%Y")),
      role = tolower(trimws(ifelse(is.na(role), "unknown", role))),
      party_clean = dashboard_party_label(party_ref, role),
      source_file = ifelse(!is.na(source_url_verified) & nzchar(source_url_verified), source_url_verified, source_file),
      combo = paste(temporal_grammar_code, symbolic_work_code, sep = " + "),
      text_en = ifelse(is.na(text_en) | !nzchar(text_en), "", text_en),
      translation_model = ifelse(is.na(translation_model), "", translation_model),
      temporal_grammar_evidence_en = ifelse(
        is.na(temporal_grammar_evidence_en) | !nzchar(temporal_grammar_evidence_en),
        "",
        temporal_grammar_evidence_en
      ),
      symbolic_work_evidence_en = ifelse(
        is.na(symbolic_work_evidence_en) | !nzchar(symbolic_work_evidence_en),
        "",
        symbolic_work_evidence_en
      ),
      # Backward-compatible alias used in older UI code paths.
      symoblic_work_evidence = symbolic_work_evidence
    )

  out
}

# Always load df_final from disk (RDS source used for paper/dashboard parity).
load_dashboard_input <- function(rds_path = "ge_final_45_24.rds",
                                 csv_fallback = c("ge_final_45_24.csv", "df_ge_high_coded_full.csv")) {
  if (file.exists(rds_path)) {
    rds_obj <- tryCatch(readRDS(rds_path), error = function(e) e)
    if (!inherits(rds_obj, "error")) return(rds_obj)
    warning(sprintf("Could not read '%s' as RDS (%s). Trying CSV fallback.", rds_path, conditionMessage(rds_obj)))
  }

  for (csv_path in csv_fallback) {
    if (file.exists(csv_path)) {
      message(sprintf("Using CSV fallback: %s", csv_path))
      return(utils::read.csv(csv_path, stringsAsFactors = FALSE))
    }
  }

  stop(
    sprintf(
      "No readable input dataset found. Tried RDS: %s and CSV fallbacks: %s",
      rds_path, paste(csv_fallback, collapse = ", ")
    )
  )
}

load_snippet_translation_map <- function(
    rds_path = "df_snippets_translated.rds",
    csv_fallback = "df_snippets_translated.csv") {
  out <- NULL

  if (file.exists(rds_path)) {
    out <- tryCatch(readRDS(rds_path), error = function(e) NULL)
  } else if (file.exists(csv_fallback)) {
    out <- tryCatch(utils::read.csv(csv_fallback, stringsAsFactors = FALSE), error = function(e) NULL)
  }

  if (is.null(out) || !nrow(out)) return(tibble())
  out <- as_tibble(out)

  need <- c("speech_id", "temporal_grammar_sentences_en", "symbolic_work_sentences_en")
  if (!all(need %in% names(out))) return(tibble())

  out %>%
    transmute(
      speech_id = as.character(speech_id),
      temporal_grammar_sentences_en = as.character(temporal_grammar_sentences_en),
      symbolic_work_sentences_en = as.character(symbolic_work_sentences_en)
    ) %>%
    distinct(speech_id, .keep_all = TRUE)
}

df_final <- apply_speech_metadata_corrections(load_dashboard_input(), metadata_corrections)

# Restrict dashboard scope to the paper period (inclusive): 1945-01-01 to 2024-12-31.
paper_start_date <- as.Date("1945-01-01")
paper_end_date <- as.Date("2024-12-31")

df_dash <- normalize_input_data(df_final) %>%
  filter(date >= paper_start_date, date <= paper_end_date)

if (nrow(df_dash) == 0) {
  stop("No rows left after include_for_coding/date/text and paper-period filters (1945-01-01 to 2024-12-31).")
}

# Optional snippet-level translations from OpenAI output file.
snippet_translation_map <- load_snippet_translation_map()
if (nrow(snippet_translation_map)) {
  df_dash <- df_dash %>% left_join(snippet_translation_map, by = "speech_id")
}
if (!"temporal_grammar_sentences_en" %in% names(df_dash)) df_dash$temporal_grammar_sentences_en <- ""
if (!"symbolic_work_sentences_en" %in% names(df_dash)) df_dash$symbolic_work_sentences_en <- ""

# Optional mapping for older SGD documents to direct official ids (e.g. 0000062547).
load_sgd_docid_map <- function(path = "sgd_docid_map.csv") {
  if (!file.exists(path)) {
    return(tibble(sgd_key = character(0), docid10 = character(0)))
  }
  x <- tryCatch(utils::read.csv(path, stringsAsFactors = FALSE), error = function(e) NULL)
  if (is.null(x) || !nrow(x)) {
    return(tibble(sgd_key = character(0), docid10 = character(0)))
  }

  nms <- names(x)
  key_col <- first_existing(c("sgd_key", "doc_key", "source_token", "source_id", "speech_id"), nms)
  id_col <- first_existing(c("docid10", "doc_id", "docid", "official_id", "obk_id"), nms)
  if (is.na(key_col) || is.na(id_col)) {
    return(tibble(sgd_key = character(0), docid10 = character(0)))
  }

  tibble(
    sgd_key = trimws(as.character(x[[key_col]])),
    docid10 = trimws(as.character(x[[id_col]]))
  ) %>%
    mutate(
      sgd_key = sub("\\.xml$", "", sgd_key, ignore.case = TRUE),
      sgd_key = sub("^nl\\.proc\\.sgd\\.d\\.", "", sgd_key, ignore.case = TRUE),
      sgd_key = sub("^nl\\.proc\\.ob\\.d\\.", "", sgd_key, ignore.case = TRUE),
      docid10 = gsub("[^0-9]", "", docid10)
    ) %>%
    filter(grepl("^[0-9]{8,}$", sgd_key), grepl("^[0-9]{10}$", docid10)) %>%
    distinct(sgd_key, .keep_all = TRUE)
}

sgd_docid_map <- load_sgd_docid_map()

# Explicit speech-to-person links replace the old surname-based biography lookup.
speaker_profiles <- load_speaker_profiles()
df_dash <- apply_speaker_profiles(df_dash, speaker_profiles)

min_date <- paper_start_date
max_date <- paper_end_date
year_max <- as.integer(format(paper_end_date, "%Y"))
year_min <- as.integer(format(paper_start_date, "%Y"))
bin_year_min <- (year_min %/% 5L) * 5L
bin_year_max <- (year_max %/% 5L) * 5L + 4L
all_parties_global <- sort(unique(df_dash$party_clean))

# ------------------------- UI -------------------------
app_theme <- bs_theme(
  bg = "#f8f7f3",
  fg = "#1d2935",
  primary = "#1d3557",
  secondary = "#6c757d",
  base_font = "Georgia",
  heading_font = "Georgia"
)

ui <- page_fluid(
  theme = app_theme,
  tags$head(
    tags$style(HTML(
      ".container-fluid{max-width:100% !important;width:100% !important;padding-left:clamp(8px,1.1vw,14px);padding-right:clamp(8px,1.1vw,14px);}\n",
      ":root{--box-gap:clamp(8px,.7vw,10px);--lower-box-h:clamp(220px,30vh,360px);--stack-main-h:clamp(620px,68vh,980px);--stack-sync-h:clamp(860px,78vh,1180px);--chip-h:clamp(34px,2.2vw,38px);--card-pad:clamp(9px,.9vw,12px);--combo-plot-pad-l:56px;--combo-plot-pad-r:8px;}\n",
      "*,*::before,*::after{box-sizing:border-box;}\n",
      ".row{--bs-gutter-x:var(--box-gap) !important;--bs-gutter-y:0 !important;}\n",
      ".app-header{margin:0 0 var(--box-gap) 0;padding:12px 10px 10px 10px;border-radius:10px;background:#f1efe8;border:1px solid #d7d2c5;}\n",
      ".app-header-main{width:100%;max-width:none;padding:0 calc(var(--box-gap)/2);}\n",
      ".title-actions-row{display:flex;align-items:center;justify-content:space-between;gap:var(--box-gap);margin-bottom:8px;}\n",
      ".app-title{margin:0;font-size:clamp(1rem,1.75vw,2.05rem);line-height:1.15;white-space:nowrap;max-width:none;overflow:hidden;text-overflow:clip;flex:1 1 auto;min-width:0;}\n",
      ".app-subtitle{margin:0;max-width:980px;font-size:.98rem;}\n",
      ".intro-row{display:grid;grid-template-columns:minmax(0,2.2fr) minmax(280px,1fr);gap:var(--box-gap);width:100%;max-width:none;align-items:stretch;}\n",
      ".intro-box{grid-column:1;min-width:0;border:1px solid #d6dce5;border-radius:8px;background:#fcfcfb;padding:10px;height:100%;}\n",
      ".intro-top3{grid-column:2;border:1px solid #d6dce5;border-radius:8px;background:#ffffff;padding:8px;display:flex;flex-direction:column;min-height:0;height:100%;}\n",
      ".intro-top3 .section-label-row{margin-bottom:6px;align-items:center;}\n",
      ".intro-top3 .section-label{margin-bottom:0;line-height:1.2;}\n",
      ".intro-top3 .intro-reset-btn,.intro-top3 .intro-reset-btn.btn,.intro-top3 .intro-reset-btn.action-button{height:30px !important;min-height:30px !important;max-height:30px !important;padding:4px 10px !important;font-size:.82rem !important;}\n",
      ".intro-combo-chart-wrap{flex:1 1 auto;min-height:0;border:1px solid #d6dce5;border-radius:8px;background:#fcfcfb;padding:6px 8px;display:flex;flex-direction:column;gap:6px;overflow:hidden;}\n",
      ".intro-combo-plot{flex:1 1 auto;min-height:clamp(145px,22vh,280px);}\n",
      ".intro-combo-axis{flex:0 0 auto;overflow:hidden;padding:0 var(--combo-plot-pad-r) 2px var(--combo-plot-pad-l);}\n",
      ".intro-combo-axis-grid{display:grid;column-gap:6px;row-gap:0;align-items:start;width:100%;min-width:0;}\n",
      ".intro-combo-axis-col{display:flex;flex-direction:column;align-items:stretch;gap:4px;min-width:0;width:100%;}\n",
      ".intro-combo-axis-badge{display:block !important;width:100%;max-width:100%;box-sizing:border-box;margin:0;padding:3px 6px;font-size:clamp(.66rem,.78vw,.76rem);line-height:1.15;color:#1d2935;white-space:nowrap;overflow:hidden;text-overflow:ellipsis;text-align:center;}\n",
      ".app-subtitle-cols{display:grid;grid-template-columns:1fr 1fr;gap:14px;max-width:none;}\n",
      ".app-subtitle-col{margin:0;font-size:.98rem;line-height:1.45;}\n",
      ".header-authors-row{display:flex;flex-wrap:wrap;gap:var(--box-gap);max-width:1200px;margin:0;justify-content:flex-end;flex:0 0 auto;}\n",
      ".header-author-btn{display:inline-flex;align-items:center;gap:7px;padding:7px 12px;border-radius:999px;font-size:.9rem;font-weight:700;line-height:1.2;min-height:42px;border:1px solid #7ea6ce;background:#dceeff;color:#1d3557;text-decoration:none;}\n",
      ".header-author-btn:hover{background:#cde6ff;border-color:#5d8fbe;color:#1d3557;}\n",
      ".btn-icon{display:inline-flex;align-items:center;justify-content:center;width:18px;height:18px;border-radius:999px;border:1px solid transparent;}\n",
      ".btn-icon i{font-size:.74rem;line-height:1;}\n",
      ".btn-icon.rug{background:#e2f0ff;border-color:#8cb5dd;color:#0f4b86;}\n",
      ".btn-icon.gh{background:#eef0f4;border-color:#b9c0cc;color:#222a35;}\n",
      ".btn-icon.doc{background:#f7efdb;border-color:#d8c189;color:#7a5a12;}\n",
      ".draft-pdf-dialog{width:96vw;max-width:96vw;margin:1.5vh auto;}\n",
      ".draft-pdf-dialog .modal-content{height:94vh;}\n",
      ".draft-pdf-dialog .modal-body{height:calc(94vh - 122px);padding:10px;overflow:hidden;}\n",
      ".draft-pdf-viewer-wrap{height:100%;width:100%;}\n",
      ".draft-pdf-viewer{width:100%;height:100%;border:1px solid #cfd6df;border-radius:8px;background:#fff;}\n",
      ".header-meta-row{display:grid;grid-template-columns:1fr;gap:10px;max-width:1200px;margin-top:10px;}\n",
      ".header-meta-chip{background:#fbfcfe;border:1px solid #d6dce5;border-radius:999px;padding:6px 12px;font-size:.9rem;font-weight:600;white-space:nowrap;overflow:hidden;text-overflow:ellipsis;}\n",
      ".panel-card{background:#fff;border:1px solid #d9dce1;border-radius:10px;padding:var(--card-pad);margin-bottom:0;min-width:0;}\n",
      ".left-main-stack{display:flex;flex-direction:column;gap:var(--box-gap);height:var(--stack-sync-h);min-height:0;max-height:var(--stack-sync-h);}\n",
      ".left-top-main{flex:0 0 auto;height:auto;display:flex;flex-direction:column;min-height:0;margin-bottom:0;}\n",
      ".left-top-party{flex:0 0 auto;height:auto;display:flex;flex-direction:column;min-height:0;margin-bottom:0;overflow:hidden;}\n",
      ".left-top-speech{flex:1 1 auto;height:auto;display:flex;flex-direction:column;min-height:0;overflow:hidden;margin-top:0;margin-bottom:0;}\n",
      ".speech-table-wrap{flex:1 1 auto;min-height:0;height:100%;max-height:100%;overflow-y:auto;overflow-x:hidden;scrollbar-gutter:stable;}\n",
      ".speech-table-wrap::-webkit-scrollbar{width:10px;}\n",
      ".speech-table-wrap::-webkit-scrollbar-track{background:#eef2f6;border-radius:8px;}\n",
      ".speech-table-wrap::-webkit-scrollbar-thumb{background:#b7c4d3;border-radius:8px;}\n",
      ".speech-table-wrap::-webkit-scrollbar-thumb:hover{background:#9fb0c4;}\n",
      ".left-top-speech .dataTables_wrapper{height:auto !important;min-height:0;}\n",
      ".right-main-stack{display:flex;flex-direction:column;gap:var(--box-gap);height:auto;min-height:0;}\n",
      ".top-right-stack{height:var(--stack-sync-h);max-height:var(--stack-sync-h);display:flex;flex-direction:column;gap:var(--box-gap);min-height:0;}\n",
      ".legend-top-row{display:grid;grid-template-columns:1fr 1fr;gap:var(--box-gap);}\n",
      ".top-right-card{flex:1 1 0;display:flex;flex-direction:column;margin-bottom:0;min-height:0;}\n",
      ".top-right-card-tg,.top-right-card-sw{flex:0 0 auto;height:auto;}\n",
      ".top-right-card-dutch{flex:1 1 auto;height:auto;min-height:0;overflow-y:auto;padding-top:0;}\n",
      ".top-right-card .legend-box,.top-right-card .combo-bars-wrap{flex:1 1 auto;min-height:0;}\n",
      ".right-bottom-card{flex:0 0 var(--lower-box-h);height:var(--lower-box-h);display:flex;flex-direction:column;min-height:0;overflow-y:auto;}\n",
      ".dash-row{margin:0 0 var(--box-gap) 0;}\n",
      ".section-label{font-size:.84rem;font-weight:700;text-transform:uppercase;letter-spacing:.05em;color:#4d5a66;margin-bottom:6px;}\n",
      ".section-label-row{display:flex;align-items:center;justify-content:space-between;gap:10px;margin-bottom:6px;}\n",
      ".section-label-row .section-label{margin-bottom:0;}\n",
      ".section-tools{font-size:.82rem;line-height:1;white-space:nowrap;}\n",
      ".helper-text{font-size:.84rem;color:#5f6c79;margin:5px 0 0 0;}\n",
      ".header-badges-row{display:flex;align-items:flex-start;gap:7px;flex-wrap:nowrap;margin-bottom:4px;overflow-x:auto;overflow-y:hidden;min-height:60px;padding-bottom:0;}\n",
      ".header-badges-row .combo-badge{margin-right:0;white-space:nowrap;flex:0 0 auto;padding:0 12px;font-size:.9rem;line-height:1.2;height:var(--chip-h);min-height:var(--chip-h);max-height:var(--chip-h);display:inline-flex;align-items:center;box-sizing:border-box;}\n",
      ".header-badges-row a.combo-badge{background:#eef3f8;border:1px solid #c7d3e1;color:#1d2935;text-decoration:none;}\n",
      ".header-badges-row a.combo-badge:hover{border-color:#9fb3c7;}\n",
      ".header-badges-row .combo-badge-neutral{background:#eef3f8;border:1px solid #c7d3e1;color:#1d2935;cursor:default;}\n",
      ".dutch-header-slot{flex:0 0 auto;min-height:70px;margin-top:calc(var(--box-gap) * .7);margin-bottom:4px;padding:2px 0 2px 0;}\n",
      ".combo-wrap{margin-bottom:10px;}\n",
      ".combo-badge{display:inline-block;padding:5px 10px;border-radius:999px;font-size:.88rem;font-weight:700;margin-right:7px;cursor:pointer;}\n",
      ".party-chips{display:flex;flex-wrap:wrap;column-gap:6px;row-gap:6px;align-content:flex-start;align-items:flex-start;flex:1 1 auto;min-height:0;overflow-y:auto;overflow-x:hidden;padding-right:2px;}\n",
      ".party-chip-btn,.party-chip-btn.btn,.party-chip-btn.action-button{display:inline-flex !important;align-items:center !important;justify-content:center;padding:0 12px !important;border-radius:999px;font-size:.9rem;font-weight:700;line-height:1.2;height:var(--chip-h) !important;min-height:var(--chip-h) !important;max-height:var(--chip-h) !important;box-sizing:border-box;border:1px solid #7ea6ce;background:#dceeff;color:#1d3557;white-space:nowrap;}\n",
      ".party-chip-btn.is-off{background:#f1f3f6;border-color:#d2d8e0;color:#8a95a1;opacity:.6;}\n",
      ".evidence-focus{outline:2px solid #1d3557;outline-offset:1px;}\n",
      ".list-code-badge{display:inline-block;padding:5px 10px;border-radius:999px;font-size:.88rem;font-weight:700;line-height:1.25;border:1px solid transparent;color:#1d2935;max-width:100%;}\n",
      ".combo-stack{display:flex;width:100%;flex-wrap:wrap;gap:4px;align-items:center;justify-content:flex-start;white-space:normal;max-width:100%;}\n",
      ".text-box{background:#fff;border:1px solid #d6dce5;border-radius:9px;padding:11px;max-height:270px;overflow-y:auto;line-height:1.45;white-space:pre-wrap;}\n",
      ".text-box-dutch{max-height:430px;}\n",
      ".text-box-english{min-height:calc(1.45em * 4 + 22px);}\n",
      ".zoom-controls{display:flex;align-items:center;gap:8px;margin:0 0 4px 0;flex-wrap:nowrap;overflow-x:visible;}\n",
      ".zoom-search-wrap{margin:0;min-width:220px;max-width:280px;}\n",
      ".zoom-search-wrap .form-group{margin-bottom:0;}\n",
      ".zoom-search-wrap .form-control{height:32px;border-radius:999px;padding:4px 10px;font-size:.84rem;line-height:1.2;}\n",
      ".zoom-left{display:flex;align-items:center;gap:0;}\n",
      ".zoom-level{font-size:.82rem;color:#4d5a66;min-width:0;margin:0;padding:0;}\n",
      ".zoom-text-label{font-size:.84rem;font-weight:700;color:#4d5a66;letter-spacing:.02em;white-space:nowrap;margin-left:8px;}\n",
      ".zoom-btn{padding:2px 8px;font-size:.8rem;line-height:1.2;}\n",
      ".timeline-inner{padding-left:0;padding-right:0;position:relative;}\n",
      ".timeline-head-row{display:flex;flex-direction:row;align-items:center;justify-content:space-between;gap:var(--box-gap);margin-bottom:6px;min-width:0;}\n",
      ".timeline-head-left{display:none;}\n",
      ".timeline-head-actions{display:flex;align-items:center;gap:var(--box-gap);flex:0 0 auto;}\n",
      ".manual-period-btn,.manual-period-btn.btn,.manual-period-btn.action-button{display:inline-flex !important;align-items:center !important;justify-content:center;padding:0 12px !important;border-radius:999px;font-size:.9rem !important;font-weight:700;line-height:1.2 !important;height:var(--chip-h) !important;min-height:var(--chip-h) !important;max-height:var(--chip-h) !important;box-sizing:border-box;border:1px solid #c7d3e1;background:#ffffff;color:#1d2935;white-space:nowrap;}\n",
      ".manual-period-btn:hover,.manual-period-btn.btn:hover,.manual-period-btn.action-button:hover{background:#f7fafc;border-color:#9fb3c7;color:#1d2935;}\n",
      ".timeline-head-slider{flex:1 1 auto;min-width:0;max-width:none;margin:0 0 0 clamp(4px,.8vw,12px);padding-left:clamp(2px,.4vw,8px);}\n",
      ".timeline-head-slider .form-group{margin-bottom:0;}\n",
      ".timeline-head-slider .irs{margin-top:0;width:100%;}\n",
      ".timeline-head-slider .irs--shiny .irs-bar{background:#2f67a6;border-color:#2f67a6;}\n",
      ".timeline-head-slider .irs--shiny .irs-handle>i:first-child{background:#2f67a6;}\n",
      ".timeline-plot-wrap{margin-top:2px;}\n",
      ".timeline-slider-wrap{margin-top:4px;padding:0 2px;}\n",
      ".compact-date-inline{flex:0 0 auto;width:170px;min-width:170px;max-width:170px;}\n",
      ".compact-date-inline .form-group{margin-bottom:0;}\n",
      ".date-pill{display:flex;align-items:center;gap:8px;height:36px;padding:0 10px;border:1px solid #c7d3e1;border-radius:999px;background:#eef3f8;}\n",
      ".date-pill-label{font-size:.86rem;font-weight:700;line-height:1;color:#4d5a66;white-space:nowrap;}\n",
      ".date-pill .shiny-date-input{width:100%;margin-bottom:0;}\n",
      ".date-pill .input-group{display:flex;align-items:center;}\n",
      ".date-pill .form-control{height:30px;padding:2px 4px;border:0;background:transparent;box-shadow:none;font-size:.9rem;line-height:1.2;}\n",
      ".date-pill .input-group-addon{border:0;background:transparent;padding:0 2px;color:#5f6c79;}\n",
      ".js-plotly-plot .plotly .rangeslider-container{opacity:1;}\n",
      ".timeline-hover-info{position:absolute;left:0;top:0;z-index:30;pointer-events:none;}\n",
      ".timeline-hover-popup{display:inline-block;background:#eef1f5;border:1px solid #cfd6df;border-radius:8px;padding:5px 9px;font-size:.84rem;color:#31404e;}\n",
      ".heatmap-placeholder{height:310px;border:1px dashed #b9c3cf;border-radius:8px;background:#f9fbfd;display:flex;align-items:center;justify-content:center;color:#5f6c79;font-size:.95rem;}\n",
      ".legend-box{height:auto;min-height:0;border:1px solid #d6dce5;border-radius:8px;background:#fcfcfb;padding:10px;overflow-y:visible;}\n",
      ".top-right-card-tg .legend-inline-chip-btn,.top-right-card-sw .legend-inline-chip-btn{margin-bottom:8px;}\n",
      ".legend-box p{font-size:.9rem;line-height:1.4;margin:0 0 8px 0;}\n",
      ".legend-sub{font-size:.78rem;font-weight:700;text-transform:uppercase;letter-spacing:.04em;color:#4d5a66;margin:8px 0 4px 0;}\n",
      ".legend-list{margin:0;padding-left:16px;}\n",
      ".legend-list li{font-size:.82rem;line-height:1.3;margin:2px 0;}\n",
      ".mini-chip{display:inline-block;padding:1px 6px;border-radius:999px;font-size:.72rem;font-weight:700;border:1px solid transparent;margin-right:4px;}\n",
      ".legend-grid{display:grid;grid-template-columns:1fr 1fr;gap:12px;}\n",
      ".legend-col{min-width:0;}\n",
      ".legend-item{display:flex;align-items:center;gap:10px;margin:6px 0;}\n",
      ".mini-chip-btn,.mini-chip-btn.btn,.mini-chip-btn.action-button{display:inline-flex !important;align-items:center !important;justify-content:center;padding:0 12px !important;border-radius:999px;font-size:.9rem !important;font-weight:700;line-height:1.2 !important;height:var(--chip-h) !important;min-height:var(--chip-h) !important;max-height:var(--chip-h) !important;box-sizing:border-box;border:1px solid transparent;color:#1d2935;white-space:nowrap;}\n",
      ".mini-chip-btn.is-selected{border-width:2px;box-shadow:0 0 0 1px #1d3557 inset;}\n",
      ".mini-chip-btn.is-faded{opacity:.42;filter:saturate(.55);}\n",
      ".legend-inline-chip-btn{display:inline-flex;align-items:center;justify-content:center;padding:0 12px;border-radius:999px;font-size:.9rem;font-weight:700;line-height:1.2;height:var(--chip-h);min-height:var(--chip-h);max-height:var(--chip-h);box-sizing:border-box;border:1px solid #c7d3e1;color:#1d2935;background:#ffffff;white-space:nowrap;cursor:pointer;}\n",
      ".legend-inline-chip-btn:hover{background:#f7fafc;border-color:#9fb3c7;}\n",
      ".legend-desc{font-size:.88rem;line-height:1.25;}\n",
      ".combo-bars-wrap{border:1px solid #d6dce5;border-radius:8px;background:#fcfcfb;padding:10px;}\n",
      ".combo-bar-row{min-height:74px;height:auto;margin:0 0 8px 0;}\n",
      ".combo-bar-btn{display:flex;align-items:center;justify-content:flex-start;width:100%;min-height:60px;height:auto;text-align:left;border:1px solid #c7d3e1;border-radius:999px;padding:8px 12px;font-size:.9rem;font-weight:700;color:#1d2935;background:#eef3f8;line-height:1.2;white-space:normal;overflow-wrap:anywhere;word-break:normal;box-shadow:inset 0 0 0 1px rgba(255,255,255,.25);}\n",
      ".combo-bar-btn.is-selected{border:2px solid #1d3557;box-shadow:0 0 0 1px #1d3557 inset;}\n",
      ".combo-bars-note{font-size:.77rem;color:#5f6c79;margin-top:4px;}\n",
      ".paper-link{font-size:.89rem;white-space:nowrap;}\n",
      ".paper-link a{color:#1d3557;font-weight:600;}\n",
      ".dataTables_wrapper .dataTable{table-layout:fixed;width:100% !important;}\n",
      "table.dataTable tbody tr.selected, table.dataTable tbody tr.selected > td, table.dataTable tbody th.selected, table.dataTable tbody td.selected{background:#f5f9ff !important;background-color:#f5f9ff !important;background-image:none !important;color:#1d2935 !important;box-shadow:inset 0 0 0 1px #bfd3ea;}\n",
      "table.dataTable tbody tr.selected a, table.dataTable tbody td.selected a{color:#1d2935 !important;}\n",
      "table.dataTable tbody tr.selected .list-code-badge, table.dataTable tbody td.selected .list-code-badge{background:#ffffff !important;border-color:#c7d3e1 !important;color:#1d2935 !important;box-shadow:none !important;}\n",
      "td.dt-nowrap{white-space:nowrap !important;overflow:hidden;text-overflow:ellipsis;}\n",
      "td.party-cell{text-align:left !important;padding-right:4px !important;}\n",
      "td.combo-cell{white-space:normal;min-width:220px;overflow:visible !important;text-overflow:clip !important;}\n",
      "td.combo-cell{text-align:left !important;padding-left:4px !important;padding-right:2px !important;}\n",
      "td.combo-cell .list-code-badge{padding:4px 7px;font-size:.8rem;line-height:1.15;}\n",
      ".speaker-chip{display:inline-block;max-width:15ch;overflow:hidden;text-overflow:ellipsis;white-space:nowrap;vertical-align:bottom;}\n",
      ".search-focus{outline:2px solid #5f7fa5;outline-offset:1px;border-radius:3px;}\n",
      ".bslib-grid{row-gap:var(--box-gap) !important;column-gap:var(--box-gap) !important;margin:0 !important;}\n",
      "@media (max-width: 1400px){.intro-row{grid-template-columns:minmax(0,1.8fr) minmax(250px,1fr);} :root{--stack-sync-h:clamp(820px,78vh,1120px);} }\n",
      "@media (max-width: 1200px){.title-actions-row{flex-wrap:wrap;align-items:flex-start;} .header-authors-row{justify-content:flex-start;} .intro-row{grid-template-columns:1fr;} .intro-box,.intro-top3{grid-column:auto;} .timeline-head-row{flex-wrap:wrap;} .timeline-head-slider{order:2;flex:1 1 100%;margin-left:0;padding-left:0;} .timeline-head-actions{order:1;margin-left:auto;} .left-main-stack,.top-right-stack{height:auto;max-height:none;} .intro-combo-axis-badge{font-size:clamp(.64rem,.84vw,.74rem);padding:2px 6px;}}\n",
      "@media (max-width: 991px){.top-right-stack{height:auto;max-height:none;}.legend-top-row{grid-template-columns:1fr;}.left-main-stack{height:auto;max-height:none;}.left-top-main,.left-top-party,.left-top-speech{flex:1 1 auto;height:auto;}.intro-row,.app-subtitle-cols,.header-meta-row{grid-template-columns:1fr;}.intro-box,.intro-top3{grid-column:auto;}.title-actions-row{flex-direction:column;align-items:flex-start;}.header-authors-row{justify-content:flex-start;}.app-title{font-size:clamp(.92rem,4.2vw,1.7rem);white-space:nowrap;} .intro-combo-axis-badge{font-size:clamp(.62rem,.94vw,.72rem);padding:2px 5px;}}\n"
    )),
    tags$script(HTML(
      "window.__evidenceCycleState = window.__evidenceCycleState || {};
       window.scrollEvidenceInBox = function(boxId, kind) {
         var type = (kind === 'sw') ? 'sw' : 'tg';
         var box = document.getElementById(boxId);
         if (!box) return;
         var sel = (type === 'sw') ? '.evidence-sw' : '.evidence-tg';
         var centerOn = function(el) {
           if (!el || !box) return;
           var boxRect = box.getBoundingClientRect();
           var elRect = el.getBoundingClientRect();
           var y = box.scrollTop + (elRect.top - boxRect.top) - (box.clientHeight / 2) + (elRect.height / 2);
           box.scrollTop = Math.max(0, y);
         };
         var tryFind = function(attempt) {
           var nodes = box.querySelectorAll(sel);
           if (!nodes || !nodes.length) {
             if (attempt < 14) setTimeout(function(){ tryFind(attempt + 1); }, 80);
             return;
           }

           var speechId = box.getAttribute('data-speech-id') || '';
           var speechKey = boxId + '_speech';
           if (window.__evidenceCycleState[speechKey] !== speechId) {
             window.__evidenceCycleState[speechKey] = speechId;
             window.__evidenceCycleState[boxId + '_tg'] = 0;
             window.__evidenceCycleState[boxId + '_sw'] = 0;
           }

           var idxKey = boxId + '_' + type;
           var idx = window.__evidenceCycleState[idxKey] || 0;
           if (idx >= nodes.length) idx = 0;
           var el = nodes[idx];
           window.__evidenceCycleState[idxKey] = (idx + 1) % nodes.length;

           centerOn(el);
           setTimeout(function(){ centerOn(el); }, 30);
           box.querySelectorAll('.evidence-focus').forEach(function(x){ x.classList.remove('evidence-focus'); });
           el.classList.add('evidence-focus');
           setTimeout(function(){ el.classList.remove('evidence-focus'); }, 1100);
         };
         tryFind(0);
       };
       window.scrollDutchEvidence = function(kind) { window.scrollEvidenceInBox('dutch_text_box', kind); };
       Shiny.addCustomMessageHandler('scrollDutchEvidence', function(msg) {
         window.scrollDutchEvidence((msg && msg.type) ? msg.type : 'tg');
       });

       window.searchInDutchBox = function(query) {
         var box = document.getElementById('dutch_text_box');
         if (!box) return;
         var q = (query || '').toString();
         box.querySelectorAll('.search-focus').forEach(function(el){ el.classList.remove('search-focus'); });
         if (!q.trim()) return;
         var qLower = q.toLowerCase();
         var walker = document.createTreeWalker(box, NodeFilter.SHOW_TEXT, null);
         var node = null;
         while ((node = walker.nextNode())) {
           var txt = node.nodeValue || '';
           var idx = txt.toLowerCase().indexOf(qLower);
           if (idx >= 0) {
             var range = document.createRange();
             range.setStart(node, idx);
             range.setEnd(node, idx + q.length);
             var sel = window.getSelection();
             sel.removeAllRanges();
             sel.addRange(range);
             var parent = node.parentElement || box;
             if (parent && parent.scrollIntoView) parent.scrollIntoView({ block: 'center', behavior: 'smooth' });
             if (parent && parent.classList) {
               parent.classList.add('search-focus');
               setTimeout(function(){ parent.classList.remove('search-focus'); }, 1200);
             }
             return;
           }
         }
       };
       Shiny.addCustomMessageHandler('searchDutchText', function(msg) {
         window.searchInDutchBox((msg && msg.query) ? msg.query : '');
       });

       document.addEventListener('keydown', function(e) {
         var key = (e.key || '').toLowerCase();
         if (key !== 'a' || !(e.metaKey || e.ctrlKey)) return;
         var active = document.activeElement;
         if (!active) return;
         if (active.tagName === 'INPUT' || active.tagName === 'TEXTAREA' || active.isContentEditable) return;
         var box = document.getElementById('dutch_text_box');
         if (!box) return;
         var inDutchPanel = active.closest ? !!active.closest('.top-right-card-dutch') : false;
         var sel = window.getSelection();
         var anchor = sel ? sel.anchorNode : null;
         var inBoxSelection = !!(anchor && box.contains(anchor));
         if (!inDutchPanel && !inBoxSelection) return;
         e.preventDefault();
         var r = document.createRange();
         r.selectNodeContents(box);
         sel.removeAllRanges();
         sel.addRange(r);
       });"
    ))
  ),

  div(
    class = "app-header",
    div(
      class = "app-header-main",
      div(
        class = "title-actions-row",
        tags$h1(class = "app-title", HTML("\"Golden Age\" Politics in Dutch Parliament, 1945-2024")),
        div(
          class = "header-authors-row",
          tags$a(
            class = "header-author-btn",
            href = "https://www.rug.nl/staff/s.couperus/?lang=en",
            target = "_blank",
            span(class = "btn-icon rug", icon("university")),
            "Stefan Couperus"
          ),
          tags$a(
            class = "header-author-btn",
            href = "https://www.rug.nl/staff/martijn.schoonvelde/",
            target = "_blank",
            span(class = "btn-icon rug", icon("university")),
            "Martijn Schoonvelde"
          ),
          tags$a(
            class = "header-author-btn",
            href = "https://github.com/stefancouperus/golden_age_dashboard",
            target = "_blank",
            span(class = "btn-icon gh", icon("github")),
            "GitHub Project"
          ),
          tags$a(
            class = "header-author-btn",
            href = "#",
            onclick = "Shiny.setInputValue('open_draft_paper', Date.now(), {priority:'event'}); return false;",
            span(class = "btn-icon doc", icon("file-alt")),
            "draft paper"
          )
        )
      ),
      div(
        div(
          class = "intro-row",
          div(
            class = "intro-box",
            div(
              class = "app-subtitle-cols",
              tags$p(
                class = "app-subtitle-col",
                "Our project examines how Dutch MPs use \"Gouden Eeuw\" (Golden Age) language as a mnemonic trope in parliamentary speech (1945-2024). We analyse their temporal operation, i.e. how speakers link a canonical seventeenth-century past to the present and future, and the symbolic work those linkages perform in parliamentary interaction. Using a corpus of roughly three million speeches, we retrieve 447 speeches with \"Gouden Eeuw\"-related episodes via a dictionary-and-embeddings pipeline and then apply an interpretive codebook that distinguishes four temporal grammars (continuity, return, break, struggle) and four functions (governing legitimation, competitive positioning, identity/boundary making, moral memory) which we code at scale using a large language model (LLM)."
              ),
              tags$p(
                class = "app-subtitle-col",
                "Across the period, continuity dominates, showing the trope's long-standing role as routinised national shorthand, most often mobilised to legitimise policy by invoking enduring national vocation (trade, entrepreneurship, outward orientation). Yet the trope's uses are conjunctural: return peaks in postwar reconstruction and resurges after the mid-2000s as a restorative governing register; break clusters in the reform decades of the 1980s-1990s; and struggle intensifies after 2006 as heritage controversies and polarised competition turn \"Gouden Eeuw\" into a flashpoint over mnemonic authority. Methodologically, the project demonstrates how computational retrieval and LLM-assisted coding can scale interpretable chronopolitics and memory-politics analysis across long parliamentary time series."
              )
            )
          ),
          div(
            class = "intro-top3",
            div(
              class = "section-label-row",
              tags$span(
                class = "section-label",
                title = "Shows the top 5 TG/SW code combinations in the current selection. X-axis lists combinations, y-axis counts speeches. Click a bar to filter to that combination. Bar labels show each combination's percentage share.",
                "TOP 5: TEMPORAL GRAMMAR AND SYMBOLIC WORK COMBINATIONS IN SELECTION"
              ),
              actionButton(
                "reset_selection_top",
                "reset selection",
                class = "manual-period-btn intro-reset-btn"
              )
            ),
            div(
              class = "intro-combo-chart-wrap",
              div(class = "intro-combo-plot", plotly::plotlyOutput("combo_selection_plotly", height = "100%")),
              uiOutput("combo_axis_buttons")
            )
          )
        ),
      )
    )
  ),

  # Top row: timeline (left) + heatmap placeholder (right)
  div(
    class = "dash-row",
    layout_columns(
      col_widths = c(5, 7),
      div(
        class = "left-main-stack",
        div(
          class = "panel-card left-top-main",
          style = "width:100%;",
          div(
            class = "timeline-head-row",
            div(
              class = "timeline-head-slider",
              sliderInput(
                "period_years",
                label = NULL,
                min = min_date,
                max = max_date,
                value = c(min_date, max_date),
                timeFormat = "%d-%m-%Y",
                step = 1
              )
            ),
            div(
              class = "timeline-head-actions",
              actionButton(
                "reset_period_selection",
                "Reset period",
                class = "manual-period-btn"
              ),
              actionButton(
                "open_manual_dates",
                "Manual selection",
                class = "manual-period-btn"
              )
            )
          ),
          div(
            class = "timeline-plot-wrap",
            plotly::plotlyOutput("timeline_plotly", height = "150px")
          )
        ),
      div(
        class = "panel-card left-top-party",
        div(
          class = "section-label-row",
          div(class = "section-label", "Party Filter (auto-updates to parties in selected period)"),
          div(
            class = "section-tools",
            actionLink("party_select_all", "Select all"),
            tags$span(" / "),
            actionLink("party_deselect_all", "Deselect all")
          )
        ),
        uiOutput("party_filter_buttons")
      ),
      div(
        class = "panel-card left-top-speech",
        uiOutput("speech_list_label"),
        div(class = "speech-table-wrap", DTOutput("speech_table"))
      )
    ),
      div(
        class = "right-main-stack",
        div(
          class = "top-right-stack",
          div(
            class = "legend-top-row",
            div(
              class = "panel-card top-right-card top-right-card-tg",
              tags$button(
                type = "button",
                class = "legend-inline-chip-btn",
                onclick = "Shiny.setInputValue('open_tg_info', Date.now(), {priority:'event'})",
                "temporal grammar"
              ),
              uiOutput("legend_tg_ui")
            ),
            div(
              class = "panel-card top-right-card top-right-card-sw",
              tags$button(
                type = "button",
                class = "legend-inline-chip-btn",
                onclick = "Shiny.setInputValue('open_sw_info', Date.now(), {priority:'event'})",
                "symbolic work"
              ),
              uiOutput("legend_sw_ui")
            )
          ),
          div(
            class = "panel-card top-right-card top-right-card-dutch",
            div(class = "dutch-header-slot", uiOutput("header_badges_row")),
            uiOutput("speech_context_note"),
            uiOutput("dutch_zoom_controls"),
            uiOutput("dutch_text"),
            br(),
            uiOutput("english_text_label"),
            uiOutput("english_text")
          )
        )
      )
    )
  )

  # ------------------------- Server -------------------------
)

# ------------------------- Server -------------------------
server <- function(input, output, session) {
  rv <- reactiveValues(
    selected_speech_id = df_dash$speech_id[[1]],
    combo_filter = NULL,
    tg_filter = NULL,
    sw_filter = NULL,
    speaker_filter = NULL,
    last_speaker_modal_action = as.POSIXct(NA),
    party_selected = all_parties_global,
    period_start = min_date,
    period_end = max_date,
    dutch_zoom = 1,
    show_seed_terms = FALSE,
    translation_cache = list(),
    evidence_active_type = "none",
    evidence_tg_idx = 1L,
    evidence_sw_idx = 1L,
    evidence_speech_id = ifelse(nrow(df_dash), as.character(df_dash$speech_id[[1]]), "")
  )

  translation_cache_key <- function(speech_id, evidence_type, evidence_idx, nl_fragment) {
    paste(
      trimws(ifelse(is.na(speech_id), "", as.character(speech_id))),
      trimws(ifelse(is.na(evidence_type), "", as.character(evidence_type))),
      as.integer(ifelse(is.na(evidence_idx), 0L, evidence_idx)),
      nchar(ifelse(is.na(nl_fragment), "", as.character(nl_fragment)), type = "chars"),
      substr(ifelse(is.na(nl_fragment), "", as.character(nl_fragment)), 1L, 220L),
      sep = "||"
    )
  }

  get_cached_translation <- function(speech_id, evidence_type, evidence_idx, nl_fragment) {
    key <- translation_cache_key(speech_id, evidence_type, evidence_idx, nl_fragment)
    cache <- isolate(rv$translation_cache)
    if (!is.null(cache[[key]])) return(cache[[key]])

    tr <- translate_nl_to_en(nl_fragment)
    cache[[key]] <- tr
    rv$translation_cache <- cache
    tr
  }

  build_speaker_profile <- function(sp) {
    list(
      speaker_name = sp$speaker[[1]],
      role = speaker_role_label(sp$role[[1]]),
      party = sp$party_clean[[1]],
      date = format(sp$date[[1]], "%Y-%m-%d"),
      capacity = sp$speaking_capacity[[1]],
      source = sp$speaker_profile_source[[1]],
      profile_url = sp$speaker_profile_url[[1]],
      match_status = sp$speaker_profile_status[[1]]
    )
  }

  build_speaker_dataset_profile <- function(sp) {
    person_id <- sp$speaker_person_id[[1]]
    x_all <- df_dash %>%
      filter(speaker_person_id == person_id) %>%
      arrange(date)

    n_total <- nrow(x_all)
    first_date <- if (n_total > 0) min(x_all$date, na.rm = TRUE) else as.Date(NA)
    last_date <- if (n_total > 0) max(x_all$date, na.rm = TRUE) else as.Date(NA)
    first_speech_id <- if (n_total > 0) as.character(x_all$speech_id[[1]]) else ""
    last_speech_id <- if (n_total > 0) as.character(x_all$speech_id[[n_total]]) else ""

    x_current <- tryCatch({
      selected_pool() %>%
        filter(speaker_person_id == person_id) %>%
        arrange(date)
    }, error = function(e) x_all[0, , drop = FALSE])

    n_current <- nrow(x_current)
    first_current <- if (n_current > 0) min(x_current$date, na.rm = TRUE) else as.Date(NA)
    last_current <- if (n_current > 0) max(x_current$date, na.rm = TRUE) else as.Date(NA)

    combo_df <- if (n_total > 0) {
      x_all %>%
        transmute(
          speech_id,
          date,
          temporal_grammar_code,
          symbolic_work_code,
          tg_word = ifelse(is.na(unname(tg_labels[temporal_grammar_code])), temporal_grammar_code, unname(tg_labels[temporal_grammar_code])),
          sw_word = ifelse(is.na(unname(sw_labels[symbolic_work_code])), symbolic_work_code, unname(sw_labels[symbolic_work_code])),
          combo_text = paste0(tg_word, " + ", sw_word)
        ) %>%
        arrange(date) %>%
        group_by(combo_text, temporal_grammar_code, symbolic_work_code) %>%
        summarise(
          n = n(),
          first_date = min(date, na.rm = TRUE),
          last_date = max(date, na.rm = TRUE),
          first_speech_id = first(speech_id),
          last_speech_id = last(speech_id),
          .groups = "drop"
        ) %>%
        arrange(desc(n), combo_text) %>%
        mutate(
          pct = 100 * n / n_total
        )
    } else {
      tibble(
        combo_text = character(0),
        temporal_grammar_code = character(0),
        symbolic_work_code = character(0),
        n = integer(0),
        first_date = as.Date(character(0)),
        last_date = as.Date(character(0)),
        first_speech_id = character(0),
        last_speech_id = character(0),
        pct = numeric(0)
      )
    }

    list(
      n_total = n_total,
      first_date = first_date,
      last_date = last_date,
      first_speech_id = first_speech_id,
      last_speech_id = last_speech_id,
      n_current = n_current,
      first_current = first_current,
      last_current = last_current,
      combo_df = combo_df
    )
  }

  show_speaker_modal <- function(sp) {
    prof <- build_speaker_profile(sp)
    stats <- build_speaker_dataset_profile(sp)
    max_combo_n <- if (nrow(stats$combo_df)) max(stats$combo_df$n, na.rm = TRUE) else 1
    sp_key <- trimws(ifelse(is.na(sp$speaker[[1]]), "", as.character(sp$speaker[[1]])))

    js_escape <- function(x) {
      x <- ifelse(is.na(x), "", as.character(x))
      x <- gsub("\\\\", "\\\\\\\\", x, perl = TRUE)
      x <- gsub("'", "\\\\'", x, fixed = TRUE)
      x
    }
    fmt_date <- function(x) ifelse(is.na(x), "", format(as.Date(x), "%Y-%m-%d"))
    sp_js <- js_escape(sp_key)

    summary_buttons <- if (stats$n_total > 0) {
      from_all <- fmt_date(stats$first_date)
      to_all <- fmt_date(stats$last_date)
      sid_first <- js_escape(stats$first_speech_id)
      sid_last <- js_escape(stats$last_speech_id)
      list(
        tags$button(
          type = "button",
          class = "list-code-badge",
          style = "background:#eef3f8;border-color:#c7d3e1;cursor:pointer;",
          onclick = sprintf("Shiny.setInputValue('speaker_modal_action',{type:'speaker',speaker:'%s',from:'%s',to:'%s',speech_id:'%s'},{priority:'event'})", sp_js, from_all, to_all, sid_first),
          paste0("Speeches: ", stats$n_total)
        ),
        tags$button(
          type = "button",
          class = "list-code-badge",
          style = "background:#eef3f8;border-color:#c7d3e1;cursor:pointer;",
          onclick = sprintf("Shiny.setInputValue('speaker_modal_action',{type:'first',speaker:'%s',from:'%s',to:'%s',speech_id:'%s'},{priority:'event'})", sp_js, from_all, from_all, sid_first),
          paste0("First speech: ", from_all)
        ),
        tags$button(
          type = "button",
          class = "list-code-badge",
          style = "background:#eef3f8;border-color:#c7d3e1;cursor:pointer;",
          onclick = sprintf("Shiny.setInputValue('speaker_modal_action',{type:'last',speaker:'%s',from:'%s',to:'%s',speech_id:'%s'},{priority:'event'})", sp_js, to_all, to_all, sid_last),
          paste0("Last speech: ", to_all)
        )
      )
    } else {
      list(
        tags$span(class = "list-code-badge", style = "background:#eef3f8;border-color:#c7d3e1;", "Speeches: 0"),
        tags$span(class = "list-code-badge", style = "background:#eef3f8;border-color:#c7d3e1;", "First speech: n/a"),
        tags$span(class = "list-code-badge", style = "background:#eef3f8;border-color:#c7d3e1;", "Last speech: n/a")
      )
    }

    combo_rows <- if (!nrow(stats$combo_df)) {
      div(class = "helper-text", "No coded speeches found for this speaker in the current dataset.")
    } else {
      lapply(seq_len(nrow(stats$combo_df)), function(i) {
        r <- stats$combo_df[i, , drop = FALSE]
        tg_col <- unname(tg_colors[r$temporal_grammar_code[[1]]]); if (is.na(tg_col)) tg_col <- "#9bb7d0"
        sw_col <- unname(sw_colors[r$symbolic_work_code[[1]]]); if (is.na(sw_col)) sw_col <- "#b8c7d8"
        w <- if (max_combo_n > 0) round(100 * r$n[[1]] / max_combo_n, 1) else 0
        label <- sprintf("%s - %d (%.1f%%)", r$combo_text[[1]], r$n[[1]], r$pct[[1]])
        tg_code <- js_escape(r$temporal_grammar_code[[1]])
        sw_code <- js_escape(r$symbolic_work_code[[1]])
        from_i <- fmt_date(r$first_date[[1]])
        to_i <- fmt_date(r$last_date[[1]])
        sid_i <- js_escape(r$first_speech_id[[1]])
        style_i <- sprintf(
          "background:linear-gradient(90deg,%s 0%%,%s 48%%,%s 52%%,%s 100%%);background-size:%s%% 100%%;background-repeat:no-repeat;background-color:#eef3f8;border:1px solid #c7d3e1;border-radius:999px;padding:7px 11px;font-size:.88rem;font-weight:700;line-height:1.25;color:#1d2935;cursor:pointer;width:100%%;text-align:left;",
          add_alpha(tg_col, "88"), add_alpha(tg_col, "88"), add_alpha(sw_col, "88"), add_alpha(sw_col, "88"), w
        )
        div(
          style = "margin-bottom:6px;",
          tags$button(
            type = "button",
            style = style_i,
            onclick = sprintf("Shiny.setInputValue('speaker_modal_action',{type:'combo',speaker:'%s',tg:'%s',sw:'%s',from:'%s',to:'%s',speech_id:'%s'},{priority:'event'})", sp_js, tg_code, sw_code, from_i, to_i, sid_i),
            label
          )
        )
      })
    }

    showModal(
      modalDialog(
        title = paste0("Speaker profile: ", prof$speaker_name),
        easyClose = TRUE,
        size = "xl",
        footer = modalButton("Close"),
        tags$div(
          style = "font-size:0.95rem;line-height:1.45;",
          tags$div(
            style = "display:grid;grid-template-columns:minmax(300px,430px) 1fr;gap:14px;align-items:start;",
            tags$div(
              tags$p(style = "margin:0 0 8px 0;", tags$strong("Source: "), prof$source, " (", prof$match_status, ")"),
              tags$table(
                class = "table table-sm",
                style = "margin-bottom:8px;",
                tags$tbody(
                  tags$tr(tags$th("Name"), tags$td(prof$speaker_name)),
                  tags$tr(tags$th("Contribution date"), tags$td(prof$date)),
                  tags$tr(tags$th("Role at this contribution"), tags$td(prof$role)),
                  tags$tr(tags$th("Recorded affiliation"), tags$td(ifelse(prof$party == "government", "Not recorded", prof$party))),
                  if (!is.na(prof$capacity) && nzchar(prof$capacity)) tags$tr(tags$th("Speaking capacity"), tags$td(prof$capacity))
                )
              ),
              if (nzchar(prof$profile_url)) tags$p(style = "margin:0;", tags$a(href = prof$profile_url, target = "_blank", rel = "noopener noreferrer", paste0("More about ", prof$speaker_name, " on Parlement.com")))
            ),
            tags$div(
              tags$p(style = "margin:0 0 8px 0;font-weight:700;", "Speaker profile in this dataset"),
              tags$div(
                style = "display:flex;flex-wrap:wrap;gap:8px;margin-bottom:10px;",
                summary_buttons
              ),
              if (stats$n_current > 0 && stats$n_current != stats$n_total) {
                tags$p(
                  style = "margin:0 0 8px 0;color:#4d5a66;",
                  paste0(
                    "In current speech list: ", stats$n_current,
                    " (", format(stats$first_current, "%Y-%m-%d"), " to ", format(stats$last_current, "%Y-%m-%d"), ")"
                  )
                )
              },
              tags$p(style = "margin:0 0 6px 0;font-weight:700;", "Coding combinations"),
              tags$div(style = "max-height:360px;overflow-y:auto;padding-right:3px;", combo_rows)
            )
          )
        )
      )
    )
  }

  clamp_period <- function(start_date, end_date) {
    s <- as.Date(start_date)
    e <- as.Date(end_date)
    if (is.na(s)) s <- min_date
    if (is.na(e)) e <- max_date
    s <- max(s, min_date)
    e <- min(e, max_date)
    if (s > e) {
      tmp <- s; s <- e; e <- tmp
    }
    c(s, e)
  }

  clear_speaker_filter <- function() {
    if (!is.null(rv$speaker_filter) && nzchar(trimws(rv$speaker_filter))) {
      rv$speaker_filter <- NULL
    }
  }

  as_date_input <- function(x) {
    if (inherits(x, "Date")) return(x)
    if (inherits(x, "POSIXt")) return(as.Date(x))
    if (is.numeric(x)) return(as.Date(x, origin = "1970-01-01"))
    as.Date(x)
  }

  sync_controls <- function(start_date, end_date) {
    d <- clamp_period(start_date, end_date)
    rv$period_start <- d[1]
    rv$period_end <- d[2]
    if (!is.null(input$period_years) && length(input$period_years) == 2) {
      cur <- as_date_input(input$period_years)
      tgt <- as_date_input(c(d[1], d[2]))
      if (length(cur) != 2 || any(is.na(cur)) || !identical(cur, tgt)) {
        updateSliderInput(session, "period_years", value = tgt)
      }
    }
  }

  observeEvent(input$open_manual_dates, {
    showModal(
      modalDialog(
        title = "Manual Time Selection",
        easyClose = TRUE,
        footer = tagList(
          modalButton("Cancel"),
          actionButton("apply_manual_dates", "Apply", class = "btn btn-primary")
        ),
        layout_columns(
          col_widths = c(6, 6),
          dateInput(
            "manual_date_start",
            "Start",
            value = rv$period_start,
            min = min_date,
            max = max_date,
            format = "dd-mm-yyyy",
            weekstart = 1
          ),
          dateInput(
            "manual_date_end",
            "End",
            value = rv$period_end,
            min = min_date,
            max = max_date,
            format = "dd-mm-yyyy",
            weekstart = 1
          )
        )
      )
    )
  }, ignoreInit = TRUE)

  observeEvent(input$apply_manual_dates, {
    req(input$manual_date_start, input$manual_date_end)
    clear_speaker_filter()
    sync_controls(input$manual_date_start, input$manual_date_end)
    removeModal()
  }, ignoreInit = TRUE)

  observeEvent(input$reset_period_selection, {
    clear_speaker_filter()
    sync_controls(min_date, max_date)
  }, ignoreInit = TRUE)

  observeEvent(input$period_years, {
    req(input$period_years, length(input$period_years) == 2)
    recent_modal_action <- !is.na(rv$last_speaker_modal_action) &&
      is.finite(as.numeric(difftime(Sys.time(), rv$last_speaker_modal_action, units = "secs"))) &&
      as.numeric(difftime(Sys.time(), rv$last_speaker_modal_action, units = "secs")) < 1
    if (!recent_modal_action) clear_speaker_filter()
    d <- sort(as_date_input(input$period_years))
    if (any(is.na(d))) return()
    sync_controls(
      d[1],
      d[2]
    )
  }, ignoreInit = TRUE)

  period_data <- reactive({
    df_dash %>% filter(date >= rv$period_start, date <= rv$period_end)
  })

  current_parties <- reactive({
    parties <- sort(unique(period_data()$party_clean))
    gov_idx <- which(tolower(parties) == "government")
    if (length(gov_idx)) {
      parties <- c(parties[-gov_idx], parties[gov_idx])
    }
    parties
  })

  observe({
    parties <- current_parties()
    selected_now <- isolate(rv$party_selected)
    selected_new <- intersect(selected_now, parties)
    if (length(selected_new) == 0 && length(parties) > 0) selected_new <- parties
    rv$party_selected <- selected_new
  })

  output$party_filter_buttons <- renderUI({
    parties <- current_parties()
    if (!length(parties)) return(div(class = "helper-text", "No parties in current period."))

    btns <- lapply(parties, function(p) {
      cls <- if (p %in% rv$party_selected) "party-chip-btn is-on" else "party-chip-btn is-off"
      p_js <- gsub("'", "\\\\'", p, fixed = TRUE)
      tags$button(
        type = "button",
        class = cls,
        onclick = sprintf("Shiny.setInputValue('party_toggle','%s',{priority:'event'})", p_js),
        p
      )
    })
    div(class = "party-chips", btns)
  })

  observeEvent(input$party_select_all, {
    clear_speaker_filter()
    rv$party_selected <- current_parties()
  }, ignoreInit = TRUE)

  observeEvent(input$party_deselect_all, {
    clear_speaker_filter()
    rv$party_selected <- character(0)
  }, ignoreInit = TRUE)

  observeEvent(input$party_toggle, {
    req(input$party_toggle)
    clear_speaker_filter()
    p <- as.character(input$party_toggle)
    parties <- current_parties()
    if (!p %in% parties) return()
    if (p %in% rv$party_selected) {
      rv$party_selected <- setdiff(rv$party_selected, p)
    } else {
      rv$party_selected <- c(rv$party_selected, p)
    }
  }, ignoreInit = TRUE)

  filtered_data <- reactive({
    sel <- rv$party_selected
    if (is.null(sel) || !length(sel)) return(period_data()[0, , drop = FALSE])
    period_data() %>% filter(party_clean %in% sel)
  })

  filtered_data_codes <- reactive({
    x <- filtered_data()
    if (!is.null(rv$speaker_filter) && nzchar(rv$speaker_filter)) {
      x <- x %>% filter(trimws(as.character(speaker)) == rv$speaker_filter)
    }
    if (!is.null(rv$tg_filter)) x <- x %>% filter(temporal_grammar_code == rv$tg_filter)
    if (!is.null(rv$sw_filter)) x <- x %>% filter(symbolic_work_code == rv$sw_filter)
    x
  })

  combo_distribution_df <- reactive({
    x <- filtered_data_codes()
    if (!nrow(x)) {
      return(tibble(
        combo = character(0), tg_code = character(0), sw_code = character(0),
        tg_word = character(0), sw_word = character(0), n = integer(0), pct = numeric(0),
        pct_label = character(0), bar_fill_color = character(0), line_color = character(0),
        line_width = numeric(0), hover_text = character(0)
      ))
    }

    total_n <- nrow(x)
    out <- x %>%
      transmute(
        tg_code = temporal_grammar_code,
        sw_code = symbolic_work_code,
        combo = paste(temporal_grammar_code, symbolic_work_code, sep = " + ")
      ) %>%
      mutate(
        tg_word = ifelse(is.na(unname(tg_labels[tg_code])), tg_code, unname(tg_labels[tg_code])),
        sw_word = ifelse(is.na(unname(sw_labels[sw_code])), sw_code, unname(sw_labels[sw_code]))
      ) %>%
      count(combo, tg_code, sw_code, tg_word, sw_word, name = "n") %>%
      arrange(desc(n), combo) %>%
      slice_head(n = 5L) %>%
      mutate(
        pct = 100 * n / total_n,
        pct_label = sprintf("%.1f%%", pct)
      )

    line_color <- if (is.null(rv$combo_filter)) {
      rep("#c6cfda", nrow(out))
    } else {
      ifelse(out$combo == rv$combo_filter, "#1d3557", "#d8dee6")
    }
    line_width <- if (is.null(rv$combo_filter)) {
      rep(1, nrow(out))
    } else {
      ifelse(out$combo == rv$combo_filter, 2.2, 1)
    }

    out <- out %>%
      mutate(
        bar_fill_color = ifelse(
          is.null(rv$combo_filter),
          "rgba(120,141,167,0.55)",
          ifelse(combo == rv$combo_filter, "rgba(56,92,136,0.78)", "rgba(160,176,195,0.35)")
        ),
        line_color = line_color,
        line_width = line_width,
        hover_text = sprintf(
          "TG: %s (%s)<br>SW: %s (%s)<br>Speeches: %s<br>Share in selection: %s",
          tg_code, tg_word, sw_code, sw_word, format(n, big.mark = ","), pct_label
        )
      )
    out
  })

  output$combo_axis_buttons <- renderUI({
    dd <- combo_distribution_df()
    if (!nrow(dd)) return(NULL)

    cols <- lapply(seq_len(nrow(dd)), function(i) {
      tg_col <- unname(tg_colors[dd$tg_code[[i]]]); if (is.na(tg_col)) tg_col <- "#9bb7d0"
      sw_col <- unname(sw_colors[dd$sw_code[[i]]]); if (is.na(sw_col)) sw_col <- "#b8c7d8"

      sw_style <- sprintf(
        "background:%s;border-color:%s;color:%s;",
        add_alpha(sw_col, "55"), sw_col, "#1d2935"
      )
      tg_style <- sprintf(
        "background:%s;border-color:%s;color:%s;",
        add_alpha(tg_col, "55"), tg_col, "#1d2935"
      )

      div(
        class = "intro-combo-axis-col",
        span(
          class = "list-code-badge intro-combo-axis-badge",
          style = sw_style,
          title = paste0(dd$sw_code[[i]], " - ", dd$sw_word[[i]]),
          dd$sw_word[[i]]
        ),
        span(
          class = "list-code-badge intro-combo-axis-badge",
          style = tg_style,
          title = paste0(dd$tg_code[[i]], " - ", dd$tg_word[[i]]),
          dd$tg_word[[i]]
        )
      )
    })

      div(
        class = "intro-combo-axis",
        div(
          class = "intro-combo-axis-grid",
          style = sprintf("grid-template-columns:repeat(%d,minmax(0,1fr));", nrow(dd)),
          cols
        )
      )
  })

  observe({
    combos_now <- filtered_data_codes() %>%
      transmute(combo = paste(temporal_grammar_code, symbolic_work_code, sep = " + ")) %>%
      pull(combo) %>%
      unique()
    if (!is.null(rv$combo_filter) && !rv$combo_filter %in% combos_now) {
      rv$combo_filter <- NULL
    }
  })

  observeEvent(plotly::event_data("plotly_click", source = "combo_selection_chart"), {
    cl <- plotly::event_data("plotly_click", source = "combo_selection_chart")
    if (is.null(cl)) return()
    clicked <- trimws(ifelse(is.null(cl$key), "", as.character(cl$key[[1]])))
    if (!nzchar(clicked) && !is.null(cl$x) && length(cl$x)) clicked <- trimws(as.character(cl$x[[1]]))
    if (!nzchar(clicked)) return()
    clear_speaker_filter()
    if (identical(rv$combo_filter, clicked)) {
      rv$combo_filter <- NULL
    } else {
      rv$combo_filter <- clicked
    }
  }, ignoreInit = TRUE)

  output$combo_selection_plotly <- plotly::renderPlotly({
    dd <- combo_distribution_df()
    if (!nrow(dd)) {
      p_empty <- plotly::plot_ly(source = "combo_selection_chart") %>%
        plotly::layout(
          xaxis = list(visible = FALSE, fixedrange = TRUE),
          yaxis = list(visible = FALSE, fixedrange = TRUE),
          annotations = list(list(
            x = 0.5, y = 0.5, xref = "paper", yref = "paper",
            text = "No combinations available for current selection.",
            showarrow = FALSE,
            font = list(size = 12, color = "#5f6c79")
          )),
          margin = list(l = 10, r = 10, t = 10, b = 10),
          plot_bgcolor = "rgba(0,0,0,0)",
          paper_bgcolor = "rgba(0,0,0,0)"
        ) %>%
        plotly::config(displayModeBar = FALSE, responsive = TRUE)
      return(p_empty %>% plotly::event_register("plotly_click"))
    }

    y_max <- max(dd$n, na.rm = TRUE)
    if (!is.finite(y_max) || y_max <= 0) y_max <- 1

    p <- plotly::plot_ly(
      data = dd,
      source = "combo_selection_chart",
      x = ~combo,
      y = ~n,
      key = ~combo,
      type = "bar",
      text = ~pct_label,
      textposition = "outside",
      cliponaxis = FALSE,
      hovertext = ~hover_text,
      hoverinfo = "text",
      marker = list(
        color = I(dd$bar_fill_color),
        line = list(color = I(dd$line_color), width = I(dd$line_width))
      ),
      showlegend = FALSE
    ) %>%
      plotly::layout(
        bargap = 0.18,
        showlegend = FALSE,
        margin = list(l = 56, r = 8, t = 8, b = 34),
        xaxis = list(
          title = "",
          showticklabels = FALSE,
          ticks = "",
          automargin = TRUE,
          categoryorder = "array",
          categoryarray = dd$combo,
          fixedrange = TRUE
        ),
        yaxis = list(
          title = "Nr of speeches",
          rangemode = "tozero",
          range = c(0, y_max * 1.25),
          automargin = TRUE,
          fixedrange = TRUE
        ),
        plot_bgcolor = "rgba(0,0,0,0)",
        paper_bgcolor = "rgba(0,0,0,0)"
      ) %>%
      plotly::config(displayModeBar = FALSE, responsive = TRUE)

    p %>% plotly::event_register("plotly_click")
  })

  output$legend_tg_ui <- renderUI({
    tg_item <- function(code, desc) {
      col <- unname(tg_colors[code]); if (is.na(col)) col <- "#9bb7d0"
      cls <- if (!is.null(rv$tg_filter) && identical(rv$tg_filter, code)) {
        "mini-chip-btn is-selected"
      } else if (!is.null(rv$tg_filter)) {
        "mini-chip-btn is-faded"
      } else {
        "mini-chip-btn"
      }
      div(
        class = "legend-item",
        actionButton(
          inputId = paste0("legend_tg_", code),
          label = tg_labels[[code]],
          class = cls,
          style = sprintf("background:%s;border-color:%s;", add_alpha(col, "88"), col)
        ),
        span(class = "legend-desc", desc)
      )
    }
    tagList(
      tg_item("TG1", "Past and present linked as a stable line."),
      tg_item("TG2", "Present framed as recurrence of an earlier pattern."),
      tg_item("TG3", "Rupture from prior trajectory."),
      tg_item("TG4", "Temporal conflict over direction and timing.")
    )
  })

  output$legend_sw_ui <- renderUI({
    sw_item <- function(code, desc) {
      col <- unname(sw_colors[code]); if (is.na(col)) col <- "#b8c7d8"
      cls <- if (!is.null(rv$sw_filter) && identical(rv$sw_filter, code)) {
        "mini-chip-btn is-selected"
      } else if (!is.null(rv$sw_filter)) {
        "mini-chip-btn is-faded"
      } else {
        "mini-chip-btn"
      }
      div(
        class = "legend-item",
        actionButton(
          inputId = paste0("legend_sw_", code),
          label = sw_labels[[code]],
          class = cls,
          style = sprintf("background:%s;border-color:%s;", add_alpha(col, "88"), col)
        ),
        span(class = "legend-desc", desc)
      )
    }
    tagList(
      sw_item("SW1", "Justify authority or policy."),
      sw_item("SW2", "Distinguish from opponents."),
      sw_item("SW3", "Define collective belonging."),
      sw_item("SW4", "Evaluate actors through ethical memory claims."),
      sw_item("SW5", "Residual category outside the four main framings.")
    )
  })

  lapply(names(tg_labels), function(code) {
    observeEvent(input[[paste0("legend_tg_", code)]], {
      clear_speaker_filter()
      rv$tg_filter <- if (identical(rv$tg_filter, code)) NULL else code
      rv$combo_filter <- NULL
    }, ignoreInit = TRUE)
  })

  lapply(names(sw_labels), function(code) {
    observeEvent(input[[paste0("legend_sw_", code)]], {
      clear_speaker_filter()
      rv$sw_filter <- if (identical(rv$sw_filter, code)) NULL else code
      rv$combo_filter <- NULL
    }, ignoreInit = TRUE)
  })

  observeEvent(input$open_tg_info, {
    tg_modal_item <- function(code, text) {
      tags$div(
        style = "display:flex;align-items:center;gap:8px;margin:6px 0;",
        tags$span(
          class = "mini-chip-btn",
          style = paste0(
            "background:", add_alpha(unname(tg_colors[code]), "88"),
            ";border-color:", unname(tg_colors[code]),
            ";cursor:default;margin-right:8px;"
          ),
          ifelse(is.na(unname(tg_labels[code])), code, unname(tg_labels[code]))
        ),
        tags$span(text)
      )
    }

    showModal(
      modalDialog(
        title = "Temporal Grammar: definition and categories",
        easyClose = TRUE,
        size = "l",
        footer = modalButton("Close"),
        tags$p(
          "In this project, temporal grammar specifies how a speech episode links the canonical seventeenth-century past to present and future."
        ),
        tags$p(
          "It captures the temporal operation of the mnemonic trope: the structure of past-present-future relations asserted in parliamentary argument."
        ),
        tags$div(
          tg_modal_item("TG1", "Past and present are linked as an ongoing line or stable national trajectory."),
          tg_modal_item("TG2", "The present is framed as recurrence, restoration, or return to an earlier pattern."),
          tg_modal_item("TG3", "The speech asserts rupture or discontinuity from prior trajectories."),
          tg_modal_item("TG4", "Time itself is politicised as conflict over direction, pace, and authority to define historical meaning.")
        )
      )
    )
  }, ignoreInit = TRUE)

  observeEvent(input$open_sw_info, {
    sw_modal_item <- function(code, text) {
      tags$div(
        style = "display:flex;align-items:center;gap:8px;margin:6px 0;",
        tags$span(
          class = "mini-chip-btn",
          style = paste0(
            "background:", add_alpha(unname(sw_colors[code]), "88"),
            ";border-color:", unname(sw_colors[code]),
            ";cursor:default;margin-right:8px;"
          ),
          ifelse(is.na(unname(sw_labels[code])), code, unname(sw_labels[code]))
        ),
        tags$span(text)
      )
    }

    showModal(
      modalDialog(
        title = "Symbolic Work: definition and categories",
        easyClose = TRUE,
        size = "l",
        footer = modalButton("Close"),
        tags$p(
          "In this project, symbolic work identifies what parliamentary action a temporal claim performs once the trope is mobilised."
        ),
        tags$p(
          "It captures the function of the linkage in interaction, for example legitimation, competition, boundary drawing, or moral evaluation."
        ),
        tags$div(
          sw_modal_item("SW1", "Uses the trope to justify authority, policy direction, or governmental competence."),
          sw_modal_item("SW2", "Uses the trope to distinguish, attack, or out-position political opponents."),
          sw_modal_item("SW3", "Uses the trope to define who belongs, who does not, and what counts as the nation."),
          sw_modal_item("SW4", "Uses the trope to evaluate actors through ethical memory claims, responsibility, pride, shame, or redress."),
          sw_modal_item("SW5", "Residual category outside the four main symbolic-work categories.")
        )
      )
    )
  }, ignoreInit = TRUE)

  observeEvent(input$open_dashboard_help, {
    showModal(
      modalDialog(
        title = "How To Use This Panel",
        easyClose = TRUE,
        footer = modalButton("Close"),
        tags$p(
          "Click on the coloured ",
          tags$strong("coding buttons"),
          " to highlight the corresponding evidence for temporal grammar or symbolic work in the text below. Click multiple times so all evidence snippets for the code are highlighted consecutively."
        ),
        tags$p(
          "Click on the ",
          tags$strong("date"),
          " to link to original website of governmental and parliamentary data (for speeches after 1995 it directly jumps to the debate from which the speech was extracted)."
        ),
        tags$p(
          "Click on the ",
          tags$strong("name"),
          " to see how the speaker features in our data of \"Golden Age\" politics."
        ),
        tags$p(
          "Click on the ",
          tags$strong("party button"),
          " to get background information about the party."
        )
      )
    )
  }, ignoreInit = TRUE)

  observeEvent(input$open_draft_paper, {
    pdf_file <- detect_draft_pdf()
    if (is.null(pdf_file) || !file.exists(file.path(getwd(), pdf_file))) {
      showModal(
        modalDialog(
          title = "Draft paper (PDF)",
          easyClose = TRUE,
          footer = modalButton("Close"),
          tags$p("No PDF found in the dashboard folder."),
          tags$p("Place your file in this folder and rename it to ", tags$code("draft_paper.pdf"), " for deterministic loading."),
          tags$p(tags$code(normalizePath(getwd(), winslash = "/")))
        )
      )
      return()
    }

    pdf_src <- paste0("localdocs/", utils::URLencode(pdf_file, reserved = TRUE))
    showModal(
      modalDialog(
        title = paste0("Draft paper: ", pdf_file),
        easyClose = TRUE,
        size = "xl",
        footer = modalButton("Close"),
        tags$script(HTML(
          "setTimeout(function(){var d=document.querySelector('#shiny-modal .modal-dialog');if(d){d.classList.add('draft-pdf-dialog');}},0);"
        )),
        div(
          class = "draft-pdf-viewer-wrap",
          tags$iframe(
            class = "draft-pdf-viewer",
            src = pdf_src,
            title = "Draft paper PDF viewer"
          )
        )
      )
    )
  }, ignoreInit = TRUE)

  timeline_year_df <- reactive({
    base_df <- df_dash
    years <- seq(year_min, year_max)

    out <- tibble(year = years) %>%
      left_join(base_df %>% count(year, name = "n"), by = "year") %>%
      mutate(
        n = ifelse(is.na(n), 0L, as.integer(n))
      )
    out
  })

  output$timeline_plotly <- plotly::renderPlotly({
    dd <- timeline_year_df()
    req(nrow(dd) > 0)

    start_year_sel <- max(year_min, as.integer(format(rv$period_start, "%Y")))
    end_year_sel <- min(year_max, as.integer(format(rv$period_end, "%Y")))
    x_ticks <- sort(unique(c(seq(year_min, year_max, by = 5), year_max)))
    y_max <- max(dd$n, na.rm = TRUE)
    if (!is.finite(y_max) || y_max <= 0) y_max <- 1

    p <- plotly::plot_ly(
      dd,
      x = ~year,
      y = ~n,
      type = "scatter",
      mode = "lines+markers",
      source = "timeline_line",
      customdata = ~n,
      hovertemplate = "%{x}: %{customdata} speeches<extra></extra>",
      line = list(color = "#2f67a6", width = 3, shape = "linear"),
      marker = list(size = 4, color = "#2f67a6")
    ) %>%
      plotly::layout(
        margin = list(l = 8, r = 12, t = 2, b = 0),
        hovermode = "closest",
        shapes = list(
          list(
            type = "rect",
            xref = "x",
            yref = "paper",
            x0 = start_year_sel - 0.5,
            x1 = end_year_sel + 0.5,
            y0 = 0,
            y1 = 1,
            fillcolor = "rgba(255,232,161,0.28)",
            line = list(width = 0),
            layer = "below"
          )
        ),
        xaxis = list(
          title = "",
          range = c(year_min - 0.35, year_max + 0.35),
          tickmode = "array",
          tickvals = x_ticks,
          ticktext = as.character(x_ticks),
          showgrid = FALSE,
          zeroline = FALSE,
          ticks = "outside"
        ),
        yaxis = list(
          title = "",
          range = c(0, y_max * 1.08),
          rangemode = "tozero",
          showgrid = FALSE,
          zeroline = FALSE,
          showticklabels = FALSE
        )
      ) %>%
      plotly::config(displayModeBar = FALSE, responsive = TRUE)

    p %>%
      plotly::event_register("plotly_click")
  })

  observeEvent(plotly::event_data("plotly_click", source = "timeline_line"), {
    cl <- plotly::event_data("plotly_click", source = "timeline_line")
    if (is.null(cl) || is.null(cl$x) || !length(cl$x)) return()
    clear_speaker_filter()
    y_click <- suppressWarnings(as.integer(round(as.numeric(cl$x[[1]]))))
    if (is.na(y_click)) return()
    y_click <- max(year_min, min(year_max, y_click))
    sync_controls(
      as.Date(sprintf("%d-01-01", y_click)),
      as.Date(sprintf("%d-12-31", y_click))
    )
  }, ignoreInit = TRUE)

  selected_pool <- reactive({
    x <- filtered_data_codes()
    if (!is.null(rv$combo_filter)) {
      x <- x %>% filter(paste(temporal_grammar_code, symbolic_work_code, sep = " + ") == rv$combo_filter)
    }
    x %>% arrange(date)
  })

  observe({
    pool <- selected_pool()
    if (!nrow(pool)) return()
    if (!rv$selected_speech_id %in% pool$speech_id) rv$selected_speech_id <- pool$speech_id[[1]]
  })

  observeEvent(selected_speech(), {
    sp <- selected_speech()
    sid <- if (is.null(sp)) "" else as.character(sp$speech_id[[1]])
    if (!identical(rv$evidence_speech_id, sid)) {
      rv$evidence_speech_id <- sid
      rv$evidence_active_type <- "none"
      rv$evidence_tg_idx <- 1L
      rv$evidence_sw_idx <- 1L
    }
  }, ignoreInit = FALSE)

  make_speech_link <- function(speech_id, date_value, source_file = NA_character_) {
    make_search_url <- function(query, scope = c("historisch", "parlementair")) {
      scope <- match.arg(scope)
      q <- URLencode(trimws(ifelse(is.na(query), "", as.character(query))), reserved = TRUE)
      paste0("https://zoek.officielebekendmakingen.nl/uitgebreidzoeken/", scope, "?zoek=", q)
    }

    extract_source_token <- function(x) {
      x <- trimws(ifelse(is.na(x), "", as.character(x)))
      if (!nzchar(x)) return("")
      tok <- basename(x)
      tok <- sub("\\.xml$", "", tok, ignore.case = TRUE, perl = TRUE)
      trimws(tok)
    }

    to_official_doc_url <- function(x) {
      x <- trimws(ifelse(is.na(x), "", as.character(x)))
      if (!nzchar(x)) return(NA_character_)

      # Already an external URL in the dataset.
      if (grepl("^https?://", x, ignore.case = TRUE, perl = TRUE)) {
        # Prefer the HTML reader page over raw XML when possible.
        if (grepl("zoek\\.officielebekendmakingen\\.nl", x, ignore.case = TRUE, perl = TRUE)) {
          x <- sub("\\.xml($|\\?)", ".html\\1", x, ignore.case = TRUE, perl = TRUE)
        }
        return(x)
      }

      # Convert internal file path conventions to document ids.
      id <- extract_source_token(x)
      id <- sub("^nl\\.proc\\.sgd\\.d\\.", "", id, ignore.case = TRUE, perl = TRUE)
      id <- sub("^nl\\.proc\\.ob\\.d\\.", "", id, ignore.case = TRUE, perl = TRUE)
      id <- sub("^nl\\.proc\\.[^.]+\\.d\\.", "", id, ignore.case = TRUE, perl = TRUE)
      id <- trimws(id)
      if (!nzchar(id)) return(NA_character_)

      # Known official document-id styles seen in this corpus.
      if (grepl("^[0-9]{8,}$", id, perl = TRUE)) {
        return(paste0("https://zoek.officielebekendmakingen.nl/", id, ".html"))
      }
      if (grepl("^(h-tk|ah-tk|h-ek|h-vv|kst)-", tolower(id), perl = TRUE)) {
        return(paste0("https://zoek.officielebekendmakingen.nl/", id, ".html"))
      }

      NA_character_
    }

    src <- trimws(ifelse(is.na(source_file), "", as.character(source_file)))
    src_token <- extract_source_token(src)

    # Older SGD files are best opened through historical search using a rich query.
    if (nzchar(src_token) && grepl("^nl\\.proc\\.sgd\\.d\\.", src_token, ignore.case = TRUE, perl = TRUE)) {
      sgd_num <- sub("^nl\\.proc\\.sgd\\.d\\.([0-9]{8,}).*$", "\\1", src_token, ignore.case = TRUE, perl = TRUE)
      mapped <- sgd_docid_map %>% filter(sgd_key == sgd_num) %>% pull(docid10)
      if (length(mapped) >= 1 && grepl("^[0-9]{10}$", mapped[[1]], perl = TRUE)) {
        return(paste0("https://zoek.officielebekendmakingen.nl/", mapped[[1]]))
      }
      sid_full <- trimws(ifelse(is.na(speech_id), "", as.character(speech_id)))
      q_parts <- c(
        ifelse(grepl("^[0-9]{8,}$", sgd_num, perl = TRUE), sgd_num, ""),
        src_token,
        sid_full
      )
      q <- paste(unique(q_parts[nzchar(q_parts)]), collapse = " ")
      return(make_search_url(q, scope = "historisch"))
    }

    url_from_src <- to_official_doc_url(src)
    if (!is.na(url_from_src) && nzchar(url_from_src)) {
      return(url_from_src)
    }

    d <- as.Date(date_value)
    scope <- if (!is.na(d) && d < as.Date("1995-01-01")) "historisch" else "parlementair"
    sid <- trimws(ifelse(is.na(speech_id), "", as.character(speech_id)))
    if (nzchar(sid)) {
      if (grepl("^nl\\.proc\\.sgd\\.d\\.", sid, ignore.case = TRUE, perl = TRUE)) {
        doc_id_full <- sub("(nl\\.proc\\.sgd\\.d\\.[0-9]+).*$", "\\1", sid, ignore.case = TRUE, perl = TRUE)
        sgd_num <- sub("^nl\\.proc\\.sgd\\.d\\.([0-9]{8,}).*$", "\\1", doc_id_full, ignore.case = TRUE, perl = TRUE)
        mapped <- sgd_docid_map %>% filter(sgd_key == sgd_num) %>% pull(docid10)
        if (length(mapped) >= 1 && grepl("^[0-9]{10}$", mapped[[1]], perl = TRUE)) {
          return(paste0("https://zoek.officielebekendmakingen.nl/", mapped[[1]]))
        }
        q_parts <- c(
          ifelse(grepl("^[0-9]{8,}$", sgd_num, perl = TRUE), sgd_num, ""),
          doc_id_full,
          sid
        )
        q <- paste(unique(q_parts[nzchar(q_parts)]), collapse = " ")
        if (!identical(doc_id_full, sid) || grepl("^nl\\.proc\\.sgd\\.d\\.", doc_id_full, ignore.case = TRUE, perl = TRUE)) {
          return(make_search_url(q, scope = "historisch"))
        }
      }
      # Try to derive a direct document page from speech-level ids first.
      doc_id <- sub("\\.[0-9].*$", "", sid, perl = TRUE)
      direct_url <- to_official_doc_url(doc_id)
      if (!is.na(direct_url) && nzchar(direct_url)) {
        return(direct_url)
      }
      return(make_search_url(ifelse(nzchar(doc_id), doc_id, sid), scope = scope))
    }
    make_search_url(paste0(format(d, "%Y-%m-%d"), " tweede kamer"), scope = scope)
  }

  speech_table_data <- reactive({
    selected_pool() %>%
      mutate(
        speaker_safe = ifelse(is.na(speaker) | !nzchar(trimws(speaker)), "Unknown speaker", as.character(speaker)),
        speech_id_js = gsub("'", "\\\\'", as.character(speech_id), fixed = TRUE),
        speech_link = mapply(make_speech_link, speech_id, date, source_file, USE.NAMES = FALSE),
        party_link = vapply(as.character(party_clean), make_party_link, character(1)),
        party_full = ifelse(is.na(party_clean), "", as.character(party_clean)),
        party_short = ifelse(
          tolower(trimws(party_full)) == "government",
          "gov...",
          ifelse(
            nchar(party_full, type = "chars") > 8L,
          paste0(substr(party_full, 1L, 7L), "..."),
          party_full
          )
        )
      ) %>%
      transmute(
        speech_id,
        date = sprintf(
          "<a href=\"%s\" target=\"_blank\" rel=\"noopener noreferrer\"><span class='list-code-badge' style='background:%s;border-color:%s;'>%s</span></a>",
          htmlEscape(speech_link),
          "#eef3f8",
          "#c7d3e1",
          format(date, "%d-%m-%Y")
        ),
        speaker = sprintf(
          "<a href=\"#\" title=\"%s\" onclick=\"Shiny.setInputValue('speaker_modal_request','%s',{priority:'event'});return false;\"><span class='list-code-badge speaker-chip' style='background:%s;border-color:%s;' title=\"%s\">%s</span></a>",
          htmlEscape(speaker_safe, attribute = TRUE),
          speech_id_js,
          "#eef3f8",
          "#c7d3e1",
          htmlEscape(speaker_safe, attribute = TRUE),
          htmlEscape(speaker_safe)
        ),
        party = ifelse(
          nzchar(party_link),
          sprintf(
            "<a href=\"%s\" target=\"_blank\" rel=\"noopener noreferrer\" title=\"%s\"><span class='list-code-badge' style='background:%s;border-color:%s;' title=\"%s\">%s</span></a>",
            htmlEscape(party_link),
            htmlEscape(party_full, attribute = TRUE),
            "#eef3f8",
            "#c7d3e1",
            htmlEscape(party_full, attribute = TRUE),
            htmlEscape(party_short)
          ),
          sprintf(
            "<span class='list-code-badge' style='background:%s;border-color:%s;' title=\"%s\">%s</span>",
            "#eef3f8",
            "#c7d3e1",
            htmlEscape(party_full, attribute = TRUE),
            htmlEscape(party_short)
          )
        ),
        combo = paste0(
          "<span class='combo-stack'>",
          sprintf(
            "<span class='list-code-badge' style='background:%s;border-color:%s;'>%s</span>",
            add_alpha(unname(tg_colors[temporal_grammar_code]), "88"),
            unname(tg_colors[temporal_grammar_code]),
            ifelse(is.na(unname(tg_labels[temporal_grammar_code])), temporal_grammar_code, unname(tg_labels[temporal_grammar_code]))
          ),
          " ",
          sprintf(
            "<span class='list-code-badge' style='background:%s;border-color:%s;'>%s</span>",
            add_alpha(unname(sw_colors[symbolic_work_code]), "88"),
            unname(sw_colors[symbolic_work_code]),
            ifelse(is.na(unname(sw_labels[symbolic_work_code])), symbolic_work_code, unname(sw_labels[symbolic_work_code]))
          )
          , "</span>"
        )
      )
  })

  output$speech_list_label <- renderUI({
    n_sel <- nrow(selected_pool())
    div(
      class = "section-label-row",
      div(class = "section-label", sprintf("Selected Speech List (%d)", n_sel)),
      div(
        class = "section-tools",
        actionButton(
          "reset_all_selection",
          "reset selection",
          class = "manual-period-btn",
          style = "height:30px;min-height:30px;padding:4px 10px;font-size:.82rem;"
        )
      )
    )
  })

  output$speech_table <- renderDT({
    datatable(
      speech_table_data(),
      rownames = FALSE,
      selection = "single",
      escape = FALSE,
      options = list(
        scrollX = FALSE,
        paging = FALSE,
        dom = "t",
        autoWidth = FALSE,
        columnDefs = list(
          list(targets = 0, visible = FALSE),
          list(targets = 1, width = "84px", className = "dt-nowrap"),   # date
          list(targets = 2, width = "128px", className = "dt-nowrap"),  # speaker (15ch chip with tooltip)
          list(targets = 3, width = "44px", className = "dt-nowrap party-cell"),   # party (shortened + tooltip)
          list(targets = 4, width = "266px", className = "combo-cell")
        )
      )
    )
  })

  proxy <- dataTableProxy("speech_table")

  observe({
    tbl <- speech_table_data()
    if (!nrow(tbl)) {
      selectRows(proxy, NULL)
      return()
    }
    idx <- match(rv$selected_speech_id, tbl$speech_id)
    if (is.na(idx)) {
      rv$selected_speech_id <- tbl$speech_id[[1]]
      idx <- 1
    }
    selectRows(proxy, idx)
  })

  observeEvent(input$speech_table_rows_selected, {
    idx <- input$speech_table_rows_selected
    tbl <- speech_table_data()
    if (length(idx) == 1 && nrow(tbl) >= idx) rv$selected_speech_id <- tbl$speech_id[[idx]]
  })

  selected_speech <- reactive({
    pool <- selected_pool()
    if (!nrow(pool)) return(NULL)
    row <- pool %>% filter(speech_id == rv$selected_speech_id)
    if (!nrow(row)) row <- pool[1, , drop = FALSE]
    row[1, , drop = FALSE]
  })

  observeEvent(input$speaker_modal_request, {
    req(input$speaker_modal_request)
    sid <- as.character(input$speaker_modal_request)
    pool <- selected_pool()
    if (!nrow(pool)) return()
    sp <- pool %>% filter(speech_id == sid)
    if (!nrow(sp)) return()
    show_speaker_modal(sp[1, , drop = FALSE])
  }, ignoreInit = TRUE)

  observeEvent(input$speaker_modal_action, {
    act <- input$speaker_modal_action
    if (is.null(act) || is.null(act$type)) return()
    rv$last_speaker_modal_action <- Sys.time()

    type <- tolower(trimws(as.character(act$type)))
    spk <- trimws(ifelse(is.null(act$speaker), "", as.character(act$speaker)))
    if (nzchar(spk)) rv$speaker_filter <- spk

    if (type %in% c("speaker", "first", "last")) {
      rv$tg_filter <- NULL
      rv$sw_filter <- NULL
      rv$combo_filter <- NULL
    }

    if (identical(type, "combo")) {
      tg <- trimws(ifelse(is.null(act$tg), "", as.character(act$tg)))
      sw <- trimws(ifelse(is.null(act$sw), "", as.character(act$sw)))
      if (nzchar(tg)) rv$tg_filter <- tg
      if (nzchar(sw)) rv$sw_filter <- sw
      rv$combo_filter <- NULL
    }

    from_d <- suppressWarnings(as.Date(ifelse(is.null(act$from), "", as.character(act$from))))
    to_d <- suppressWarnings(as.Date(ifelse(is.null(act$to), "", as.character(act$to))))
    if (!is.na(from_d) && !is.na(to_d)) {
      sync_controls(from_d, to_d)
    } else if (!is.na(from_d)) {
      sync_controls(from_d, from_d)
    }

    # Auto-adjust party filter to the selected speaker within the active period.
    if (nzchar(spk)) {
      spk_parties <- df_dash %>%
        filter(
          trimws(as.character(speaker)) == spk,
          date >= rv$period_start,
          date <= rv$period_end
        ) %>%
        pull(party_clean) %>%
        unique() %>%
        sort()
      gov_idx <- which(tolower(spk_parties) == "government")
      if (length(gov_idx)) spk_parties <- c(spk_parties[-gov_idx], spk_parties[gov_idx])
      if (length(spk_parties)) rv$party_selected <- spk_parties
    }

    sid <- trimws(ifelse(is.null(act$speech_id), "", as.character(act$speech_id)))
    if (nzchar(sid)) rv$selected_speech_id <- sid

    removeModal()
  }, ignoreInit = TRUE)

  reset_selection_state <- function() {
    rv$last_speaker_modal_action <- as.POSIXct(NA)
    rv$speaker_filter <- NULL
    rv$tg_filter <- NULL
    rv$sw_filter <- NULL
    rv$combo_filter <- NULL
    sync_controls(min_date, max_date)

    parties <- sort(unique(df_dash$party_clean))
    gov_idx <- which(tolower(parties) == "government")
    if (length(gov_idx)) parties <- c(parties[-gov_idx], parties[gov_idx])
    rv$party_selected <- parties
    rv$evidence_active_type <- "none"
    rv$evidence_tg_idx <- 1L
    rv$evidence_sw_idx <- 1L

    pool_all <- df_dash %>% arrange(date)
    if (nrow(pool_all)) rv$selected_speech_id <- as.character(pool_all$speech_id[[1]])
  }

  observeEvent(input$reset_all_selection, {
    reset_selection_state()
  }, ignoreInit = TRUE)

  observeEvent(input$reset_selection_top, {
    reset_selection_state()
  }, ignoreInit = TRUE)

  make_party_link <- function(party) {
    p_raw <- trimws(ifelse(is.na(party), "", as.character(party)))
    p_key <- normalize_party_key(p_raw)
    if (!nzchar(p_key) || p_key == "government") return("")

    party_slug_map <- c(
      "arp" = "arp",
      "bbb" = "bbb",
      "bp" = "boerenpartij",
      "cd" = "cd",
      "cda" = "cda",
      "christenunie" = "christenunie",
      "chu" = "chu",
      "cpn" = "cpn",
      "d66" = "d66",
      "denk" = "denk",
      "ds70" = "ds70",
      "fvd" = "fvd",
      "gl" = "gl",
      "gpv" = "gpv",
      "groenlinks" = "groenlinks",
      "ja21" = "ja21",
      "knp" = "nu",
      "kvp" = "kvp",
      "lpf" = "lpf",
      "ppr" = "ppr",
      "psp" = "psp",
      "pvda" = "pvda",
      "pvdd" = "pvdd",
      "pvv" = "pvv",
      "rpf" = "rpf",
      "sgp" = "sgp",
      "sp" = "sp",
      "vvd" = "vvd",
      "groep bontes van klaveren" = "vnl",
      "groep van haga" = "bvnl",
      "groepvanoudenallen" = "50plus",
      "lid gundogan" = "volt"
    )

    base <- "https://www.rug.nl/research/dnpp/politieke-partijen/"
    slug <- unname(party_slug_map[p_key])
    if (length(slug) >= 1 && !is.na(slug[[1]]) && nzchar(slug[[1]])) {
      slug <- slug[[1]]
      return(paste0(base, slug, "/"))
    }

    paste0(base, "alle-index/?search=", URLencode(p_raw, reserved = TRUE))
  }

  output$speech_context_note <- renderUI({
    sp <- selected_speech()
    if (is.null(sp)) return(NULL)
    role_label <- speaker_role_label(sp$role[[1]])
    details <- c(role_label, sp$speaking_capacity[[1]], sp$sample_scope_note[[1]])
    group <- sp$parliamentary_group_as_recorded[[1]]
    if (!is.na(group) && nzchar(group)) details <- c(details, paste0("Parliamentary group as recorded: ", group))
    details <- unique(details[!is.na(details) & nzchar(details)])
    div(class = "helper-text", style = "margin:0 0 8px 0;", paste(details, collapse = " · "))
  })

  output$header_badges_row <- renderUI({
    sp <- selected_speech()
    if (is.null(sp)) return(div(class = "helper-text", "No speech matches the active filters."))
    sp_id_js <- gsub("'", "\\\\'", as.character(sp$speech_id[[1]]), fixed = TRUE)
    txt <- ifelse(is.na(sp$text[[1]]), "", sp$text[[1]])
    wc <- if (!nzchar(trimws(txt))) 0L else length(strsplit(trimws(txt), "\\s+")[[1]])
    tg <- sp$temporal_grammar_code[[1]]
    sw <- sp$symbolic_work_code[[1]]
    tg_tip <- ifelse(nzchar(trimws(sp$temporal_grammar_rationale[[1]])), sp$temporal_grammar_rationale[[1]], "No trajectory rationale available.")
    sw_tip <- ifelse(nzchar(trimws(sp$symbolic_work_rationale[[1]])), sp$symbolic_work_rationale[[1]], "No framing rationale available.")
    seed_toggle_style <- if (isTRUE(rv$show_seed_terms)) {
      paste0("cursor:pointer;background:", seed_highlight_color, ";border:1px solid #d8bf5a;color:#4a3f1b;")
    } else {
      "cursor:pointer;background:#f3f4f6;border:1px solid #d1d5db;color:#6b7280;"
    }
    party_link <- make_party_link(sp$party_clean[[1]])
    party_badge <- if (nzchar(party_link)) {
      tags$a(
        class = "combo-badge",
        href = party_link,
        target = "_blank",
        rel = "noopener noreferrer",
        sp$party_clean[[1]]
      )
    } else {
      span(class = "combo-badge combo-badge-neutral", sp$party_clean[[1]])
    }

    div(
      class = "header-badges-row",
      span(
        class = "combo-badge",
        title = tg_tip,
        onclick = "Shiny.setInputValue('jump_evidence','tg',{priority:'event'})",
        style = paste0("background:", add_alpha(tg_colors[[tg]], "88"), "; border:1px solid ", tg_colors[[tg]], ";"),
        tg_labels[[tg]]
      ),
      span(
        class = "combo-badge",
        title = sw_tip,
        onclick = "Shiny.setInputValue('jump_evidence','sw',{priority:'event'})",
        style = paste0("background:", add_alpha(sw_colors[[sw]], "88"), "; border:1px solid ", sw_colors[[sw]], ";"),
        sw_labels[[sw]]
      ),
      tags$a(
        class = "combo-badge",
        href = make_speech_link(sp$speech_id[[1]], sp$date[[1]], sp$source_file[[1]]),
        target = "_blank",
        rel = "noopener noreferrer",
        format(sp$date[[1]], "%d-%m-%Y")
      ),
      tags$a(
        class = "combo-badge",
        href = "#",
        onclick = sprintf("Shiny.setInputValue('speaker_modal_request','%s',{priority:'event'});return false;", sp_id_js),
        sp$speaker[[1]]
      ),
      party_badge,
      span(
        class = "combo-badge combo-badge-neutral",
        sprintf("%s words", format(wc, big.mark = ","))
      ),
      tags$button(
        type = "button",
        class = "combo-badge combo-badge-neutral",
        style = seed_toggle_style,
        onclick = "Shiny.setInputValue('toggle_seed_terms', Date.now(), {priority:'event'})",
        if (isTRUE(rv$show_seed_terms)) "dict on" else "dict off"
      ),
      tags$button(
        type = "button",
        class = "combo-badge combo-badge-neutral",
        style = "cursor:pointer;",
        onclick = "Shiny.setInputValue('open_dashboard_help', Date.now(), {priority:'event'})",
        "?"
      )
    )
  })

  observeEvent(input$toggle_seed_terms, {
    rv$show_seed_terms <- !isTRUE(rv$show_seed_terms)
  }, ignoreInit = TRUE)

  output$dutch_text <- renderUI({
    sp <- selected_speech()
    nl_style <- sprintf("font-size:%s%%;", as.integer(round(rv$dutch_zoom * 100)))
    if (is.null(sp)) return(div(class = "text-box text-box-dutch", style = nl_style, HTML("<em>No speech available under current filters.</em>")))

    tg <- sp$temporal_grammar_code[[1]]
    sw <- sp$symbolic_work_code[[1]]

    marked <- highlight_evidence(
      text = sp$text[[1]],
      tg_ev = sp$temporal_grammar_evidence[[1]],
      sw_ev = sp$symbolic_work_evidence[[1]],
      tg_col = tg_colors[[tg]],
      sw_col = sw_colors[[sw]],
      tg_title = ifelse(nzchar(trimws(sp$temporal_grammar_rationale[[1]])), sp$temporal_grammar_rationale[[1]], "No trajectory rationale available."),
      sw_title = ifelse(nzchar(trimws(sp$symbolic_work_rationale[[1]])), sp$symbolic_work_rationale[[1]], "No framing rationale available."),
      active_type = rv$evidence_active_type,
      tg_idx = rv$evidence_tg_idx,
      sw_idx = rv$evidence_sw_idx,
      show_seed_terms = isTRUE(rv$show_seed_terms)
    )

    div(
      class = "text-box text-box-dutch",
      id = "dutch_text_box",
      tabindex = "0",
      `data-speech-id` = sp$speech_id[[1]],
      style = nl_style,
      HTML(marked)
    )
  })

  observeEvent(input$jump_evidence, {
    req(input$jump_evidence)
    jump <- tolower(as.character(input$jump_evidence))
    if (!jump %in% c("tg", "sw")) return()

    sp <- selected_speech()
    if (!is.null(sp)) {
      sid <- as.character(sp$speech_id[[1]])
      if (!identical(rv$evidence_speech_id, sid)) {
        rv$evidence_speech_id <- sid
        rv$evidence_tg_idx <- 1L
        rv$evidence_sw_idx <- 1L
        rv$evidence_active_type <- "none"
      }

      text_raw <- ifelse(is.na(sp$text[[1]]), "", as.character(sp$text[[1]]))
      if (identical(jump, "tg")) {
        tg_raw <- ifelse(is.na(sp$temporal_grammar_evidence[[1]]), "", as.character(sp$temporal_grammar_evidence[[1]]))
        n_tg <- length(find_evidence_fragments(text_raw, tg_raw))
        if (!identical(rv$evidence_active_type, "tg")) {
          rv$evidence_tg_idx <- 1L
        } else if (n_tg > 0L) {
          rv$evidence_tg_idx <- ((as.integer(rv$evidence_tg_idx) %% n_tg) + 1L)
        } else {
          rv$evidence_tg_idx <- 1L
        }
        rv$evidence_active_type <- "tg"
      } else {
        sw_raw <- ifelse(is.na(sp$symbolic_work_evidence[[1]]), "", as.character(sp$symbolic_work_evidence[[1]]))
        n_sw <- length(find_evidence_fragments(text_raw, sw_raw))
        if (!identical(rv$evidence_active_type, "sw")) {
          rv$evidence_sw_idx <- 1L
        } else if (n_sw > 0L) {
          rv$evidence_sw_idx <- ((as.integer(rv$evidence_sw_idx) %% n_sw) + 1L)
        } else {
          rv$evidence_sw_idx <- 1L
        }
        rv$evidence_active_type <- "sw"
      }
    }

    session$onFlushed(function() {
      session$sendCustomMessage("scrollDutchEvidence", list(type = jump))
    }, once = TRUE)
  }, ignoreInit = TRUE)

  output$dutch_text_label <- renderUI({
    div(class = "section-label", "Dutch Text")
  })

  output$dutch_zoom_controls <- renderUI({
    div(
      class = "zoom-controls",
      div(
        class = "zoom-search-wrap",
        textInput("dutch_search", NULL, value = "", placeholder = "Search in Dutch text...")
      ),
      div(
        class = "zoom-left",
        actionButton("dutch_zoom_out", "-", class = "btn btn-outline-secondary btn-sm zoom-btn"),
        actionButton("dutch_zoom_in", "+", class = "btn btn-outline-secondary btn-sm zoom-btn"),
        actionButton("dutch_zoom_reset", "100%", class = "btn btn-outline-secondary btn-sm zoom-btn"),
        span(class = "zoom-level", sprintf("%d%%", as.integer(round(rv$dutch_zoom * 100)))),
        span(class = "zoom-text-label", "DUTCH TEXT OF SPEECH")
      )
    )
  })

  observeEvent(input$dutch_zoom_in, {
    rv$dutch_zoom <- min(2.2, rv$dutch_zoom + 0.1)
  }, ignoreInit = TRUE)

  observeEvent(input$dutch_zoom_out, {
    rv$dutch_zoom <- max(0.7, rv$dutch_zoom - 0.1)
  }, ignoreInit = TRUE)

  observeEvent(input$dutch_zoom_reset, {
    rv$dutch_zoom <- 1
  }, ignoreInit = TRUE)

  observeEvent(input$dutch_search, {
    session$sendCustomMessage("searchDutchText", list(query = input$dutch_search))
  }, ignoreInit = TRUE)

  output$english_text_label <- renderUI({
    div(class = "section-label", "English Translation of Selected Code Evidence")
  })

  output$english_text <- renderUI({
    sp <- selected_speech()
    sid <- if (is.null(sp)) "" else as.character(sp$speech_id[[1]])
    if (is.null(sp)) {
      return(
        div(
          class = "text-box text-box-english",
          id = "english_text_box",
          `data-speech-id` = sid,
          HTML("<em>No speech available under current filters.</em>")
        )
      )
    }

    ev <- get_active_evidence_info(
      sp_row = sp,
      active_type = rv$evidence_active_type,
      tg_idx = rv$evidence_tg_idx,
      sw_idx = rv$evidence_sw_idx
    )

    if (identical(ev$type, "none")) {
      return(
        div(
          class = "text-box text-box-english",
          id = "english_text_box",
          `data-speech-id` = sid,
          HTML("<em>Click a temporal grammar or symbolic work button above Dutch text to translate the selected evidence snippet.</em>")
        )
      )
    }

    if (!nzchar(trimws(ev$fragment))) {
      return(
        div(
          class = "text-box text-box-english",
          id = "english_text_box",
          `data-speech-id` = sid,
          HTML(sprintf("<em>No %s evidence snippet found in this speech text.</em>", ifelse(ev$type == "tg", "temporal grammar", "symbolic work")))
        )
      )
    }

    tr_text_raw <- get_translated_evidence_from_row(sp, ev)
    if (!nzchar(trimws(tr_text_raw))) {
      return(
        div(
          class = "text-box text-box-english",
          id = "english_text_box",
          `data-speech-id` = sid,
          HTML(paste0(
            "<p style='margin:0 0 8px 0;'><strong>Translation unavailable for this snippet</strong></p>",
            "<p style='margin:0 0 6px 0;'>No pretranslated text found in <code>df_snippets_translated.(rds/csv)</code> for this speech/snippet index.</p>",
            "<p style='margin:0;font-size:.82rem;color:#6b7785;'>Expected columns: <code>speech_id</code>, <code>temporal_grammar_sentences_en</code>, <code>symbolic_work_sentences_en</code>.</p>"
          ))
        )
      )
    }

    ev_label <- ifelse(ev$type == "tg", "Temporal grammar evidence", "Symbolic work evidence")
    ev_style <- sprintf("background-color:%s; border-radius:2px; padding:0 2px;", add_alpha(ev$color, "55"))
    ev_title <- htmlEscape(ifelse(is.null(ev$title), "", as.character(ev$title)), attribute = TRUE)
    tr_text <- htmlEscape(as.character(tr_text_raw))

    div(
      class = "text-box text-box-english",
      id = "english_text_box",
      `data-speech-id` = sid,
      HTML(paste0(
        "<p style='margin:0 0 8px 0;'><strong>", ev_label, " (", ev$index, "/", ev$total, ")</strong></p>",
        "<p style='margin:0;'><span class='evidence-mark evidence-", ev$type, "' style='", ev_style, "' title='", ev_title, "'>", tr_text, "</span></p>"
      ))
    )
  })

  outputOptions(output, "english_text", suspendWhenHidden = FALSE)
}

app <- shinyApp(ui, server)

# Start manually:
# runApp(app)
