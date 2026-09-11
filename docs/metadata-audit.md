# Speaker, role and party metadata audit

Reviewed 11 September 2026, before migration from Shiny to GitHub Pages.

The nine records initially displayed as government speakers because they lacked
a party value were not nine verified MPs. The source review identifies six MP
contributions, two ministerial contributions and one visiting MEP contribution.
A consistency check also identified an opposite error: Asscher's 2018
contribution was recorded as government even though he was then an MP.

## Corrections

The machine-readable [correction ledger](../data/metadata_corrections.json)
contains exact speech IDs, expected original values, changes, source locations,
biography links and reasons. Dates below identify the contributions, not a
politician's entire career.

| Date | Original speaker label | Corrected identification and capacity | Party information | Parliamentary source |
|---|---|---|---|---|
| 1949-05-17 | Welter zet zijn rede voort en | Charles Welter, MP; remove a continuation instruction from the name | KNP | [Proceedings](https://resolver.kb.nl/resolve?urn=sgd:mpeg21:19481949:0000487:pdf); same sitting's correctly identified Welter turn |
| 1950-11-10 | Holtrop | Charles Welter, MP; the parser mistook his quotation of Holtrop for a speaker change | KNP | [Scan](https://resolver.kb.nl/resolve?urn=sgd:mpeg21:19501951:0000563:pdf), printed p. 426, PDF p. 14, and continuing page headers |
| 1960-02-18 | Schüüuiis | Tineke Schilthuis, MP; repair OCR-damaged name | PvdA | [Scan](https://resolver.kb.nl/resolve?urn=sgd:mpeg21:19591960:0002136:pdf), printed p. 3690, PDF p. 28 |
| 1965-02-23 | Scholten, Minister van Justitie | Ynso Scholten, Minister of Justice; change role to government and replace the incorrectly matched Willem Scholten biography | Source party field stays missing; personal CHU affiliation is separate | [Proceedings](https://resolver.kb.nl/resolve?urn=sgd:mpeg21:19641965:0000782:pdf); another ministerial reply in the debate supplies the member reference |
| 1968-09-24 | Polak, Minister van Justitie | Carel Polak, Minister of Justice; change role to government and replace the incorrectly matched Henri Polak biography | Source party field stays missing; personal VVD affiliation is separate | [Proceedings](https://resolver.kb.nl/resolve?urn=sgd:mpeg21:19681969:0000711:pdf); adjacent ministerial replies supply the member reference |
| 1974-02-12 | Van Veenen | Fia van Veenendaal-van Meggelen, MP; repair a split, OCR-damaged surname | DS'70 | [Scan](https://resolver.kb.nl/resolve?urn=sgd:mpeg21:19731974:0000729:pdf), printed p. 2436, PDF p. 34 |
| 1984-05-01 | Verbeek | Jan Verbeek, VVD senator; change role to `senator`. This is an Eerste Kamer sitting | VVD, already recorded | [Scan](https://resolver.kb.nl/resolve?urn=sgd:mpeg21:19831984:0000028:pdf), printed p. 896, PDF p. 34; [biography](https://www.parlement.com/biografie/jw-jan-verbeek) |
| 1996-10-10 | Van Middelkoop | Eimert van Middelkoop, MP, speaking for the parliamentary climate committee | GPV affiliation; this does not make the committee's argument a party position | [Proceedings](https://zoek.officielebekendmakingen.nl/h-tk-19961997-637-661.html) |
| 2000-09-28 | Van Middelkoop | Eimert van Middelkoop, MP | GPV component-party affiliation; retain the source's joint group label **RPF/GPV** separately | [Proceedings](https://zoek.officielebekendmakingen.nl/h-tk-20002001-338-357.html) |
| 2012-02-09 | Gerbrandy (EP/D66) | Gerben-Jan Gerbrandy, visiting MEP; separate role `mep` and replace the incorrectly matched Pieter Sjoerds Gerbrandy biography | D66 | [Proceedings](https://zoek.officielebekendmakingen.nl/h-tk-20112012-52-9.html), including the chair's introduction of visiting MEPs |
| 2018-06-13 | Asscher | Lodewijk Asscher, MP; change role from government to MP | PvdA, already recorded | [Proceedings](https://zoek.officielebekendmakingen.nl/h-tk-20172018-93-4.html) |

The subsequent review of every speaker biography identified Verbeek's 1984
contribution as an Eerste Kamer speech. The scan confirms both his VVD
maiden speech and the chamber. This eleventh correction adds `senator` as a
distinct speaking role. The original `mp` count above reflects the source label,
which did not correctly distinguish this contribution.

The older XML references in the ledger identify the research corpus files in
the parent project's `Data/` directory; they are not bundled in this repository.
The official scan URLs and printed-page references provide public source access.

## Result and interpretation

| Role | Original data | Corrected data |
|---|---:|---:|
| MP / Tweede Kamer (`mp`) | 378 | 375 |
| Eerste Kamer senator | 0 | 1 |
| Government speaker | 69 | 70 |
| Visiting MEP | 0 | 1 |
| **Total contributions** | **447** | **447** |

Seven missing party affiliations are filled. No non-government contribution
retains a missing party. Government role and party affiliation remain separate:
69 of the 70 government contributions lack a recorded party, while Willem
Scholten's 1973 contribution already records CHU. Consequently the legacy party
filter's government bucket contains 69 records, not the 70 government-role
records. A future role filter must use `role`, not that party bucket.

Party metadata describes affiliation at the time of a contribution. It does not
establish that a minister, committee representative or visiting MEP speaks for
a Tweede Kamer party group. Separate capacity and group fields retain these
distinctions and are shown in the Shiny speech reader.

## Reproducibility and limits

- The original RDS and CSV files are unchanged. `R/metadata_corrections.R`
  applies the reviewed ledger when the app loads, retains original metadata in
  separate fields, and rejects unexpected changes to the reviewed source values.
- All 447 speech IDs, texts, dates, evidence, rationales, inclusion decisions and
  temporal-grammar/symbolic-work assignments are unchanged. This is a metadata
  repair, not a recoding or a change to the analytical sample.
- Gerbrandy's MEP contribution and Verbeek's Eerste Kamer speech remain in the
  sample and are explicitly labelled. Excluding either would change the research scope and requires a separate decision.
- The 1950 Welter record begins partway through the original contribution because
  the parser assigned its earlier portion to a stage direction. This repair
  corrects attribution without silently expanding the coded text. The scan
  remains the authority for the complete parliamentary contribution.
- The metadata repair helper clears dates and offices belonging to the wrong
  person in the legacy biography map. The app now uses the separately
  [reviewed Parlement.com registry](speaker-links.md) for every speaker;
  it no longer loads the old biography map or fetches Wikipedia biographies.
- `Rscript --vanilla tests/metadata_corrections.R` checks preservation of the
  original research content, the eleven corrections, role totals, missing-party
  handling, biography repairs, repeatability, source drift rejection and actual
  Shiny data/profile integration. It does not test rendered browser behaviour.

These changes take effect when this repository's app is run. They do not
redeploy the separately hosted shinyapps.io application.
