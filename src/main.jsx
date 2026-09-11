import React, { useEffect, useMemo, useRef, useState } from "react";
import { createRoot } from "react-dom/client";
import {
  INITIAL,
  MAX_YEAR,
  MIN_YEAR,
  dateLabel,
  filterSpeeches,
  number,
  parseState,
  prepareSpeeches,
  serializeState,
  validateFilters,
} from "./domain.js";
import {
  ActiveFilters,
  AuthorLinks,
  Code,
  Filters,
  Information,
  MobileReader,
  OutLink,
  Patterns,
  Reader,
  Timeline,
} from "./components.jsx";
import { CodeHint } from "./CodeHint.jsx";
import "./styles.css";
import "./explorer.css";

function useMobile() {
  const [mobile, setMobile] = useState(
    () => matchMedia("(max-width: 1000px)").matches,
  );
  useEffect(() => {
    const media = matchMedia("(max-width: 1000px)");
    const change = () => setMobile(media.matches);
    media.addEventListener("change", change);
    return () => media.removeEventListener("change", change);
  }, []);
  return mobile;
}
function App() {
  const [data, setData] = useState(null);
  const [error, setError] = useState("");
  const [state, setState] = useState(() => parseState(location.hash));
  const [limit, setLimit] = useState(12);
  const [mobileFilters, setMobileFilters] = useState(false);
  const [toast, setToast] = useState("");
  const [manualCopy, setManualCopy] = useState("");
  const mobile = useMobile();
  const stateRef = useRef(state),
    updateRef = useRef(null),
    toastTimer = useRef(null);
  stateRef.current = state;
  useEffect(() => {
    const controller = new AbortController();
    fetch(
      new URL(`${import.meta.env.BASE_URL}data/corpus.json`, location.href),
      { signal: controller.signal },
    )
      .then((r) => {
        if (!r.ok) throw Error("The research data could not be loaded.");
        return r.json();
      })
      .then((d) => {
        if (d.schemaVersion !== 1 || !Array.isArray(d.speeches))
          throw Error("This data version is not supported.");
        setData({ ...d, speeches: prepareSpeeches(d.speeches) });
      })
      .catch((e) => {
        if (e.name !== "AbortError") setError(e.message);
      });
    return () => {
      controller.abort();
      clearTimeout(toastTimer.current);
    };
  }, []);
  useEffect(() => {
    const restore = () => {
      setState(parseState(location.hash));
      setLimit(12);
    };
    addEventListener("popstate", restore);
    addEventListener("hashchange", restore);
    return () => {
      removeEventListener("popstate", restore);
      removeEventListener("hashchange", restore);
    };
  }, []);
  function update(patch) {
    const next = { ...stateRef.current, ...patch };
    const hash = serializeState(next);
    history[
      Object.hasOwn(patch, "q") &&
      Object.keys(patch).every((k) => ["q", "speech"].includes(k))
        ? "replaceState"
        : "pushState"
    ](null, "", location.pathname + location.search + (hash ? "#" + hash : ""));
    stateRef.current = next;
    setState(next);
    setLimit(12);
  }
  updateRef.current = update;
  const rows = useMemo(
    () =>
      data
        ? filterSpeeches(data.speeches, state).sort((a, b) =>
            state.sort === "oldest"
              ? a.date.localeCompare(b.date) || a.id.localeCompare(b.id)
              : b.date.localeCompare(a.date) || a.id.localeCompare(b.id),
          )
        : [],
    [data, state],
  );
  const selected = state.speech
    ? data?.speeches.find((s) => s.id === state.speech)
    : rows[0];
  const outsideSelection = selected && !rows.some((s) => s.id === selected.id);
  const reset = () =>
    update({ ...INITIAL, page: state.page, view: state.view });
  const active = Boolean(
    state.q ||
      state.from !== MIN_YEAR ||
      state.to !== MAX_YEAR ||
      ["parties", "roles", "speakers", "tg", "sw"].some((k) => state[k].length),
  );
  const navigate = (page) => {
    update({ page });
    window.scrollTo({ top: 0 });
  };
  async function copy(text, success = "Link copied") {
    try {
      await navigator.clipboard.writeText(text);
      setToast(success);
      clearTimeout(toastTimer.current);
      toastTimer.current = setTimeout(() => setToast(""), 3500);
    } catch {
      setManualCopy(text);
    }
  }
  const share = (speech) =>
    copy(
      `${location.origin}${location.pathname}${location.search}#${serializeState({ ...state, page: "explore", ...(speech ? { speech } : {}) })}`,
    );
  useEffect(() => {
    document.title =
      state.page === "explore"
        ? "Golden Age Politics — Explore Dutch parliamentary speech"
        : "About & methods — Golden Age Politics";
  }, [state.page]);
  // Optional WebMCP surface shares the interface's filter actions. Browsers
  // without this proposed API use the ordinary controls without a polyfill.
  useEffect(() => {
    if (!data || !document.modelContext?.registerTool) return;
    const lifecycle = new AbortController();
    const summarize = (current) => {
      const matches = filterSpeeches(data.speeches, current);
      return {
        count: matches.length,
        filters: current,
        speeches: matches.slice(0, 20).map((s) => ({
          id: s.id,
          speaker: s.speaker,
          date: s.date,
          tg: s.tg,
          sw: s.sw,
        })),
      };
    };
    const tools = [
      {
        name: "read_speech_selection",
        title: "Read the selected speeches",
        description:
          "Return current filters, result count and up to 20 matching speech identifiers.",
        inputSchema: {
          type: "object",
          properties: {},
          additionalProperties: false,
        },
        annotations: { readOnlyHint: true, untrustedContentHint: true },
        execute: (input) => {
          if (input && Object.keys(input).length)
            throw Error("No arguments are accepted.");
          return summarize(stateRef.current);
        },
      },
      {
        name: "filter_speeches",
        title: "Filter parliamentary speeches",
        description:
          "Update the visible explorer filters; omitted fields keep their values. Empty arrays clear a category filter. Returns the matching selection.",
        inputSchema: {
          type: "object",
          properties: {
            q: { type: "string" },
            from: { type: "integer", minimum: MIN_YEAR, maximum: MAX_YEAR },
            to: { type: "integer", minimum: MIN_YEAR, maximum: MAX_YEAR },
            ...Object.fromEntries(
              ["parties", "roles", "speakers", "tg", "sw"].map((k) => [
                k,
                { type: "array", items: { type: "string" } },
              ]),
            ),
          },
          additionalProperties: false,
        },
        annotations: { readOnlyHint: false, untrustedContentHint: true },
        execute: async (input) => {
          const patch = validateFilters(input, data.speeches);
          const next = {
            ...stateRef.current,
            ...patch,
            page: "explore",
            speech: "",
          };
          if (next.from > next.to)
            throw Error("The first year must not follow the last year.");
          updateRef.current(next);
          await new Promise((resolve) => requestAnimationFrame(resolve));
          return summarize(next);
        },
      },
    ];
    for (const tool of tools) {
      try {
        Promise.resolve(
          document.modelContext.registerTool(tool, {
            signal: lifecycle.signal,
          }),
        ).catch(() => {});
      } catch {
        /* Normal browser controls remain available. */
      }
    }
    return () => lifecycle.abort();
  }, [data]);
  function reader() {
    return (
      selected && (
        <Reader
          key={selected.id}
          speech={selected}
          copyLink={share}
          filterSpeaker={(id) =>
            update({ speakers: [id], speech: "", view: "speeches" })
          }
          outsideSelection={outsideSelection}
          clearForSpeech={() => update({ ...INITIAL, speech: selected.id })}
        />
      )
    );
  }
  const readerOpen =
    mobile && state.page === "explore" && state.speech && selected;
  function feedback() {
    return (
      <>
        {toast && (
          <div className="toast" role="status">
            {toast}
          </div>
        )}
        {manualCopy && (
          <div
            className="copy-fallback"
            role="dialog"
            aria-modal="false"
            aria-label="Copy the text"
          >
            <p>Copy this text:</p>
            <textarea
              aria-label="Text to copy"
              readOnly
              value={manualCopy}
              onFocus={(e) => e.target.select()}
              autoFocus
            />
            <button className="button" onClick={() => setManualCopy("")}>
              Close
            </button>
          </div>
        )}
      </>
    );
  }
  return (
    <>
      <a
        className="skip-link"
        href="#main-content"
        onClick={(e) => {
          e.preventDefault();
          document.getElementById("main-content").focus();
        }}
      >
        Skip to content
      </a>
      <header className="site-header">
        <div className="header-inner">
          <a
            className="brand"
            href={location.pathname}
            onClick={(e) => {
              e.preventDefault();
              navigate("explore");
            }}
          >
            <span>
              Golden Age <em>Politics</em>
            </span>
            <small>DUTCH PARLIAMENTARY MEMORY · 1945–2024</small>
          </a>
          <nav aria-label="Main navigation">
            {[
              ["explore", "Explore"],
              ["methods", "About & methods"],
            ].map(([page, label]) => (
              <button
                key={page}
                className={state.page === page ? "nav-current" : ""}
                aria-current={state.page === page ? "page" : undefined}
                onClick={() => navigate(page)}
              >
                {label}
              </button>
            ))}
          </nav>
        </div>
      </header>
      <main id="main-content" tabIndex={-1}>
        {state.page === "explore" && (
          <section className="introduction">
            <div>
              <p className="eyebrow">A RESEARCH EXPLORER</p>
              <h1>The Golden Age in parliamentary debate.</h1>
              <p>
                How does a remembered past become a political argument? Explore
                the uses of the <i>Gouden Eeuw</i>, with Dutch speeches and
                English translations of the evidence.
              </p>
            </div>
            <dl className="study-stats">
              <div>
                <dt>Coded speeches</dt>
                <dd>447</dd>
              </div>
              <div>
                <dt>Speakers</dt>
                <dd>244</dd>
              </div>
              <div>
                <dt>Study period</dt>
                <dd className="period">
                  1945<span>—</span>2024
                </dd>
              </div>
            </dl>
          </section>
        )}
        {error ? (
          <div className="notice error" role="alert">
            <h2>The explorer could not load</h2>
            <p>{error} Please reload to try again.</p>
            <OutLink href="https://github.com/hjmschoonvelde/gouden_eeuw_project/blob/main/docs/methodology_extended.md">
              Read the research methodology
            </OutLink>
          </div>
        ) : !data ? (
          <div className="loading" role="status">
            <span className="spinner" />
            Loading the speeches and their evidence…
          </div>
        ) : state.page !== "explore" ? (
          <Information navigate={navigate} copy={copy} />
        ) : (
          <div className="workspace" id="explorer">
            <button
              className="mobile-filter-button button"
              onClick={() => setMobileFilters(!mobileFilters)}
              aria-expanded={mobileFilters}
              aria-controls="filters"
            >
              {mobileFilters ? "Hide filters" : "Filters"}{" "}
              {active ? "· active" : ""}
            </button>
            <Filters
              speeches={data.speeches}
              state={state}
              update={update}
              reset={reset}
              active={active}
              mobileOpen={mobileFilters}
              closeMobile={() => setMobileFilters(false)}
            />
            <section
              className="explore-main"
              aria-label="Speeches and evidence"
            >
              <Timeline rows={rows} state={state} update={update} />
              <ActiveFilters
                state={state}
                speeches={data.speeches}
                update={update}
                reset={reset}
              />
              <div className="result-heading">
                <div>
                  <p className="eyebrow">
                    {active
                      ? "THE CURRENT SELECTION"
                      : "EXPLORE THE COLLECTION"}
                  </p>
                  <h2 aria-live="polite">
                    {number(rows.length)}{" "}
                    <span>
                      speeches · {new Set(rows.map((s) => s.speakerId)).size}{" "}
                      speakers
                    </span>
                  </h2>
                </div>
                <div className="selection-actions">
                  <button className="text-button" onClick={() => share()}>
                    Share selection
                  </button>
                </div>
              </div>
              <div className="view-toolbar">
                <div
                  className="view-tabs"
                  role="group"
                  aria-label="Explorer view"
                >
                  <button
                    aria-pressed={state.view === "speeches"}
                    onClick={() => update({ view: "speeches" })}
                  >
                    Speeches
                  </button>
                  <button
                    aria-pressed={state.view === "patterns"}
                    onClick={() => update({ view: "patterns" })}
                  >
                    Patterns
                  </button>
                </div>
                {state.view === "speeches" && (
                  <label className="sort-label">
                    Order
                    <select
                      value={state.sort}
                      onChange={(e) => update({ sort: e.target.value })}
                    >
                      <option value="newest">Newest first</option>
                      <option value="oldest">Oldest first</option>
                    </select>
                  </label>
                )}
              </div>
              {state.speech && !selected && (
                <div className="scope-note" role="status">
                  That speech identifier is not in this dataset.{" "}
                  <button
                    className="text-button"
                    onClick={() => update({ speech: "" })}
                  >
                    Return to the selection
                  </button>
                </div>
              )}
              {state.view === "patterns" ? (
                <Patterns rows={rows} state={state} update={update} />
              ) : (
                <>
                  {!rows.length && (
                    <div className="empty-state">
                      <h3>No speeches match this combination.</h3>
                      <p>Try fewer filters or a different search term.</p>
                      <button className="button primary" onClick={reset}>
                        Reset all filters
                      </button>
                    </div>
                  )}
                  <div
                    className={`results-reader ${!rows.length ? "no-results" : ""}`}
                  >
                    <div className="speech-results">
                      <div className="speech-list">
                        {rows.slice(0, limit).map((s) => (
                          <CodeHint
                            as="button"
                            codes={[s.tg, s.sw]}
                            preserveClick
                            focusOnly
                            key={s.id}
                            className={`speech-card ${s.id === selected?.id ? "selected" : ""}`}
                            onClick={() => update({ speech: s.id })}
                            aria-pressed={s.id === selected?.id}
                          >
                            <span className="result-date">
                              {dateLabel(s.date)}
                              <span>{s.partyLabel}</span>
                            </span>
                            <strong>{s.speaker}</strong>
                            <p lang="nl">
                              {s.evidence.tg[0].nl.slice(0, 175)}
                              {s.evidence.tg[0].nl.length > 175 ? "…" : ""}
                            </p>
                            <span className="code-row">
                              <Code id={s.tg} focusable={false} />
                              <Code id={s.sw} focusable={false} />
                            </span>
                            {s.scopeNote && (
                              <span className="scope-indicator">
                                Scope note
                              </span>
                            )}
                          </CodeHint>
                        ))}
                      </div>
                      {rows.length > limit && (
                        <button
                          className="button load-more"
                          onClick={() => setLimit(limit + 12)}
                        >
                          Show 12 more{" "}
                          <span>({rows.length - limit} remaining)</span>
                        </button>
                      )}
                    </div>
                    {!mobile && reader()}
                  </div>
                </>
              )}
              {mobile && (
                <MobileReader
                  speech={state.speech ? selected : null}
                  close={() => update({ speech: "" })}
                >
                  {state.speech && reader()}
                  {readerOpen && feedback()}
                </MobileReader>
              )}
            </section>
          </div>
        )}
      </main>
      <footer className="site-footer">
        <div className="footer-authors">
          <AuthorLinks />
        </div>
        <span>University of Groningen</span>
      </footer>
      {!readerOpen && feedback()}
    </>
  );
}

createRoot(document.getElementById("root")).render(<App />);
