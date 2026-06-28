# "Golden Age" Politics Dashboard

Interactive R Shiny dashboard for exploring how Dutch members of parliament used
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
  "httr", "jsonlite", "legislatoR", "plotly", "rvest", "xml2"
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
- `df_final_speaker_bio_map.*`: precomputed speaker metadata used in profile panels.
- `gouden_eeuw_seed_dictionary*.csv`, `seed dictionary_add.csv`, and
  `dictplusseed.csv`: dictionaries used to highlight retrieval terms.

The RDS files are used by the app; CSV copies are included for inspection and
reuse. No API key is stored in this repository. Optional on-demand translation
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

Citation metadata are provided in `CITATION.cff`. A DOI will be added after the
first GitHub release is archived by Zenodo.

## License

The software source code is licensed under the MIT License; see `LICENSE`.
The license does not grant rights over third-party content represented in the
derived research data, including parliamentary speech text. Rights in that
content remain subject to the terms of the original sources.
