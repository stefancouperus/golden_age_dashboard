import test from "node:test";
import assert from "node:assert/strict";
import { readFileSync } from "node:fs";
import React from "react";
import { renderToStaticMarkup } from "react-dom/server";
import { createServer } from "vite";
import { INITIAL, prepareSpeeches } from "../src/domain.js";

test("research views render populated, exceptional and empty selections", async () => {
  const server = await createServer({
    server: { middlewareMode: true },
    appType: "custom",
  });
  try {
    const { Reader, Filters, Patterns, Information, Timeline } =
      await server.ssrLoadModule("/src/components.jsx");
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
    assert.match(filters, /No affiliation recorded/);
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
    assert.match(reader, /retained provisionally/);
    assert.match(reader, /outside the current selection/);
    assert.match(reader, /Read the full Dutch speech/);
    assert.match(reader, /ENGLISH TRANSLATION/);
    assert(reader.includes(verbeek.biography));
    assert.match(
      render(Information, {
        page: "methods",
        source: corpus.source,
        navigate: update,
        copy: update,
      }),
      /572 candidate speeches/,
    );
    assert.match(
      render(Information, {
        page: "data",
        source: corpus.source,
        navigate: update,
        copy: update,
      }),
      /href="\/data\/research.csv"/,
    );
  } finally {
    await server.close();
  }
});
