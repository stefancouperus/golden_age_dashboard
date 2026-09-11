# Golden Age Politics

A static research explorer for the *Gouden Eeuw* (“Golden Age”) in Dutch
parliamentary speech, 1945–2024. The dashboard presents 447 coded contributions
by 244 reviewed speakers, with an accessible introduction and detailed research tools.

The new React/Vite website replaces the Shiny interface in this repository.
Its data come directly from the **updated research dataset**, captured at a
specific commit. The website does not apply correction overlays to the old RDS.

## Explore

- Search full Dutch speeches, English evidence, and original or reviewed names.
- Combine period, party, speaker, speaking role, and coding filters.
- Explore a timeline and all 20 temporal-grammar × symbolic-work combinations.
- Read paired evidence translations, coding rationales and full Dutch speeches.
- See all TG and SW evidence together in the exact code colours; overlapping passages carry both colours as underline bands.
- Hover over coding labels to read the same definitions as About; focus or tap a badge to inspect its explanation.
- Follow reviewed Parlement.com biographies and original parliamentary records.
- Share a selection or individual speech by URL.
- Find the authors’ University of Groningen profiles and data-request information under About.

Temporal grammar uses four distinct blues; symbolic work uses five amber/orange
shades. Text labels identify every code. Government role and party
are separate filters. Verbeek’s contribution remains included provisionally,
with its explicit Eerste Kamer scope note.

## Run locally

Use Node.js 22.12+ (Node 22 LTS recommended) and Python 3 for the data-preservation
checks. R is needed only when deliberately regenerating the website data.

```sh
npm ci
npm run dev
```

Open the local URL printed by Vite. To check and build the production website:

```sh
npm test
npm run build
npm run preview
```

The deployable site is `dist/`. It needs only static hosting.

## Publish with GitHub Pages

The [build and publish workflow](.github/workflows/pages.yml) checks the data
and interface components, builds the website, and uploads the `dist/` artifact.
Publication runs from `main` after Pages is available.

The public repository is configured to publish through GitHub Actions at:

**[Open the dashboard](https://stefancouperus.github.io/golden_age_dashboard/)**

Pushes to `main` rebuild and publish after the checks pass. To republish without
a code change, choose **Actions → Build and publish dashboard → Run workflow**.
The workflow reports the deployment status and live URL. Only `dist/` is published.

The site uses relative assets and hash-based shared selections, so it supports
both the repository path and a future custom domain. When that domain is chosen,
configure it in Pages and its DNS settings; the application needs no route rewrite.

## Updated research data

The source is [`hjmschoonvelde/gouden_eeuw_project`](https://github.com/hjmschoonvelde/gouden_eeuw_project),
`data/derived/ge_final_45_24.csv`. The exact upstream commit and SHA-256 digest are
recorded in [`data/research/source.json`](data/research/source.json).

The dashboard offers no data downloads. Its About section states that data can
be shared upon request and links to both authors’ University of Groningen profiles.
The display data remain publicly served as JSON for the static explorer; removing
download controls does not restrict access to existing public repository files
or previously archived releases.

To adopt a later research update explicitly:

```sh
python3 scripts/sync_research_data.py
Rscript --vanilla scripts/export_site_data.R
npm test
npm run build
```

The R export requires `jsonlite`. Review and commit the source snapshot, manifest,
and regenerated `public/data/` files together. Normal builds use the committed
snapshot and do not fetch a changing upstream branch.

The export preserves speech text, codes, reviewed identities, original speaker
labels, biographies, role, and scope notes. Existing precomputed translations
join strictly by speech ID; translation files do not supply speaker metadata.
All evidence pairs must be present. A future change to the analytical sample or
coding scheme requires reviewing the exporter’s explicit invariants and tests.

`gl` and `groenlinks` are combined under the displayed GroenLinks filter;
`party_ref` is imported directly from the research snapshot. The
[government metadata review](docs/government-metadata.md) supplies verified
affiliations and dated positions for all 70 government contributions by 47
speakers. English positions appear in the cards and reader; English and Dutch
positions are searchable. Government role and party affiliation remain separate.

## Project files

| Location | Purpose |
| --- | --- |
| `src/` | Interface, filtering, URL state, evidence reader and colours |
| `scripts/` | Explicit research snapshot update and R-to-JSON export |
| `data/research/` | Exact versioned upstream CSV and provenance |
| `public/data/` | Website JSON used by the explorer |
| `tests/*.test.js` | Preservation, filters, evidence alignment and component checks |
| `docs/static-dashboard.md` | Implementation and validation record |

The legacy `app.R`, R environment, root data files and earlier metadata audits
remain available for research provenance and historical reproduction. The new
website does not load them. They are excluded from `dist/`. The previous Shiny
service has not been redeployed by this migration:
<https://stefancouperus.shinyapps.io/golden-age-dashboard/>.

## Research and citation

> Couperus, Stefan, and Martijn Schoonvelde. “Golden Age Politics: A
> Computational-Interpretive Analysis of the ‘Gouden Eeuw’ as a Trope in Dutch
> Parliamentary Speech, 1945–2024.” Forthcoming in *Revived Futures: The Turn
> to the Past in European Party Politics*, edited by Katarina Pettersson,
> Katarina Eriksson, and Monika Menke. Palgrave Macmillan, 2026.

Both authors are affiliated with the University of Groningen.
Software citation metadata are provided in [`CITATION.cff`](CITATION.cff).
The earlier dashboard record remains at <https://zenodo.org/records/21003433>.

## License

The software source code is licensed under MIT; see [`LICENSE`](LICENSE).
Third-party parliamentary texts remain subject to their original sources’ terms.
Biography prose and photographs are not reproduced.
