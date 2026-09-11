import test from "node:test";
import assert from "node:assert/strict";
import { readFileSync } from "node:fs";
import { createHash } from "node:crypto";
import { execFileSync } from "node:child_process";
import {
  INITIAL,
  TG,
  SW,
  filterSpeeches,
  findRanges,
  foreground,
  matrixCounts,
  matrixStyle,
  parseState,
  prepareSpeeches,
  selectionCSV,
  serializeState,
  textSegments,
  validateFilters,
  yearCounts,
} from "../src/domain.js";

const corpus = JSON.parse(
  readFileSync(new URL("../public/data/corpus.json", import.meta.url)),
);
const speeches = prepareSpeeches(corpus.speeches);
const count = (field, rows = speeches) =>
  rows.reduce((result, s) => {
    result[s[field]] = (result[s[field]] || 0) + 1;
    return result;
  }, {});
const csvRows = (csv) =>
  JSON.parse(
    execFileSync(
      "python3",
      [
        "-c",
        "import sys,csv,json; csv.field_size_limit(10000000); print(json.dumps(list(csv.DictReader(sys.stdin))))",
      ],
      { input: csv.replace(/^\ufeff/, ""), maxBuffer: 30_000_000 },
    ).toString(),
  );

test("website uses the exact updated research snapshot, with all texts and identities preserved", () => {
  const original = readFileSync(
    new URL("../data/research/ge_final_45_24.csv", import.meta.url),
  );
  assert.equal(
    createHash("sha256").update(original).digest("hex"),
    corpus.source.sha256,
  );
  assert.deepEqual(
    original,
    readFileSync(new URL("../public/data/research.csv", import.meta.url)),
  );
  const source = new Map(
    csvRows(original.toString()).map((s) => [s.speech_id, s]),
  );
  const translations = new Map(
    csvRows(
      readFileSync(
        new URL("../df_snippets_translated.csv", import.meta.url),
        "utf8",
      ),
    ).map((s) => [s.speech_id, s]),
  );
  assert.equal(speeches.length, 447);
  assert.equal(new Set(speeches.map((s) => s.id)).size, 447);
  assert.equal(new Set(speeches.map((s) => s.speakerId)).size, 244);
  for (const s of speeches) {
    const row = source.get(s.id);
    for (const [siteField, csvField] of Object.entries({
      text: "text",
      speaker: "speaker",
      speakerId: "speaker_person_id",
      biography: "speaker_profile_url",
      date: "date",
      role: "role",
      scopeNote: "sample_scope_note",
      originalSpeaker: "speaker_original",
      sourceSpeaker: "speaker_source_label",
      tg: "temporal_grammar_code",
      sw: "symbolic_work_code",
      tgRationale: "temporal_grammar_rationale",
      swRationale: "symbolic_work_rationale",
    }))
      assert.equal(s[siteField], row[csvField], `${s.id}/${siteField}`);
    assert.match(
      s.source,
      /^https:\/\/(resolver\.kb\.nl|zoek\.officielebekendmakingen\.nl)\//,
    );
    assert.match(s.biography, /^https:\/\/www\.parlement\.com\/biografie\//);
    for (const dimension of ["tg", "sw"]) {
      assert(s.evidence[dimension].length > 0);
      assert.equal(
        new Set(s.evidence[dimension].map((e) => e.id)).size,
        s.evidence[dimension].length,
      );
      assert(s.evidence[dimension].every((e) => e.nl.length && e.en.length));
      const field = dimension === "tg" ? "temporal_grammar" : "symbolic_work";
      for (const language of ["nl", "en"])
        assert.deepEqual(
          s.evidence[dimension].map((e) => e[language]),
          translations
            .get(s.id)
            [`${field}_sentences${language === "en" ? "_en" : ""}`].split(
              " || ",
            )
            .map((s) => s.trim()),
        );
    }
  }
  assert.deepEqual(count("tg"), { TG1: 258, TG3: 68, TG2: 66, TG4: 55 });
  assert.deepEqual(count("sw"), {
    SW1: 287,
    SW3: 33,
    SW2: 88,
    SW4: 35,
    SW5: 4,
  });
  assert.deepEqual(count("role"), {
    mp: 375,
    government: 70,
    senator: 1,
    mep: 1,
  });
});

test("role and affiliation stay separate; Verbeek remains with his explicit note", () => {
  assert.equal(
    filterSpeeches(speeches, { ...INITIAL, roles: ["government"] }).length,
    70,
  );
  assert.equal(
    filterSpeeches(speeches, { ...INITIAL, parties: ["unknown"] }).length,
    69,
  );
  assert.equal(
    filterSpeeches(speeches, { ...INITIAL, parties: ["groenlinks"] }).length,
    9,
  );
  const senator = filterSpeeches(speeches, { ...INITIAL, roles: ["senator"] });
  assert.equal(senator[0].speaker, "Jan Verbeek");
  assert.match(senator[0].scopeNote, /retained provisionally/);
  assert.equal(
    senator[0].source,
    "https://resolver.kb.nl/resolve?urn=sgd:mpeg21:19831984:0000028:pdf",
  );
});

test("filters combine OR within a field and AND across fields without clearing other choices", () => {
  const filter = {
    ...INITIAL,
    from: 1990,
    to: 2024,
    parties: ["pvda", "vvd"],
    roles: ["mp"],
    tg: ["TG1", "TG2"],
    sw: ["SW2"],
  };
  const expected = speeches.filter(
    (s) =>
      s.year >= 1990 &&
      ["pvda", "vvd"].includes(s.party) &&
      s.role === "mp" &&
      ["TG1", "TG2"].includes(s.tg) &&
      s.sw === "SW2",
  );
  assert(expected.length > 0);
  assert.deepEqual(filterSpeeches(speeches, filter), expected);
  const person = expected[0].speakerId;
  assert.deepEqual(
    filterSpeeches(speeches, { ...filter, speakers: [person] }),
    expected.filter((s) => s.speakerId === person),
  );
  assert.equal(
    filterSpeeches(speeches, {
      ...filter,
      q: "this phrase definitely never appears xyz987654",
    }).length,
    0,
  );
  assert.equal(filterSpeeches(speeches, INITIAL).length, 447);
});

test("search covers full Dutch text, reviewed and original names, and English evidence", () => {
  assert.equal(
    filterSpeeches(speeches, {
      ...INITIAL,
      q: '"Jan Verbeek"',
      roles: ["senator"],
    }).length,
    1,
  );
  assert(
    filterSpeeches(speeches, { ...INITIAL, q: "Holtrop" }).some(
      (s) => s.speaker === "Charles Welter",
    ),
  );
  const s = speeches.find((s) => s.role === "senator");
  const englishPhrase = s.evidence.tg[0].en.split(/\s+/).slice(0, 8).join(" ");
  assert(
    filterSpeeches(speeches, { ...INITIAL, q: `"${englishPhrase}"` }).some(
      (row) => row.id === s.id,
    ),
  );
  const middlePhrase = s.text
    .slice(1200, 1260)
    .split(" ")
    .slice(1, -1)
    .join(" ");
  assert(
    filterSpeeches(speeches, { ...INITIAL, q: `"${middlePhrase}"` }).some(
      (row) => row.id === s.id,
    ),
  );
});

test("shared URLs restore all selections and survive repository or custom-domain hosting", () => {
  const state = {
    ...INITIAL,
    q: '"gouden eeuw" kolonialisme & verleden',
    from: 1984,
    to: 2020,
    parties: ["groep bontes/van klaveren", "groenlinks"],
    roles: ["mp", "government"],
    speakers: [speeches[12].speakerId],
    tg: ["TG4", "TG2"],
    sw: ["SW3"],
    speech: speeches[12].id,
    view: "patterns",
    page: "methods",
    sort: "oldest",
  };
  const restored = parseState(serializeState(state));
  for (const key of ["parties", "roles", "speakers", "tg", "sw"])
    state[key] = state[key].sort();
  assert.deepEqual(restored, state);
  for (const root of [
    "https://example.org/",
    "https://stefancouperus.github.io/golden_age_dashboard/",
  ]) {
    assert.deepEqual(
      parseState(new URL(root + "#" + serializeState(state)).hash),
      state,
    );
    assert.equal(
      new URL("./data/corpus.json", root).pathname,
      new URL(root).pathname + "data/corpus.json",
    );
  }
  assert.equal(parseState("from=1800&to=2300").from, 1945);
  assert.equal(parseState("from=1950.4").from, 1950);
  assert.equal(parseState("from=2020&to=1950").to, 2020);
  assert.deepEqual(parseState("tg=BAD|TG1").tg, ["TG1"]);
});

test("timeline and complete matrix reconcile with the filtered results, including empty selections", () => {
  for (const rows of [
    speeches,
    filterSpeeches(speeches, {
      ...INITIAL,
      parties: ["sgp"],
      from: 1950,
      to: 2000,
    }),
    [],
  ]) {
    assert.equal(yearCounts(rows).length, 80);
    assert.equal(
      yearCounts(rows).reduce((n, y) => n + y.n, 0),
      rows.length,
    );
    const matrix = matrixCounts(rows);
    assert.equal(matrix.length, 4);
    assert(matrix.every((row) => row.length === 5));
    assert.equal(
      matrix.flat().reduce((a, b) => a + b, 0),
      rows.length,
    );
  }
});

test("filtered CSV round-trips quotes, newlines, full text and evidence pairs", () => {
  const rows = filterSpeeches(speeches, {
    ...INITIAL,
    roles: ["senator", "mep"],
  });
  const exported = csvRows(selectionCSV(rows));
  assert.equal(exported.length, 2);
  rows.forEach((s, i) => {
    assert.equal(exported[i].text, s.text);
    assert.equal(exported[i].speaker, s.speaker);
    assert.equal(exported[i].sample_scope_note, s.scopeNote);
    assert.equal(
      exported[i].temporal_grammar_evidence_en,
      s.evidence.tg.map((e) => e.en).join(" || "),
    );
    assert.equal(exported[i].source_url, s.source);
  });
});

test("evidence highlights retain original offsets and never alter the source text", () => {
  const text = "😀 Hij zei: “Een\n\ngouden eeuw” — letterlijk.";
  const ranges = findRanges(text, "“een gouden eeuw”");
  assert.equal(ranges.length, 1);
  assert.equal(
    text.slice(ranges[0].start, ranges[0].end),
    "“Een\n\ngouden eeuw”",
  );
  assert.equal(
    textSegments(text, ranges)
      .map((s) => s.text)
      .join(""),
    text,
  );
  assert.equal(findRanges(text, "not in the speech").length, 0);
  let matched = 0,
    total = 0;
  for (const s of speeches)
    for (const e of [...s.evidence.tg, ...s.evidence.sw]) {
      total++;
      const hits = findRanges(s.text, e.nl);
      if (hits.length) matched++;
      assert.equal(
        textSegments(s.text, hits)
          .map((s) => s.text)
          .join(""),
        s.text,
      );
    }
  assert.equal(matched, total);
  console.log(`Evidence alignment: ${matched}/${total} fragments matched.`);
});

test("code colours are unique and use text with at least WCAG AA contrast", () => {
  assert.equal(new Set([...TG, ...SW].map((c) => c.color)).size, 9);
  function luminance(hex) {
    const c = hex
      .slice(1)
      .match(/../g)
      .map((v) => parseInt(v, 16) / 255)
      .map((v) => (v <= 0.04045 ? v / 12.92 : ((v + 0.055) / 1.055) ** 2.4));
    return 0.2126 * c[0] + 0.7152 * c[1] + 0.0722 * c[2];
  }
  for (let n = 0; n <= 447; n++) {
    const cell = matrixStyle(n, 447);
    const a = luminance(cell.background),
      b = luminance(cell.color);
    assert((Math.max(a, b) + 0.05) / (Math.min(a, b) + 0.05) >= 4.5);
  }
  for (const c of [...TG, ...SW]) {
    const a = luminance(c.color),
      b = luminance(foreground(c.color));
    assert((Math.max(a, b) + 0.05) / (Math.min(a, b) + 0.05) >= 4.5, c.id);
  }
});

test("structured filters reject malformed or unknown values before changing state", () => {
  assert.deepEqual(
    validateFilters(
      { q: "gouden eeuw", roles: ["mp"], tg: ["TG2"], from: 2000 },
      speeches,
    ),
    { q: "gouden eeuw", roles: ["mp"], tg: ["TG2"], from: 2000 },
  );
  for (const input of [
    null,
    [],
    { roles: ["invented"] },
    { speakers: ["not-a-person"] },
    { from: 1800 },
    { q: 7 },
    { deleteData: true },
  ])
    assert.throws(() => validateFilters(input, speeches));
});
