# "Golden Age" Politics Dashboard

Interactive dashboard for exploring how speakers in Dutch parliamentary debate used
the *Gouden Eeuw* ("Golden Age") as a mnemonic trope between 1945 and 2024.

The dashboard presents 447 coded speeches retrieved from a corpus of roughly
three million parliamentary speeches. It supports exploration by period, party,
speaker, temporal grammar, and symbolic work, and links observations back to
official parliamentary records where possible.

## Use the dashboard

The deployed dashboard is available at:

<https://stefancouperus.shinyapps.io/golden-age-dashboard/>

## Run locally

The app requires R 4.3 or newer. From the repository root, install the required
packages and start Shiny:

```r
install.packages(c(
  "shiny", "bslib", "ggplot2", "dplyr", "stringr", "DT", "htmltools",
  "httr", "jsonlite", "plotly"
))

shiny::runApp(".")
```

An `renv.lock` file records the package versions used for this release. To
restore that environment instead:

```r
install.packages("renv")
renv::restore()
shiny::runApp(".")
```

## Repository contents

- `app.R`: dashboard user interface, data preparation, and server logic.
- `ge_final_45_24.rds` and `ge_final_45_24.csv`: 447 coded speeches used by the dashboard.
- `df_snippets_translated.*`: precomputed English translations of coded evidence snippets.
- `data/speaker_profiles.json`: reviewed Parlement.com links for all 244 people,
  with explicit assignments for all 447 contributions. See the [speaker-link audit](docs/speaker-links.md).
- `df_final_speaker_bio_map.*`: legacy biography matches, retained for audit only;
  the app no longer loads them or uses Wikipedia as a biography fallback.
- `gouden_eeuw_seed_dictionary*.csv`, `seed dictionary_add.csv`, and
  `dictplusseed.csv`: dictionaries used to highlight retrieval terms.

The published RDS and CSV datasets contain the corrected metadata and reviewed
speaker names directly. All 447 contributions have the same names and profile
links as the research repository. `speaker_original` preserves the original
corpus label; `speaker_source_label` preserves that label after the earlier
OCR/attribution repairs. The original files remain in Git history at `a619446`.

The app validates the eleven [metadata repairs](docs/metadata-audit.md) and
the [speaker registry](docs/speaker-links.md) when loading data. Verbeek's
Eerste Kamer speech remains included provisionally with a visible
`sample_scope_note` identifying it as outside the intended Tweede Kamer scope.

Run the data and app-integration checks from the repository root in a clone
with Git history (used for preservation comparisons):

```sh
Rscript --vanilla tests/metadata_corrections.R
Rscript --vanilla tests/speaker_profiles.R
```

Speaker panels link to the full biography on Parlement.com and show the role and
recorded affiliation at the selected contribution. Speaker filters and statistics
use the reviewed identities, distinguishing shared surnames and combining member
references that changed between corpus versions. Biography prose and photos are
not copied into the dashboard. These repository updates have not been redeployed
to the existing Shiny service.

No API key is stored in this repository. Optional on-demand translation
uses a LibreTranslate endpoint configured through `LIBRETRANSLATE_URL` and,
where required, `LIBRETRANSLATE_API_KEY`.

## Related research

The dashboard accompanies:

> Couperus, Stefan, and Martijn Schoonvelde. "Golden Age Politics: A
> Computational-Interpretive Analysis of the 'Gouden Eeuw' as a Trope in Dutch
> Parliamentary Speech, 1945-2024." Forthcoming in *Revived Futures: The Turn
> to the Past in European Party Politics*, edited by Katarina Pettersson,
> Katarina Eriksson, and Monika Menke. Palgrave Macmillan, 2026.

The broader reproduction materials are maintained separately at
<https://github.com/hjmschoonvelde/gouden_eeuw_project>.

## Authors

- Stefan Couperus, University of Groningen
- Martijn Schoonvelde, University of Groningen

## Citation

Citation metadata are provided in `CITATION.cff`. DOI to be found here: https://zenodo.org/records/21003433

## License

The software source code is licensed under the MIT License; see `LICENSE`.
The license does not grant rights over third-party content represented in the
derived research data, including parliamentary speech text. Rights in that
content remain subject to the terms of the original sources.
