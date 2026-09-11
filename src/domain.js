export const TG = [
  {
    id: "TG1",
    label: "Continuity",
    color: "#16466b",
    meaning:
      "The past continues into the present through identity, analogy or a lasting national vocation.",
  },
  {
    id: "TG2",
    label: "Return",
    color: "#2b78a3",
    meaning: "The past offers a model to recover, renew or restore.",
  },
  {
    id: "TG3",
    label: "Break",
    color: "#67afd1",
    meaning: "The past is no longer a valid, usable or comparable guide.",
  },
  {
    id: "TG4",
    label: "Struggle",
    color: "#c2e2ef",
    meaning:
      "The meaning, ownership or commemoration of the past is itself contested.",
  },
];
export const SW = [
  {
    id: "SW1",
    label: "Governing legitimation",
    short: "Legitimation",
    color: "#81370e",
    meaning:
      "Invoking the past justifies a policy, institution, budget or governing programme.",
  },
  {
    id: "SW2",
    label: "Competitive positioning",
    short: "Positioning",
    color: "#b66013",
    meaning:
      "Invoking the past praises, blames, attacks or defends a political actor.",
  },
  {
    id: "SW3",
    label: "Identity and boundary making",
    short: "Identity",
    color: "#e49320",
    meaning:
      "Invoking the past defines collective identity, belonging or the boundaries of a group.",
  },
  {
    id: "SW4",
    label: "Moral memory",
    short: "Moral memory",
    color: "#f3c35e",
    meaning:
      "Invoking the past expresses pride, shame, responsibility, apology or another moral judgement.",
  },
  {
    id: "SW5",
    label: "Other",
    short: "Other",
    color: "#fae6b3",
    meaning: "The symbolic work falls outside the four main categories.",
  },
];
export const CODES = Object.fromEntries([...TG, ...SW].map((x) => [x.id, x]));
export const ROLES = {
  mp: "Tweede Kamer member",
  government: "Government speaker",
  mep: "Visiting MEP",
  senator: "Eerste Kamer member",
};
export const MIN_YEAR = 1945;
export const MAX_YEAR = 2024;
export const INITIAL = {
  q: "",
  from: MIN_YEAR,
  to: MAX_YEAR,
  parties: [],
  roles: [],
  speakers: [],
  tg: [],
  sw: [],
  view: "speeches",
  page: "explore",
  speech: "",
  sort: "newest",
};
const dimensions = ["parties", "roles", "speakers", "tg", "sw"];
export const normalized = (text) =>
  String(text ?? "")
    .normalize("NFD")
    .replace(/[\u0300-\u036f]/g, "")
    .toLocaleLowerCase("nl")
    .replace(/\s+/g, " ")
    .trim();
