import test from "node:test";
import assert from "node:assert/strict";
import { readFileSync } from "node:fs";
import React from "react";
import { renderToStaticMarkup } from "react-dom/server";
import { createServer } from "vite";
import {
  INITIAL,
  CODES,
  prepareSpeeches,
  evidenceRanges,
  textSegments,
} from "../src/domain.js";

test("research views render populated, exceptional and empty selections", async () => {
  const server = await createServer({
    server: { middlewareMode: true },
    appType: "custom",
  });
  try {
    const {
      Reader,
      Filters,
      Patterns,
      Information,
      Timeline,
      AuthorLinks,
      Code,
    } = await server.ssrLoadModule("/src/components.jsx");
    const corpus = JSON.parse(
      readFileSync(new URL("../public/data/corpus.json", import.meta.url)),
    );
    const speeches = prepareSpeeches(corpus.speeches);
    const render = (component, props) =>
      renderToStaticMarkup(React.createElement(component, props));
    const update = () => {};
    const filters = render(Filters, {
      speeches,
      state: INITIAL,
      update,
      reset: update,
      closeMobile: update,
    });
    assert.match(filters, /Temporal grammar/);
    assert.match(filters, /Speaking role/);
    assert.match(filters, /Party affiliation/);
    assert.doesNotMatch(filters, /No affiliation recorded/);
    for (const code of Object.values(CODES)) {
      const badge = render(Code, { id: code.id });
      assert(badge.includes(code.meaning), code.id);
      assert(filters.includes(code.meaning), `${code.id} filter explanation`);
      assert.match(badge, /role="tooltip"/);
      const description = badge.match(/aria-describedby="([^"]+)"/)[1];
      assert(badge.includes(`id="${description}"`));
      assert.match(badge, /tabindex="0"/);
      const cardBadge = render(Code, { id: code.id, focusable: false });
      assert.doesNotMatch(cardBadge, /tabindex=|role="button"/);
    }

    for (const rows of [speeches, []]) {
      const matrix = render(Patterns, { rows, state: INITIAL, update });
      assert.equal((matrix.match(/<td>/g) || []).length, 20);
      assert.match(matrix, /SW5/);
      assert.equal(
        (
          render(Timeline, { rows, state: INITIAL, update }).match(
            /<button /g,
          ) || []
        ).length,
        80,
      );
    }
    const verbeek = speeches.find((s) => s.role === "senator");
    const reader = render(Reader, {
      speech: verbeek,
      copyLink: update,
      filterSpeaker: update,
      outsideSelection: true,
      clearForSpeech: update,
    });
    assert.match(reader, /outside the current selection/);
    assert.match(reader, /Read the full Dutch speech/);
    assert.match(reader, /ENGLISH TRANSLATION/);
    assert(reader.includes(verbeek.biography));
    assert.match(reader, /All evidence for both codes is highlighted/);
    assert.match(reader, /--evidence-tg:/);
    assert.match(reader, /--evidence-sw:/);
    const minister = speeches.find((s) => s.speaker === "Eric Wiebes" && s.date === "2019-04-02");
    const ministerReader = render(Reader, {
      speech: minister,
      copyLink: update,
      filterSpeaker: update,
      clearForSpeech: update,
    });
    assert.match(ministerReader, /VVD/);
    assert.match(ministerReader, /Government speaker/);
    assert.match(ministerReader, /Minister of Economic Affairs and Climate Policy/);
    assert.match(ministerReader, /Minister van Economische Zaken en Klimaat/);
    const overlapping = speeches.find((speech) =>
      textSegments(speech.text, evidenceRanges(speech)).some(
        (part) => part.families.includes("tg") && part.families.includes("sw"),
      ),
    );
    const overlapReader = render(Reader, {
      speech: overlapping,
      copyLink: update,
      filterSpeaker: update,
      clearForSpeech: update,
    });
    assert(overlapReader.includes('class="text-highlight tg sw overlap"'));

    for (const range of evidenceRanges(verbeek)) {
      assert(
        new RegExp(`data-evidence-ids="[^"]*${range.evidenceId}(?: |")`).test(
          reader,
        ),
        range.evidenceId,
      );
    }

    const about = render(Information, { navigate: update, copy: update });
    assert.match(about, /572 candidate speeches/);
    assert.match(about, /<h2>Authors<\/h2>/);
    assert.match(about, /Data can be shared upon request/);
    assert.doesNotMatch(about, /download=|Download|data\/research\.csv/);
    const authors = render(AuthorLinks, {});
    for (const url of [
      "https://www.rug.nl/staff/s.couperus/",
      "https://www.rug.nl/staff/martijn.schoonvelde/",
    ]) {
      assert(about.includes(url));
      assert(authors.includes(url));
    }
  } finally {
    await server.close();
  }
});
