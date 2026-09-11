import React, { useEffect, useMemo, useRef, useState } from "react";
import {
  CODES,
  TG,
  SW,
  ROLES,
  INITIAL,
  MIN_YEAR,
  MAX_YEAR,
  dateLabel,
  filterSpeeches,
  findRanges,
  foreground,
  matrixCounts,
  matrixStyle,
  normalized,
  number,
  researchCitation,
  textSegments,
  toggle,
  yearCounts,
} from "./domain.js";

export function Code({ id }) {
  const c = CODES[id];
  return (
    <span
      className="code"
      style={{ "--code-color": c.color, "--code-text": foreground(c.color) }}
      title={c.meaning}
    >
      <b>{id}</b>
      {c.short || c.label}
    </span>
  );
}
export function Arrow() {
  return <span aria-hidden="true">↗</span>;
}
export function OutLink({ href, children, ...props }) {
  return (
    <a href={href} target="_blank" rel="noopener noreferrer" {...props}>
      {children} <Arrow />
    </a>
  );
}
export function YearRange({ state, update }) {
  const [draft, setDraft] = useState([String(state.from), String(state.to)]);
  useEffect(
    () => setDraft([String(state.from), String(state.to)]),
    [state.from, state.to],
  );
  function commit(i) {
    const value = Number(draft[i]);
    if (!draft[i] || !Number.isInteger(value)) {
      setDraft([String(state.from), String(state.to)]);
      return;
    }
    const year = Math.max(MIN_YEAR, Math.min(MAX_YEAR, value));
    update(
      i === 0
        ? { from: Math.min(year, state.to), speech: "" }
        : { to: Math.max(year, state.from), speech: "" },
    );
  }
  return (
    <div className="year-inputs">
      {["From", "To"].map((label, i) => (
        <React.Fragment key={label}>
          {i > 0 && <span aria-hidden="true">—</span>}
          <label>
            {label}
            <input
              aria-label={i ? "Last year" : "First year"}
              type="number"
              min={MIN_YEAR}
              max={MAX_YEAR}
              value={draft[i]}
              onChange={(e) =>
                setDraft(draft.map((v, j) => (i === j ? e.target.value : v)))
              }
              onBlur={() => commit(i)}
              onKeyDown={(e) => {
                if (e.key === "Enter") e.currentTarget.blur();
              }}
            />
          </label>
        </React.Fragment>
      ))}
    </div>
  );
}
export function Filters({
  speeches,
  state,
  update,
  reset,
  active,
  mobileOpen,
  closeMobile,
}) {
  const [partySearch, setPartySearch] = useState("");
  const [speakerSearch, setSpeakerSearch] = useState("");
  const partyOptions = useMemo(
    () =>
      [...new Map(speeches.map((s) => [s.party, s.partyLabel]))].sort((a, b) =>
        a[1].localeCompare(b[1]),
      ),
    [speeches],
  );
  const people = useMemo(
    () =>
      [...new Map(speeches.map((s) => [s.speakerId, s.speaker]))].sort((a, b) =>
        a[1].localeCompare(b[1]),
      ),
    [speeches],
  );
  const facets = useMemo(() => {
    const result = {};
    for (const [dimension, field] of Object.entries({
      parties: "party",
      roles: "role",
      speakers: "speakerId",
      tg: "tg",
      sw: "sw",
    })) {
      result[dimension] = filterSpeeches(speeches, state, dimension).reduce(
        (counts, s) => {
          counts[s[field]] = (counts[s[field]] || 0) + 1;
          return counts;
        },
        {},
      );
    }
    return result;
  }, [speeches, state]);
  const shownPeople = people.filter(([id, name]) =>
    speakerSearch
      ? normalized(name).includes(normalized(speakerSearch))
      : state.speakers.includes(id),
  );
  function option(dimension, id, label, color) {
    return (
      <label className="check-option" key={id}>
        <input
          type="checkbox"
          checked={state[dimension].includes(id)}
          onChange={() =>
            update({ [dimension]: toggle(state[dimension], id), speech: "" })
          }
        />
        {color && (
          <span
            className="color-swatch"
            style={{ background: color }}
            aria-hidden="true"
          />
        )}
        <span>{label}</span>
        <small>{facets[dimension][id] || 0}</small>
      </label>
    );
  }
  return (
    <aside
      className={`filter-panel ${mobileOpen ? "mobile-open" : ""}`}
      aria-label="Filter speeches"
      id="filters"
    >
      <div className="filter-heading">
        <h2>Refine the selection</h2>
        <button className="text-button" onClick={reset} disabled={!active}>
          Reset
        </button>
      </div>
      <label className="field-label" htmlFor="search">
        Search the corpus
      </label>
      <div className="search-wrap">
        <span aria-hidden="true">⌕</span>
        <input
          id="search"
          type="search"
          value={state.q}
          onChange={(e) => update({ q: e.target.value, speech: "" })}
          placeholder="Words, names, arguments…"
        />
      </div>
      <p className="field-hint">
        Dutch speeches and English evidence. Use quotation marks for a phrase.
      </p>
      <fieldset>
        <legend>Period</legend>
        <YearRange state={state} update={update} />
      </fieldset>
      <fieldset className="code-filters">
        <legend>
          <span className="dimension-rule blue" />
          Temporal grammar
        </legend>
        <p className="field-hint dimension-question">
          How does the past relate to the present?
        </p>
        {TG.map((c) => option("tg", c.id, c.label, c.color))}
      </fieldset>
      <fieldset className="code-filters">
        <legend>
          <span className="dimension-rule amber" />
          Symbolic work
        </legend>
        <p className="field-hint dimension-question">
          What does invoking the past do?
        </p>
        {SW.map((c) => option("sw", c.id, c.short, c.color))}
      </fieldset>
      <fieldset>
        <legend>Party / recorded affiliation</legend>
        <input
          className="compact-search"
          type="search"
          aria-label="Find a party"
          placeholder="Find a party…"
          value={partySearch}
          onChange={(e) => setPartySearch(e.target.value)}
        />
        <div className="party-options">
          {partyOptions
            .filter(([, name]) =>
              normalized(name).includes(normalized(partySearch)),
            )
            .map(([id, name]) => option("parties", id, name))}
        </div>
      </fieldset>
      <fieldset>
        <legend>Speaker</legend>
        <input
          className="compact-search"
          type="search"
          aria-label="Find a speaker"
          placeholder="Type a speaker’s name…"
          value={speakerSearch}
          onChange={(e) => setSpeakerSearch(e.target.value)}
        />
        <div className="speaker-options">
          {shownPeople
            .slice(0, 15)
            .map(([id, name]) => option("speakers", id, name))}
        </div>
        {!speakerSearch && !state.speakers.length && (
          <p className="field-hint">Search the 244 reviewed speaker names.</p>
        )}
        {speakerSearch && !shownPeople.length && (
          <p className="field-hint">No matching speaker names.</p>
        )}
        {shownPeople.length > 15 && (
          <p className="field-hint">
            Type more of the name to narrow {shownPeople.length} matches.
          </p>
        )}
      </fieldset>
      <fieldset>
        <legend>Speaking role</legend>
        {Object.entries(ROLES).map(([id, label]) => option("roles", id, label))}
      </fieldset>
      <p className="filter-footnote">
        Option counts reflect the other filters. Affiliation is recorded at the
        contribution date; government role and party affiliation are separate.
      </p>
      <button className="button primary mobile-apply" onClick={closeMobile}>
        Show the selection
      </button>
    </aside>
  );
}
export function ActiveFilters({ state, speeches, update, reset }) {
  const chips = [];
  if (state.q) chips.push({ label: `Search: ${state.q}`, patch: { q: "" } });
  if (state.from !== MIN_YEAR || state.to !== MAX_YEAR)
    chips.push({
      label: `${state.from}–${state.to}`,
      patch: { from: MIN_YEAR, to: MAX_YEAR },
    });
  const names = {
    parties: Object.fromEntries(speeches.map((s) => [s.party, s.partyLabel])),
    speakers: Object.fromEntries(speeches.map((s) => [s.speakerId, s.speaker])),
    roles: ROLES,
    tg: Object.fromEntries(TG.map((c) => [c.id, c.label])),
    sw: Object.fromEntries(SW.map((c) => [c.id, c.label])),
  };
  for (const dimension of Object.keys(names))
    for (const id of state[dimension])
      chips.push({
        label: names[dimension][id] || id,
        patch: { [dimension]: state[dimension].filter((x) => x !== id) },
      });
  if (!chips.length) return null;
  return (
    <div className="active-filters" aria-label="Active filters">
      {chips.map((chip, i) => (
        <button
          key={i}
          onClick={() => update({ ...chip.patch, speech: "" })}
          aria-label={`Remove filter: ${chip.label}`}
        >
          {chip.label}
          <span aria-hidden="true">×</span>
        </button>
      ))}
      <button className="clear-all" onClick={reset}>
        Clear all
      </button>
    </div>
  );
}
export function Timeline({ rows, state, update }) {
  const years = yearCounts(rows),
    max = Math.max(1, ...years.map((y) => y.n));
  return (
    <section className="timeline-panel" aria-labelledby="timeline-title">
      <div className="panel-heading">
        <div>
          <h2 id="timeline-title">Speeches through time</h2>
          <p>Number of coded speeches in the current selection</p>
        </div>
        <span className="chart-scale">Peak: {rows.length ? max : 0}</span>
      </div>
      <div
        className="timeline"
        role="group"
        aria-label="Select a year; use arrow keys to move between years"
      >
        {years.map(({ year, n }, i) => (
          <button
            key={year}
            tabIndex={i === 0 ? 0 : -1}
            title={`${year}: ${n} speeches. Select year.`}
            aria-label={`${year}, ${n} speeches`}
            aria-pressed={state.from === year && state.to === year}
            onClick={() =>
              update({
                from:
                  state.from === year && state.to === year ? MIN_YEAR : year,
                to: state.from === year && state.to === year ? MAX_YEAR : year,
                speech: "",
              })
            }
            onKeyDown={(e) => {
              const move = { ArrowRight: 1, ArrowLeft: -1, Home: -80, End: 80 }[
                e.key
              ];
              if (move) {
                e.preventDefault();
                e.currentTarget.parentElement.children[
                  Math.max(0, Math.min(years.length - 1, i + move))
                ].focus();
              }
            }}
          >
            <span
              style={{ height: `${n ? Math.max(3, (100 * n) / max) : 1}%` }}
              className={n ? "" : "zero"}
            />
          </button>
        ))}
      </div>
      <div className="timeline-axis" aria-hidden="true">
        <span>1945</span>
        <span>1965</span>
        <span>1985</span>
        <span>2005</span>
        <span>2024</span>
      </div>
      <p className="chart-note">
        Click a year to focus the selection. Counts describe this coded sample,
        not rates across all parliamentary speech.
      </p>
    </section>
  );
}
export function Patterns({ rows, state, update }) {
  const [measure, setMeasure] = useState("count");
  const matrix = matrixCounts(rows),
    max = Math.max(1, ...matrix.flat());
  return (
    <section className="patterns-panel" aria-labelledby="patterns-title">
      <div className="panel-heading">
        <div>
          <h2 id="patterns-title">How meanings combine</h2>
          <p>Temporal grammar × symbolic work · all active filters apply</p>
        </div>
        <label className="measure-label">
          Show
          <select value={measure} onChange={(e) => setMeasure(e.target.value)}>
            <option value="count">Speech counts</option>
            <option value="share">Share of selection</option>
          </select>
        </label>
      </div>
      <div
        className="matrix-scroll"
        tabIndex={0}
        role="region"
        aria-label="Coding combinations table"
      >
        <table className="matrix">
          <caption>
            All 20 coding combinations. Select a cell to explore its speeches.
            Darker cells contain more speeches.
          </caption>
          <thead>
            <tr>
              <th scope="col">
                <span className="axis-label">
                  TEMPORAL
                  <br />
                  GRAMMAR ↓
                </span>
                <span className="axis-label">SYMBOLIC WORK →</span>
              </th>
              {SW.map((c) => (
                <th scope="col" key={c.id}>
                  <Code id={c.id} />
                </th>
              ))}
            </tr>
          </thead>
          <tbody>
            {TG.map((c, i) => (
              <tr key={c.id}>
                <th scope="row">
                  <Code id={c.id} />
                </th>
                {SW.map((w, j) => {
                  const n = matrix[i][j];
                  const selected =
                    state.tg.length === 1 &&
                    state.sw.length === 1 &&
                    state.tg[0] === c.id &&
                    state.sw[0] === w.id;
                  return (
                    <td key={w.id}>
                      <button
                        className={selected ? "matrix-selected" : ""}
                        style={matrixStyle(n, max)}
                        aria-pressed={selected}
                        aria-label={`${c.id} ${c.label} and ${w.id} ${w.label}: ${n} speeches. Select combination.`}
                        onClick={() =>
                          update({
                            tg: selected ? [] : [c.id],
                            sw: selected ? [] : [w.id],
                            view: "speeches",
                            speech: "",
                          })
                        }
                      >
                        {measure === "share"
                          ? `${rows.length ? ((100 * n) / rows.length).toFixed(1) : "0.0"}%`
                          : n}
                      </button>
                    </td>
                  );
                })}
              </tr>
            ))}
          </tbody>
        </table>
      </div>
      <p className="matrix-footnote">
        Each contribution has one primary code in each dimension. Percentages
        use the {number(rows.length)} speeches in the current selection as their
        denominator. SW5 “Other” remains included.
      </p>
      <button className="button" onClick={() => update({ view: "speeches" })}>
        Read these {number(rows.length)} speeches{" "}
        <span aria-hidden="true">→</span>
      </button>
    </section>
  );
}
function Highlighted({ text, ranges, family }) {
  return textSegments(text, ranges).map((part, i) =>
    part.marked ? (
      <mark key={i} className={`text-highlight ${family}`}>
        {part.text}
      </mark>
    ) : (
      <React.Fragment key={i}>{part.text}</React.Fragment>
    ),
  );
}
function EvidenceBlock({ speech, dimension, language, locate }) {
  const [index, setIndex] = useState(0);
  const evidence = speech.evidence[dimension],
    current = evidence[index];
  const code = dimension === "tg" ? speech.tg : speech.sw;
  const exact = findRanges(speech.text, current.nl).length > 0;
  return (
    <section className={`evidence-block ${dimension}`}>
      <p className="section-label">
        {dimension === "tg"
          ? "HOW THE PAST CONNECTS TO THE PRESENT"
          : "WHAT INVOKING THE PAST DOES"}
      </p>
      <Code id={code} />
      <div className="evidence-navigation">
        <span>
          Evidence {index + 1} of {evidence.length}
        </span>
        {evidence.length > 1 && (
          <div>
            <button
              aria-label={`Previous ${dimension === "tg" ? "temporal grammar" : "symbolic work"} evidence`}
              disabled={index === 0}
              onClick={() => setIndex(index - 1)}
            >
              ←
            </button>
            <button
              aria-label={`Next ${dimension === "tg" ? "temporal grammar" : "symbolic work"} evidence`}
              disabled={index === evidence.length - 1}
              onClick={() => setIndex(index + 1)}
            >
              →
            </button>
          </div>
        )}
      </div>
      {language !== "en" && <blockquote lang="nl">{current.nl}</blockquote>}
      {language !== "nl" && (
        <div className="translation">
          <span className="section-label">ENGLISH TRANSLATION</span>
          <p>{current.en}</p>
        </div>
      )}
      <button
        className="text-button locate-evidence"
        disabled={!exact}
        onClick={() => locate(dimension, current.nl)}
      >
        Locate in the Dutch speech <span aria-hidden="true">↓</span>
      </button>
      {!exact && (
        <p className="field-hint">
          This extracted fragment cannot be matched exactly to the OCR text.
        </p>
      )}
      <details className="rationale">
        <summary>Why this code?</summary>
        <p>{dimension === "tg" ? speech.tgRationale : speech.swRationale}</p>
      </details>
    </section>
  );
}
export function Reader({
  speech: s,
  copyLink,
  filterSpeaker,
  outsideSelection,
  clearForSpeech,
}) {
  const [language, setLanguage] = useState("both");
  const [highlight, setHighlight] = useState({
    family: "tg",
    query: s.evidence.tg[0].nl,
  });
  const [withinSearch, setWithinSearch] = useState("");
  const details = useRef(null),
    body = useRef(null);
  const query = withinSearch || highlight.query;
  const ranges = useMemo(() => findRanges(s.text, query), [s.text, query]);
  function locate(family, query) {
    setWithinSearch("");
    setHighlight({ family, query });
    details.current.open = true;
    requestAnimationFrame(() =>
      body.current
        ?.querySelector("mark")
        ?.scrollIntoView({
          block: "center",
          behavior: matchMedia("(prefers-reduced-motion: reduce)").matches
            ? "instant"
            : "smooth",
        }),
    );
  }
  return (
    <article className="speech-reader" aria-label={`Speech by ${s.speaker}`}>
      <div className="reader-heading">
        <div className="reader-eyebrow">
          <p className="eyebrow">READ THE EVIDENCE</p>
          <button className="text-button" onClick={() => copyLink(s.id)}>
            Share speech
          </button>
        </div>
        <h2>{s.speaker}</h2>
        <p>
          {dateLabel(s.date)} · {s.partyLabel}
        </p>
        <p className="role-line">
          {ROLES[s.role]}
          {s.capacity && s.capacity !== ROLES[s.role] ? ` · ${s.capacity}` : ""}
        </p>
        {s.group && (
          <p className="role-line">
            Parliamentary group as recorded: {s.group}
          </p>
        )}
        <div className="reader-links">
          <OutLink href={s.biography}>Speaker biography</OutLink>
          <OutLink href={s.source}>Original proceedings</OutLink>
          <button
            className="text-button"
            onClick={() => filterSpeaker(s.speakerId)}
          >
            More by this speaker
          </button>
        </div>
      </div>
      {outsideSelection && (
        <div className="scope-note">
          This shared speech is outside the current selection.{" "}
          <button className="text-button" onClick={clearForSpeech}>
            Clear filters and keep this speech
          </button>
        </div>
      )}
      {s.scopeNote && <p className="scope-note">{s.scopeNote}</p>}
      <div className="reader-content">
        <div className="language-control" aria-label="Evidence language">
          {[
            ["both", "Dutch + English"],
            ["nl", "Dutch"],
            ["en", "English"],
          ].map(([id, label]) => (
            <button
              key={id}
              onClick={() => setLanguage(id)}
              aria-pressed={language === id}
            >
              {label}
            </button>
          ))}
        </div>
        <EvidenceBlock
          speech={s}
          dimension="tg"
          language={language}
          locate={locate}
        />
        <EvidenceBlock
          speech={s}
          dimension="sw"
          language={language}
          locate={locate}
        />
        <p className="translation-note">
          English text is a precomputed translation of the evidence fragments.
          The Dutch proceedings remain the source.
        </p>
        <details className="full-text" ref={details}>
          <summary>Read the full Dutch speech</summary>
          <div className="within-search">
            <label htmlFor="within-speech">Find within this speech</label>
            <input
              id="within-speech"
              type="search"
              value={withinSearch}
              onChange={(e) => setWithinSearch(e.target.value)}
              onKeyDown={(e) => {
                if (e.key === "Enter")
                  body.current
                    ?.querySelector("mark")
                    ?.scrollIntoView({ block: "center" });
              }}
              placeholder="Search the Dutch text…"
            />
            {withinSearch && (
              <span role="status">
                {ranges.length} match{ranges.length === 1 ? "" : "es"}
              </span>
            )}
          </div>
          <p className="full-text-note">
            Original corpus text, including OCR and page headers. Highlighted
            text corresponds to{" "}
            {withinSearch
              ? "your search"
              : highlight.family === "tg"
                ? "the selected temporal-grammar evidence"
                : "the selected symbolic-work evidence"}
            .
          </p>
          <div className="full-text-body" lang="nl" ref={body}>
            <Highlighted
              text={s.text}
              ranges={ranges}
              family={withinSearch ? "search" : highlight.family}
            />
          </div>
        </details>
        <details className="rationale record-notes">
          <summary>Inclusion and research notes</summary>
          <p>{s.inclusionRationale}</p>
          {s.notes && <p>{s.notes}</p>}
          <dl>
            <dt>Original speaker label</dt>
            <dd>{s.originalSpeaker}</dd>
            <dt>Speech identifier</dt>
            <dd className="record-id">{s.id}</dd>
          </dl>
        </details>
      </div>
    </article>
  );
}
export function MobileReader({ speech, close, children }) {
  const ref = useRef(null);
  useEffect(() => {
    if (speech && !ref.current.open) ref.current.showModal();
    else if (!speech && ref.current.open) ref.current.close();
  }, [speech]);
  return (
    <dialog
      className="reader-dialog"
      ref={ref}
      aria-label={speech ? `Speech by ${speech.speaker}` : "Speech reader"}
      onCancel={(e) => {
        e.preventDefault();
        close();
      }}
    >
      <div className="dialog-toolbar">
        <span>Speech reader</span>
        <button className="button" onClick={close}>
          Back to results <span aria-hidden="true">×</span>
        </button>
      </div>
      {children}
    </dialog>
  );
}
export function Information({ page, source, navigate, copy }) {
  if (page === "methods")
    return (
      <section className="information-page">
        <p className="eyebrow">ABOUT & METHODS</p>
        <h1>Reading political uses of the past.</h1>
        <p className="lead">
          The “Golden Age” is more than a name for a historical period. In a
          political argument, it can become a model to restore, a legacy to
          defend, or a memory to challenge.
        </p>
        <div className="information-grid">
          <div>
            <h2>The research</h2>
            <p>
              This explorer accompanies research by Stefan Couperus and Martijn
              Schoonvelde at the University of Groningen on the{" "}
              <i>Gouden Eeuw</i> as a mnemonic trope in Dutch parliamentary
              speech.
            </p>
            <p>
              A dictionary and word-embedding retrieval workflow identified 572
              candidate speeches. The analytic sample contains 447 contributions
              in which a Golden Age reference does argumentative, evaluative or
              identity work. Each received one primary temporal-grammar code and
              one symbolic-work code, using LLM-assisted coding with documented
              human validation.
            </p>
            <h2>Scope and interpretation</h2>
            <p>
              The intended scope is Tweede Kamer debate from 1945 to 2024. The
              earliest included contribution is from 1946. Government speakers
              and one visiting MEP are represented alongside Tweede Kamer
              members.
            </p>
            <p>
              One Eerste Kamer contribution by Jan Verbeek on 1 May 1984 remains
              provisionally included pending a separate scope decision, with a
              visible note. This does not expand the intended scope of the
              study.
            </p>
            <p>
              Counts and percentages describe this selected sample. They do not
              measure a party's or a year's rate of Golden Age references in the
              full parliamentary corpus. Recorded affiliation does not establish
              that a speaker represents that party's position.
            </p>
            <OutLink href="https://github.com/hjmschoonvelde/gouden_eeuw_project/blob/main/docs/methodology_extended.md">
              Read the full methodology
            </OutLink>
          </div>
          <aside className="method-note">
            <h2>From a pattern to its evidence</h2>
            <ol>
              <li>Choose a period, speaker, party or coding category.</li>
              <li>Inspect the timeline or a combination of codes.</li>
              <li>Open a speech to read its evidence in Dutch and English.</li>
              <li>Check the coding rationale and the original proceedings.</li>
            </ol>
            <p>
              The original speech text is preserved, including OCR errors and
              page headers. Evidence translations were prepared in advance.
              Biographies link to reviewed Parlement.com profiles.
            </p>
            <button
              className="button primary"
              onClick={() => navigate("explore")}
            >
              Return to the explorer
            </button>
          </aside>
        </div>
        <section className="codebook">
          <h2>The two coding dimensions</h2>
          <div className="codebook-columns">
            <div>
              <h3>Temporal grammar</h3>
              <p>How does the speech connect past, present and future?</p>
              {TG.map((c) => (
                <div className="code-definition" key={c.id}>
                  <Code id={c.id} />
                  <p>{c.meaning}</p>
                </div>
              ))}
            </div>
            <div>
              <h3>Symbolic work</h3>
              <p>What does invoking that past do in the argument?</p>
              {SW.map((c) => (
                <div className="code-definition" key={c.id}>
                  <Code id={c.id} />
                  <p>{c.meaning}</p>
                </div>
              ))}
            </div>
          </div>
          <p className="method-small">
            The residual temporal-grammar category TG5 is excluded from the
            analytic sample. The four SW5 “Other” contributions remain included.
            Contests over the meaning or ownership of “Gouden Eeuw” take
            priority as TG4; symbolic work is classified by the dominant target
            of the argument.
          </p>
          <OutLink href="https://github.com/hjmschoonvelde/gouden_eeuw_project/blob/main/docs/codebook.md">
            Read the research codebook
          </OutLink>
        </section>
      </section>
    );
  return (
    <section className="information-page">
      <p className="eyebrow">DATA & CITATION</p>
      <h1>Follow the research. Reuse the data.</h1>
      <p className="lead">
        Explore and reuse the 447 coded contributions, with reviewed speaker
        identities and links to the original proceedings.
      </p>
      <div className="information-grid">
        <div>
          <h2>Download the data</h2>
          <p>
            The full analytic dataset contains all 447 coded contributions. To
            download a filtered selection with its paired evidence translations,
            use “Download selection” in the explorer.
          </p>
          <a
            className="button primary"
            href={`${import.meta.env.BASE_URL}data/research.csv`}
            download="golden-age-research-data.csv"
          >
            Download full research CSV <span aria-hidden="true">↓</span>
          </a>
          <div className="data-links">
            <OutLink href={source.url}>
              Exact research dataset used here
            </OutLink>
            <OutLink href={source.repository}>
              Research and reproduction materials
            </OutLink>
            <OutLink href="https://github.com/hjmschoonvelde/gouden_eeuw_project/blob/main/docs/speaker_links.md">
              Speaker identities and biography review
            </OutLink>
            <OutLink href="https://github.com/hjmschoonvelde/gouden_eeuw_project/blob/main/docs/metadata_corrections.md">
              Metadata and scope notes
            </OutLink>
          </div>
          <h2>Cite the study</h2>
          <p className="citation">{researchCitation}</p>
          <button
            className="button"
            onClick={() => copy(researchCitation, "Citation copied")}
          >
            Copy citation
          </button>
        </div>
        <aside className="method-note">
          <h2>Source and version</h2>
          <p>
            The data are a fixed snapshot of the research repository. The
            download preserves original corpus labels alongside reviewed speaker
            identities.
          </p>
          <p>
            <OutLink href={`${source.repository}/commit/${source.commit}`}>
              View this dataset version
            </OutLink>
          </p>
          <h2>Rights and attribution</h2>
          <p>
            The dashboard software is licensed under MIT. Parliamentary texts
            and linked biographies remain subject to their original sources'
            terms. Biography prose and photographs are not reproduced here.
          </p>
          <p>
            Please cite the research when using the dataset and retain speech
            identifiers when referring to individual contributions.
          </p>
          <button className="button" onClick={() => navigate("explore")}>
            Return to the explorer
          </button>
        </aside>
      </div>
    </section>
  );
}