export const queryTerms = (q) =>
  (q.match(/"[^"]+"|\S+/g) || [])
    .map((x) => normalized(x.replace(/^"|"$/g, "")))
    .filter(Boolean);
export function parseState(hash = "") {
  const p = new URLSearchParams(hash.replace(/^#/, ""));
  const state = { ...INITIAL };
  for (const key of ["q", "speech"]) state[key] = p.get(key) || "";
  for (const key of dimensions)
    state[key] = [...new Set((p.get(key) || "").split("|").filter(Boolean))];
  state.from = Math.max(
    MIN_YEAR,
    Math.min(MAX_YEAR, Math.trunc(Number(p.get("from"))) || MIN_YEAR),
  );
  state.to = Math.max(
    state.from,
    Math.min(MAX_YEAR, Math.trunc(Number(p.get("to"))) || MAX_YEAR),
  );
  state.tg = state.tg.filter((x) => TG.some((c) => c.id === x));
  state.sw = state.sw.filter((x) => SW.some((c) => c.id === x));
  state.roles = state.roles.filter((x) => x in ROLES);
  state.view = p.get("view") === "patterns" ? "patterns" : "speeches";
  // Previously shared data-page URLs now lead to the note in About.
  state.page = ["methods", "data"].includes(p.get("page"))
    ? "methods"
    : "explore";
  state.sort = p.get("sort") === "oldest" ? "oldest" : "newest";
  return state;
}
export function serializeState(state) {
  const p = new URLSearchParams();
  for (const key of Object.keys(INITIAL)) {
    const value = state[key];
    if (Array.isArray(value)) {
      if (value.length) p.set(key, [...value].sort().join("|"));
    } else if (value !== INITIAL[key] && value !== "")
      p.set(key, String(value));
  }
  return p.toString();
}
export function prepareSpeeches(speeches) {
  return speeches.map((s) => ({
    ...s,
    searchText: normalized(
      [
        s.speaker,
        s.originalSpeaker,
        s.sourceSpeaker,
        s.partyLabel,
        s.capacity,
        s.governmentPosition,
        s.text,
        s.tgRationale,
        s.swRationale,
        ...s.evidence.tg.flatMap((e) => [e.nl, e.en]),
        ...s.evidence.sw.flatMap((e) => [e.nl, e.en]),
      ].join(" "),
    ),
  }));
}
export function filterSpeeches(speeches, state, omit) {
  const terms = queryTerms(state.q);
  return speeches.filter(
    (s) =>
      s.year >= state.from &&
      s.year <= state.to &&
      terms.every((t) => s.searchText.includes(t)) &&
      (omit === "parties" ||
        !state.parties.length ||
        state.parties.includes(s.party)) &&
      (omit === "roles" ||
        !state.roles.length ||
        state.roles.includes(s.role)) &&
      (omit === "speakers" ||
        !state.speakers.length ||
        state.speakers.includes(s.speakerId)) &&
      (omit === "tg" || !state.tg.length || state.tg.includes(s.tg)) &&
      (omit === "sw" || !state.sw.length || state.sw.includes(s.sw)),
  );
}
export function matrixStyle(count, maximum) {
  const opacity = count ? 0.09 + (0.76 * count) / Math.max(1, maximum) : 0;
  const background =
    "#" +
    [19, 44, 62]
      .map((channel) =>
        Math.round(255 + opacity * (channel - 255))
          .toString(16)
          .padStart(2, "0"),
      )
      .join("");
  return { background, color: foreground(background) };
}
export const toggle = (list, value) =>
  list.includes(value) ? list.filter((x) => x !== value) : [...list, value];
export const dateLabel = (date) =>
  new Date(date + "T12:00:00Z").toLocaleDateString("en-GB", {
    day: "numeric",
    month: "long",
    year: "numeric",
    timeZone: "UTC",
  });
export const number = (n) => n.toLocaleString("en-GB");
export function foreground(hex) {
  const c = hex
    .slice(1)
    .match(/../g)
    .map((v) => parseInt(v, 16) / 255)
    .map((v) => (v <= 0.04045 ? v / 12.92 : ((v + 0.055) / 1.055) ** 2.4));
  const luminance = 0.2126 * c[0] + 0.7152 * c[1] + 0.0722 * c[2];
  return (luminance + 0.05) / 0.05 > 1.05 / (luminance + 0.05)
    ? "#000000"
    : "#ffffff";
}
export const yearCounts = (rows) =>
  Array.from({ length: MAX_YEAR - MIN_YEAR + 1 }, (_, i) => ({
    year: MIN_YEAR + i,
    n: rows.filter((s) => s.year === MIN_YEAR + i).length,
  }));
export const matrixCounts = (rows) =>
  TG.map((t) =>
    SW.map((w) => rows.filter((s) => s.tg === t.id && s.sw === w.id).length),
  );
export const researchCitation =
  "Couperus, Stefan, and Martijn Schoonvelde. “Golden Age Politics: A Computational-Interpretive Analysis of the ‘Gouden Eeuw’ as a Trope in Dutch Parliamentary Speech, 1945–2024.” Forthcoming in Revived Futures: The Turn to the Past in European Party Politics, edited by Katarina Pettersson, Katarina Eriksson, and Monika Menke. Palgrave Macmillan, 2026.";
export function validateFilters(input, speeches) {
  if (!input || typeof input !== "object" || Array.isArray(input))
    throw Error("Supply a filter object.");
  const allowed = ["q", "from", "to", ...dimensions];
  if (Object.keys(input).some((k) => !allowed.includes(k)))
    throw Error("Unknown filter field.");
  if ("q" in input && typeof input.q !== "string")
    throw Error("Search must be text.");
  for (const k of ["from", "to"])
    if (
      k in input &&
      (!Number.isInteger(input[k]) ||
        input[k] < MIN_YEAR ||
        input[k] > MAX_YEAR)
    )
      throw Error("Years must be between 1945 and 2024.");
  const valid = {
    parties: new Set(speeches.map((s) => s.party)),
    speakers: new Set(speeches.map((s) => s.speakerId)),
    roles: new Set(Object.keys(ROLES)),
    tg: new Set(TG.map((c) => c.id)),
    sw: new Set(SW.map((c) => c.id)),
  };
  for (const k of dimensions)
    if (
      k in input &&
      (!Array.isArray(input[k]) || input[k].some((x) => !valid[k].has(x)))
    )
      throw Error(`Unknown ${k} value.`);
  return input;
}

// Normalize typography and whitespace while keeping offsets into the unchanged
// Dutch speech. This permits highlighting without rewriting the source text.
function comparable(text) {
  let value = "",
    start = [],
    end = [],
    offset = 0;
  for (const char of text) {
    let c = char
      .replace(/[“”„«»]/g, '"')
      .replace(/[‘’]/g, "'")
      .toLowerCase();
    if (/\s/.test(c)) c = " ";
    if (c === " " && value.endsWith(" "))
      end[end.length - 1] = offset + char.length;
    else {
      for (let unit = 0; unit < c.length; unit++) {
        value += c[unit];
        start.push(offset);
        end.push(offset + char.length);
      }
    }
    offset += char.length;
  }
  return { value, start, end };
}
export function findRanges(text, query) {
  if (!query.trim()) return [];
  const source = comparable(text),
    needle = comparable(query.trim()).value;
  const ranges = [];
  let at = source.value.indexOf(needle);
  while (at !== -1) {
    ranges.push({
      start: source.start[at],
      end: source.end[at + needle.length - 1],
    });
    at = source.value.indexOf(needle, at + needle.length);
  }
  return ranges;
}
export function evidenceRanges(speech) {
  return ["tg", "sw"].flatMap((family) =>
    speech.evidence[family].flatMap((evidence) =>
      findRanges(speech.text, evidence.nl).map((range) => ({
        ...range,
        family,
        evidenceId: evidence.id,
      })),
    ),
  );
}
export function textSegments(text, ranges) {
  const bounds = [
    ...new Set([0, text.length, ...ranges.flatMap((r) => [r.start, r.end])]),
  ].sort((a, b) => a - b);
  return bounds.slice(0, -1).map((start, i) => {
    const end = bounds[i + 1];
    const matches = ranges.filter(
      (range) => range.start <= start && range.end >= end,
    );
    return {
      text: text.slice(start, end),
      start,
      end,
      marked: matches.length > 0,
      families: ["tg", "sw", "search"].filter((family) =>
        matches.some((range) => range.family === family),
      ),
      evidenceIds: [
        ...new Set(matches.map((range) => range.evidenceId).filter(Boolean)),
      ],
    };
  });
}
