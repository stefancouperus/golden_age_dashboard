# Static dashboard: implementation and validation

The React/Vite explorer replaces the Shiny interface for static hosting on
GitHub Pages. It preserves the analytical sample and implements the agreed
mixed-audience layout: a short introduction followed by detailed research tools.

## Data provenance

The site reads a versioned copy of the updated research CSV directly. The
exporter does not load the legacy RDS, metadata repair ledger, or biography
matching code. The website publishes only the JSON needed by the explorer; the direct CSV download has been removed.

- Research repository: https://github.com/hjmschoonvelde/gouden_eeuw_project
- Commit: `4a977ca124d3f9e2fdfa4391e4443c04f2bb569c`
- File: `data/derived/ge_final_45_24.csv`
- SHA-256: `98eeaf07539ee5799fd6e60a19fc3ee5cd9e2640cd7e853c09a2d8ae8e83cc68`
- 447 contributions, 244 reviewed people, and 1,870 paired evidence fragments.
- Speaking roles: 375 Tweede Kamer members, 70 government contributions,
  one visiting MEP, and one provisionally retained Eerste Kamer contribution.

Names, biography URLs, original labels, role and scope notes come from that
updated dataset. Dutch speech text and coding assignments are unchanged.
Precomputed evidence translations join by speech ID and never provide identity
metadata. `gl` and `groenlinks` share the displayed GroenLinks filter; original
`party_ref` values remain in the source snapshot and website JSON. Missing recorded affiliation remains
separate from government role. Verbeek’s agreed provisional-retention note is
visible in the reader and preserved in the website data.

## Interface and interpretation

Shared filters apply to the timeline, results and coding matrix. Multiple values within a field use OR; different fields use AND. Facet
counts reflect the other filters. Search covers Dutch full text, evidence in
both languages, reviewed/original names, party labels and coding rationales.
Quoted phrases are supported.

The matrix includes every combination of four TG and five SW codes. Counts and
percentages describe the selected analytical sample; they are not rates across
all parliamentary speeches. The percentage denominator is shown explicitly.

Temporal grammar uses four blue shades, symbolic work five amber/orange shades.
Code IDs and text labels supplement colour. Label foregrounds and matrix counts
are chosen for at least 4.5:1 text contrast. This numeric check does not establish
complete visual or accessibility compliance.

The reader pairs original Dutch evidence with precomputed English translations,
links the selected evidence to its location in the unchanged full text, and
provides coding rationales, research notes, biographies and original proceedings.
Every TG and SW evidence fragment is highlighted simultaneously in the full
Dutch text, using the same specific code colours and readable foregrounds as
the matrix labels. Overlap uses a neutral background and two underline bands,
one in each exact code colour. A visible legend explains the two codes and
combined treatment; hover titles and keyboard descriptions identify the labels.
Search adds a dotted outline without clearing the evidence highlights, and
“Locate in the Dutch speech” moves to the requested fragment. The mobile layout
uses a native modal reader. Share links retain filters and
speech identifiers; browser back/forward restores the URL state. Relative
assets and hash state support both project-path and future custom-domain hosting.

## Validation on 11 September 2026

`npm test`: all 12 current checks pass. Coverage includes:

- Exact upstream CSV digest and absence of the retired public CSV download.
- Every speech’s full text, identity, biography, role, original labels, codes,
  rationales and scope note compared with the updated research CSV.
- Every Dutch/English evidence pair compared with the stored translations.
- All 1,870 Dutch evidence fragments located in their unchanged source speeches;
  highlight offsets preserve Unicode, whitespace, quotation marks and full text.
- Combined filters, empty selections, historical names, and English evidence search.
- Shared state round-trips at a root domain and repository path.
- Timeline and all 20 matrix cells reconcile with the selected records.
- Code-label and matrix text contrast.
- Nested, identical and adjacent evidence ranges, plus searches crossing their
  boundaries, preserve the original text and every applicable label.
- All fragments remain represented simultaneously in all 447 speeches;
  227 speeches have TG/SW evidence overlap.
- Component rendering for filters, reader, About, exceptional records, and
  populated/empty charts; verified author links and the data-request note.
- Old data-page URLs resolve to About while preserving their filters.

`npm run build` produces the static `dist/` site. The GitHub workflow repeats
installation, tests and build before uploading and deploying that artifact.
The deployed files contain the website and public data, not legacy R assets.

All 350 distinct official source-document links returned HTTP 200 with redirects
followed. Results are recorded in [source-link-checks.csv](source-link-checks.csv).
An HTTP response confirms availability, not the content of every PDF page.
The earlier speaker identity and biography review is documented separately in
[speaker-links.md](speaker-links.md).

A browser was not available for visual or interactive browser verification.
Component rendering and data tests are not substitutes for that review. The
optional WebMCP registration is feature-detected and uses the same filter
validator/actions as the interface; its browser integration remains unverified.
Ordinary use does not require that API.

## Data availability and author links

The navigation now contains Explore and About & methods. Both full-data and
selection downloads are removed, and the data exporter no longer produces the
retired CSV asset. About preserves the study citation and adds the note:
“Data can be shared upon request. Please contact either author through their
University of Groningen profile.”

Both About and the footer link to the verified institutional profiles:

- Stefan Couperus: https://www.rug.nl/staff/s.couperus/
- Martijn Schoonvelde: https://www.rug.nl/staff/martijn.schoonvelde/

The static explorer still serves the JSON required to display its speeches.
Removing download controls does not make that data or existing repository/release
copies private. No research records or historical release tags were altered.

## Hosting

The owner made the repository public and GitHub Pages was configured with the
Actions build source. Publication uses the workflow in `.github/workflows/pages.yml`.
The expected URL is https://stefancouperus.github.io/golden_age_dashboard/.
A later custom domain can be configured in GitHub Pages without changing the
application’s routes or data preparation. The original Shiny deployment is
separate and has not been updated by this migration.
