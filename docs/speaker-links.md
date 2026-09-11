# Reviewed speaker biography links

Reviewed 11 September 2026. All **447 contributions** have a direct Parlement.com
biography link, covering **244 distinct people**. Every selected page returned
HTTP 200 during this review. Availability was checked on this date; it is not a
promise that external URLs will remain unchanged.

## Matching and use

The [registry](../data/speaker_profiles.json) contains one entry per person and
an explicit speech-to-person assignment for every contribution. Each assignment
retains the expected source label, date, role, party and member reference, after
the [metadata corrections](metadata-audit.md). `R/speaker_profiles.R` rejects
unexpected changes to those fields or incomplete coverage.

Candidates were found through Parlement.com's [biography search](https://www.parlement.com/personen-hoe-werkt-het#p4).
The match was reviewed against the contribution date, the corresponding office
held at that date, and the recorded party where available. Ambiguous surnames
were resolved using those details and, where needed, the parliamentary record.
The old biography match was only a hint, not evidence of identity. A minister's
personal party affiliation is not used to fill a missing contribution-level
party field.

The 247 distinct member-reference groups resolve to 244 people: Martin Bosma,
Sandra Beckerman and Tunahan Kuzu each have two member references across corpus
versions. Conversely, surname labels such as Bakker, De Koning and Diepenhorst
represent different people and must not be pooled. Display names follow the
reviewed biography, generally using the given name shown in parentheses.
Reviewed names are now written into both repositories' published datasets.
`speaker_original` preserves the unmodified corpus label, while
`speaker_source_label` preserves the label after the earlier OCR/attribution
repairs. These are distinct from the reviewed full name in `speaker`.
`speaker_person_id` and `speaker_profile_url` provide a stable identity and a
direct biography link. The original dashboard files remain in Git history at
`a619446`; the original research files remain at `05c5f4e`.

The research analytic CSV updates 422 existing speaker labels, mostly by
expanding surname-only labels to identify the person. These are not 422
incorrect-person matches. The candidate file receives the same changes for
the 447 overlapping contributions; the validation sample updates 41 labels
among its 45 overlapping contributions. Names outside this reviewed sample
are unchanged and have blank person/profile fields.

The app's profile panel links to the biography and displays the selected
contribution's date, role and recorded affiliation. It does not fetch biographies
at runtime. The old surname matcher and Wikipedia fallback have been removed.
Only names, links and our matching notes are published; biography text and
photographs remain on Parlement.com.

## Additional incorrect biography matches

These ten identities correct the old precomputed biography map, beyond the
previously reviewed Ynso Scholten, Carel Polak and Gerben-Jan Gerbrandy cases.
They do not change speech texts or analytical codes.

| Correct person | Incorrect old biography | Basis for distinguishing the person |
|---|---|---|
| Dien Cornelissen | Pam Cornelissen | The 1976 sitting identifies Mevrouw Cornelissen, member 01655; Pam speaks separately as De heer, member 00270 |
| Jan de Graaf | Louw de Graaf | CDA MP in October 1991; office dates |
| Jan de Koning (born 1937) | Marijn de Koning | Boerenpartij and 1976 date |
| Isaäc A. Diepenhorst | I.N.Th. Diepenhorst | Ministerial office in 1965 |
| Piet Hein Donner | Johannes Hendricus Donner | Ministerial office and contribution date |
| Wouter Gortzak | Henk Gortzak | PvdA MP in 2001 |
| Jozias van Aartsen | Jan van Aartsen | Ministerial office and contribution date |
| Willibrord van Beek | Cas van Beek | VVD MP and contribution date |
| Martijn van Dam | Marcel van Dam | PvdA MP and contribution date |
| Cees Veerman | Antoon Veerman | Ministerial office and contribution date |

The same review identified **Jan Verbeek as an Eerste Kamer senator**. His
1 May 1984 contribution is in an Eerste Kamer sitting, confirmed by the
[original scan](https://resolver.kb.nl/resolve?urn=sgd:mpeg21:19831984:0000028:pdf),
printed p. 896 / PDF p. 34, and his
[biography](https://www.parlement.com/biografie/jw-jan-verbeek).
The role is corrected to `senator` in both repositories.

Jan Verbeek's 1 May 1984 speech is outside the intended Tweede Kamer scope.
The original text itself retains Eerste Kamer page footers, independently of
the biography match. It is retained provisionally in the 447-contribution
sample at the researcher's request, pending a separate scope decision. This
does not expand the intended scope of the study. The row-level
`sample_scope_note` makes the exception visible without changing the original
inclusion decision, coding or speech text.
The corrected sample contains 375 Tweede Kamer MP contributions, 70 government
contributions, one senator contribution and one visiting MEP contribution.

## Complete link inventory

Dates below are the first and last included contributions for each person,
not their full career. The registry supplies every individual speech ID.

| Speaker and biography | First contribution | Last contribution | Contributions |
|---|---|---|---:|
| [Aad Nuis](https://www.parlement.com/biografie/drs-aad-nuis) | 1988-04-19 | 1997-11-13 | 4 |
| [Aad Wagenaar](https://www.parlement.com/biografie/drs-ahd-aad-wagenaar) | 1983-01-17 | 1983-01-17 | 1 |
| [Ad Melkert](https://www.parlement.com/biografie/drs-apw-ad-melkert) | 1993-10-12 | 1993-10-12 | 1 |
| [Adri Duivesteijn](https://www.parlement.com/biografie/ath-adri-duivesteijn) | 2002-11-12 | 2002-11-12 | 1 |
| [Agnes Nolte](https://www.parlement.com/biografie/ah-agnes-nolte) | 1962-03-21 | 1962-03-21 | 1 |
| [Alexander Pechtold](https://www.parlement.com/biografie/drs-alexander-pechtold) | 2010-12-14 | 2015-06-02 | 3 |
| [Anne Mulder](https://www.parlement.com/biografie/anne-mulder) | 2014-11-26 | 2014-11-26 | 1 |
| [Annelien Kappeyne van de Coppello](https://www.parlement.com/biografie/mr-annelien-kappeyne-van-de-coppello) | 1983-01-31 | 1983-01-31 | 1 |
| [Ans Willemse-van der Ploeg](https://www.parlement.com/biografie/aam-ans-willemse-van-der-ploeg) | 2008-01-23 | 2008-01-23 | 1 |
| [Anton Roosjen](https://www.parlement.com/biografie/mr-ab-anton-roosjen) | 1955-07-12 | 1955-07-12 | 1 |
| [Arie van der Hek](https://www.parlement.com/biografie/dr-arie-van-der-hek) | 1978-12-19 | 1983-02-09 | 3 |
| [Aukje de Vries](https://www.parlement.com/biografie/aukje-de-vries) | 2019-10-02 | 2019-10-02 | 1 |
| [Barbara Visser](https://www.parlement.com/biografie/drs-b-barbara-visser) | 2015-10-28 | 2015-10-28 | 1 |
| [Barry Madlener](https://www.parlement.com/biografie/b-barry-madlener) | 2024-06-11 | 2024-06-11 | 1 |
| [Bart Verbrugh](https://www.parlement.com/biografie/dr-aj-bart-verbrugh) | 1973-02-06 | 1981-04-28 | 9 |
| [Bas van der Vlies](https://www.parlement.com/biografie/ir-bj-bas-van-der-vlies) | 1982-12-09 | 2006-09-28 | 11 |
| [Ben Hennekam](https://www.parlement.com/biografie/drs-bmj-ben-hennekam) | 1980-11-19 | 1980-11-19 | 1 |
| [Bernard Verhoeven](https://www.parlement.com/biografie/bj-bernard-verhoeven) | 1950-09-22 | 1958-12-03 | 2 |
| [Bert Bakker](https://www.parlement.com/biografie/ad-bert-bakker) | 2006-10-18 | 2006-10-18 | 1 |
| [Bert Koenders](https://www.parlement.com/biografie/drs-ag-bert-koenders) | 1998-12-02 | 2006-10-19 | 2 |
| [Berthe Groensmit-van der Kallen](https://www.parlement.com/biografie/amcv-berthe-groensmit-van-der-kallen) | 1973-02-07 | 1973-02-07 | 1 |
| [Boris van der Ham](https://www.parlement.com/biografie/b-boris-van-der-ham) | 2005-02-22 | 2005-02-22 | 1 |
| [C.N. van Dis](https://www.parlement.com/biografie/ir-cn-van-dis) | 1946-12-13 | 1970-12-03 | 12 |
| [Carel Polak](https://www.parlement.com/biografie/mr-chf-carel-polak) | 1968-09-24 | 1968-09-24 | 1 |
| [Cees Berkhouwer](https://www.parlement.com/biografie/dr-c-cees-berkhouwer) | 1965-02-23 | 1965-02-23 | 1 |
| [Cees Veerman](https://www.parlement.com/biografie/dr-cp-cees-veerman) | 2007-02-06 | 2007-02-06 | 1 |
| [Charles Welter](https://www.parlement.com/biografie/chjim-charles-welter) | 1949-05-17 | 1954-06-29 | 6 |
| [Chris van der Klaauw](https://www.parlement.com/biografie/dr-cha-chris-van-der-klaauw) | 1980-09-15 | 1980-09-15 | 1 |
| [Christine Teunissen](https://www.parlement.com/biografie/ch-christine-teunissen) | 2023-01-25 | 2023-01-25 | 1 |
| [Cor Borst](https://www.parlement.com/biografie/c-cor-borst) | 1948-11-16 | 1948-11-16 | 1 |
| [Cor van Dis Jr.](https://www.parlement.com/biografie/cn-cor-van-dis-jr) | 1977-03-09 | 1992-11-12 | 3 |
| [Daniël van der Ree](https://www.parlement.com/biografie/drs-da-daniel-van-der-ree) | 2016-09-29 | 2016-09-29 | 1 |
| [Dick Benschop](https://www.parlement.com/biografie/drs-da-dick-benschop) | 1998-12-03 | 1998-12-03 | 1 |
| [Dick Dees](https://www.parlement.com/biografie/drs-djd-dick-dees) | 1988-03-03 | 1988-03-03 | 1 |
| [Dick Stellingwerf](https://www.parlement.com/biografie/dj-dick-stellingwerf) | 1996-04-23 | 1996-04-23 | 1 |
| [Dick Tommel](https://www.parlement.com/biografie/dr-dkj-dick-tommel) | 1982-02-16 | 1982-02-16 | 1 |
| [Diederik van Dijk](https://www.parlement.com/biografie/djh-diederik-van-dijk) | 2024-03-13 | 2024-03-13 | 1 |
| [Dien Cornelissen](https://www.parlement.com/biografie/gmp-dien-cornelissen) | 1976-06-17 | 1976-06-17 | 1 |
| [Dion Graus](https://www.parlement.com/biografie/djg-dion-graus) | 2008-10-22 | 2017-12-13 | 3 |
| [Ed Nijpels](https://www.parlement.com/biografie/drs-ehthm-ed-nijpels) | 1988-11-03 | 1988-11-03 | 1 |
| [Eimert van Middelkoop](https://www.parlement.com/biografie/e-eimert-van-middelkoop) | 1996-10-10 | 2000-09-28 | 3 |
| [Elco Brinkman](https://www.parlement.com/biografie/mrdrs-lc-elco-brinkman) | 1985-12-09 | 1986-02-10 | 2 |
| [Elizabeth Schmitz](https://www.parlement.com/biografie/mr-ema-elizabeth-schmitz) | 1997-10-01 | 1997-10-01 | 1 |
| [Els Borst-Eilers](https://www.parlement.com/biografie/dr-e-els-borst-eilers) | 1998-11-26 | 1998-11-26 | 1 |
| [Els Veder-Smit](https://www.parlement.com/biografie/mr-e-els-veder-smit) | 1976-06-17 | 1976-06-17 | 1 |
| [Elske ter Veld](https://www.parlement.com/biografie/e-elske-ter-veld) | 1993-01-28 | 1993-01-28 | 2 |
| [Enric Hessing](https://www.parlement.com/biografie/ir-elp-enric-hessing) | 1998-12-02 | 1998-12-03 | 2 |
| [Eric Balemans](https://www.parlement.com/biografie/erm-eric-balemans) | 2004-06-09 | 2004-06-09 | 1 |
| [Eric Wiebes](https://www.parlement.com/biografie/ir-ed-eric-wiebes) | 2015-03-05 | 2019-04-02 | 3 |
| [Erik Jurgens](https://www.parlement.com/biografie/profmr-ecm-erik-jurgens) | 1974-05-07 | 1974-05-07 | 1 |
| [Esther Ouwehand](https://www.parlement.com/biografie/e-esther-ouwehand) | 2018-06-13 | 2018-06-13 | 1 |
| [Evelien Eshuis](https://www.parlement.com/biografie/drs-el-evelien-eshuis) | 1984-11-19 | 1985-02-27 | 2 |
| [Evert Jan Slootweg](https://www.parlement.com/biografie/drs-ej-evert-jan-slootweg) | 2018-05-23 | 2018-05-23 | 1 |
| [Ewout Irrgang](https://www.parlement.com/biografie/drs-e-ewout-irrgang) | 2006-10-19 | 2006-10-19 | 1 |
| [Fatma Koşer Kaya](https://www.parlement.com/biografie/mr-f-fatma-koser-kaya) | 2008-10-01 | 2008-10-01 | 1 |
| [Femke Halsema](https://www.parlement.com/biografie/drs-f-femke-halsema) | 2006-09-28 | 2006-09-28 | 1 |
| [Ferd Crone](https://www.parlement.com/biografie/drs-fjm-ferd-crone) | 1999-06-23 | 2000-06-20 | 3 |
| [Ferdinand Kranenburg](https://www.parlement.com/biografie/mr-fj-ferdinand-kranenburg) | 1963-03-05 | 1963-03-05 | 1 |
| [Fia van Veenendaal-van Meggelen](https://www.parlement.com/biografie/s-fia-van-veenendaal-van-meggelen) | 1974-02-12 | 1976-06-17 | 2 |
| [Fleur Agema](https://www.parlement.com/biografie/m-fleur-agema) | 2008-01-23 | 2015-12-09 | 2 |
| [Foort van Oosten](https://www.parlement.com/biografie/mr-f-foort-van-oosten) | 2018-01-23 | 2018-01-23 | 1 |
| [Frank Futselaar](https://www.parlement.com/biografie/drs-fw-frank-futselaar) | 2019-04-02 | 2019-04-02 | 1 |
| [Frank Heemskerk](https://www.parlement.com/biografie/drs-f-frank-heemskerk) | 2004-09-14 | 2004-09-14 | 1 |
| [Frits Korthals Altes](https://www.parlement.com/biografie/mr-f-frits-korthals-altes) | 1989-02-23 | 1989-02-23 | 1 |
| [Frits Niessen](https://www.parlement.com/biografie/gaq-frits-niessen) | 1981-04-28 | 1988-04-20 | 3 |
| [Fré Meis](https://www.parlement.com/biografie/f-fre-meis) | 1973-03-14 | 1973-03-14 | 1 |
| [Geert Ruygers](https://www.parlement.com/biografie/gjnm-geert-ruygers) | 1966-12-28 | 1966-12-28 | 1 |
| [Geert Wilders](https://www.parlement.com/biografie/g-geert-wilders) | 2007-09-06 | 2022-09-21 | 5 |
| [Gerard Nederhorst](https://www.parlement.com/biografie/drs-gm-gerard-nederhorst) | 1947-02-05 | 1947-02-05 | 1 |
| [Gerard ter Woorst](https://www.parlement.com/biografie/dr-gj-gerard-ter-woorst) | 1976-06-17 | 1976-06-17 | 1 |
| [Gerard van Leijenhorst](https://www.parlement.com/biografie/drs-g-gerard-van-leijenhorst) | 1976-06-17 | 1976-06-17 | 1 |
| [Gerben-Jan Gerbrandy](https://www.parlement.com/biografie/gjm-gerben-jan-gerbrandy) | 2012-02-09 | 2012-02-09 | 1 |
| [Gerrit Brokx](https://www.parlement.com/biografie/mr-gph-gerrit-brokx) | 1983-11-23 | 1983-11-23 | 1 |
| [Gerrit Jan Wolffensperger](https://www.parlement.com/biografie/mrdrs-gj-gerrit-jan-wolffensperger) | 1991-03-19 | 1991-03-19 | 1 |
| [Gerrit Valk](https://www.parlement.com/biografie/dr-g-gerrit-valk) | 1993-03-23 | 1993-03-23 | 1 |
| [Gerrit Zalm](https://www.parlement.com/biografie/dr-g-gerrit-zalm) | 2007-01-31 | 2007-01-31 | 1 |
| [Gert Schutte](https://www.parlement.com/biografie/gj-gert-schutte) | 1982-01-18 | 1997-04-09 | 9 |
| [Gert-Jan Segers](https://www.parlement.com/biografie/drs-gjm-gert-jan-segers) | 2022-09-22 | 2022-09-22 | 1 |
| [Gijs van Aardenne](https://www.parlement.com/biografie/drs-gmv-gijs-van-aardenne) | 1983-02-09 | 1985-11-14 | 4 |
| [Gonny van Oudenallen](https://www.parlement.com/biografie/hfm-gonny-van-oudenallen) | 2006-09-28 | 2006-09-28 | 1 |
| [Govert Ritmeester](https://www.parlement.com/biografie/g-govert-ritmeester) | 1954-11-26 | 1954-11-26 | 1 |
| [H.F. van Leeuwen](https://www.parlement.com/biografie/mr-hf-van-leeuwen) | 1955-12-08 | 1955-12-08 | 1 |
| [H.J.W.A. Meijerink](https://www.parlement.com/biografie/hjwa-meijerink) | 1948-04-28 | 1948-04-28 | 1 |
| [H.W. Tilanus](https://www.parlement.com/biografie/dr-hw-tilanus) | 1946-11-28 | 1946-11-28 | 1 |
| [Han ten Broeke](https://www.parlement.com/biografie/drs-jh-han-ten-broeke) | 2007-06-27 | 2018-03-06 | 3 |
| [Hanja Maij-Weggen](https://www.parlement.com/biografie/jrh-hanja-maij-weggen) | 1990-11-29 | 1990-11-29 | 1 |
| [Hanke Bruins Slot](https://www.parlement.com/biografie/mrdrs-hgj-hanke-bruins-slot) | 2010-12-07 | 2010-12-07 | 2 |
| [Hans Gualthérie van Weezel](https://www.parlement.com/biografie/mr-jsl-hans-gualtherie-van-weezel) | 1983-02-23 | 1983-02-23 | 1 |
| [Hans Janmaat](https://www.parlement.com/biografie/drs-jgh-hans-janmaat) | 1985-02-27 | 1995-02-16 | 3 |
| [Hans van Mierlo](https://www.parlement.com/biografie/mr-hafmo-hans-van-mierlo) | 1988-03-30 | 1988-03-30 | 1 |
| [Harm Beertema](https://www.parlement.com/biografie/hj-harm-beertema) | 2015-03-24 | 2016-09-14 | 2 |
| [Harry van Bommel](https://www.parlement.com/biografie/drs-h-harry-van-bommel) | 2010-12-15 | 2010-12-15 | 1 |
| [Harry van Doorn](https://www.parlement.com/biografie/mr-hw-harry-van-doorn) | 1975-11-19 | 1977-08-24 | 4 |
| [Hella Voûte-Droste](https://www.parlement.com/biografie/drs-wcg-hella-voute-droste) | 1994-12-06 | 1994-12-06 | 1 |
| [Hendrik Koekoek](https://www.parlement.com/biografie/h-hendrik-koekoek) | 1965-10-13 | 1970-02-18 | 2 |
| [Henk Beernink](https://www.parlement.com/biografie/mr-hkj-henk-beernink) | 1969-10-29 | 1969-10-29 | 1 |
| [Henk Kamp](https://www.parlement.com/biografie/hgj-henk-kamp) | 2005-11-17 | 2006-10-18 | 2 |
| [Henk Kikkert](https://www.parlement.com/biografie/h-henk-kikkert) | 1955-12-13 | 1955-12-13 | 1 |
| [Henk Koning](https://www.parlement.com/biografie/mr-he-henk-koning) | 1967-09-20 | 1990-02-07 | 3 |
| [Henk Korthals](https://www.parlement.com/biografie/drs-ha-henk-korthals) | 1949-01-27 | 1953-07-22 | 2 |
| [Henk Mulderije](https://www.parlement.com/biografie/mr-h-henk-mulderije) | 1952-03-12 | 1952-03-12 | 1 |
| [Henk van Gerven](https://www.parlement.com/biografie/drs-hpj-henk-van-gerven) | 2016-12-01 | 2016-12-01 | 1 |
| [Henk van Rossum](https://www.parlement.com/biografie/ir-h-henk-van-rossum) | 1969-02-18 | 1984-05-30 | 6 |
| [Henk Vermeer](https://www.parlement.com/biografie/h-henk-vermeer) | 2024-06-11 | 2024-06-11 | 1 |
| [Henk Waltmans](https://www.parlement.com/biografie/dr-hjg-henk-waltmans) | 1977-04-21 | 1980-06-19 | 2 |
| [Hette Abma](https://www.parlement.com/biografie/hg-hette-abma) | 1975-03-06 | 1977-08-24 | 3 |
| [Hilde Palland-Mulder](https://www.parlement.com/biografie/mr-hm-hilde-palland-mulder) | 2019-09-04 | 2019-09-04 | 1 |
| [Huib Eversdijk](https://www.parlement.com/biografie/drs-h-huib-eversdijk) | 1979-12-12 | 1979-12-12 | 1 |
| [I.N.Th. Diepenhorst](https://www.parlement.com/biografie/dr-inth-diepenhorst) | 1960-11-29 | 1962-06-20 | 2 |
| [Ien Dales](https://www.parlement.com/biografie/drs-ci-ien-dales) | 1990-03-19 | 1990-03-19 | 1 |
| [Ina Brouwer](https://www.parlement.com/biografie/mr-i-ina-brouwer) | 1993-01-27 | 1993-01-28 | 2 |
| [Isaäc Diepenhorst](https://www.parlement.com/biografie/dr-ia-isaac-diepenhorst) | 1966-03-31 | 1966-03-31 | 1 |
| [Jaap Boersma](https://www.parlement.com/biografie/drs-j-jaap-boersma) | 1971-02-25 | 1971-02-25 | 1 |
| [Jaap Burger](https://www.parlement.com/biografie/mr-jaw-jaap-burger) | 1960-05-10 | 1960-05-10 | 1 |
| [Jaap Jelle Feenstra](https://www.parlement.com/biografie/jj-jaap-jelle-feenstra) | 1990-11-19 | 1990-12-10 | 2 |
| [Jaco Geurts](https://www.parlement.com/biografie/jl-jaco-geurts) | 2018-02-22 | 2018-02-22 | 1 |
| [Jacques Monasch](https://www.parlement.com/biografie/js-jacques-monasch) | 2015-02-10 | 2015-02-10 | 1 |
| [Jan Beekmans](https://www.parlement.com/biografie/drs-japm-jan-beekmans) | 1977-02-17 | 1977-02-17 | 1 |
| [Jan de Graaf](https://www.parlement.com/biografie/ing-j-jan-de-graaf) | 1991-10-28 | 1991-10-28 | 1 |
| [Jan de Koning](https://www.parlement.com/biografie/j-jan-de-koning) | 1976-06-17 | 1976-06-17 | 1 |
| [Jan Dirk Blaauw](https://www.parlement.com/biografie/jd-jan-dirk-blaauw) | 1993-02-18 | 1993-02-18 | 2 |
| [Jan Haken](https://www.parlement.com/biografie/j-jan-haken) | 1955-07-12 | 1955-07-12 | 1 |
| [Jan Marijnissen](https://www.parlement.com/biografie/jgcha-jan-marijnissen) | 1998-12-02 | 2007-12-18 | 9 |
| [Jan Paternotte](https://www.parlement.com/biografie/jm-jan-paternotte) | 2017-12-13 | 2017-12-13 | 1 |
| [Jan Peter Balkenende](https://www.parlement.com/biografie/profdr-jp-jan-peter-balkenende) | 2005-10-12 | 2005-10-12 | 1 |
| [Jan Schaefer](https://www.parlement.com/biografie/jln-jan-schaefer) | 1974-12-17 | 1974-12-17 | 1 |
| [Jan Schmal](https://www.parlement.com/biografie/dr-jjr-jan-schmal) | 1955-03-17 | 1955-03-17 | 1 |
| [Jan te Veldhuis](https://www.parlement.com/biografie/mr-aj-jan-te-veldhuis) | 1990-05-02 | 1993-03-09 | 2 |
| [Jan Terpstra](https://www.parlement.com/biografie/mr-j-jan-terpstra) | 1947-12-11 | 1947-12-11 | 1 |
| [Jan Verbeek](https://www.parlement.com/biografie/jw-jan-verbeek) | 1984-05-01 | 1984-05-01 | 1 |
| [Jeanet Nijhof-Leeuw](https://www.parlement.com/biografie/jm-jeanet-nijhof-leeuw) | 2024-05-23 | 2024-05-23 | 1 |
| [Jeanine Hennis-Plasschaert](https://www.parlement.com/biografie/ja-jeanine-hennis-plasschaert) | 2014-11-13 | 2017-07-06 | 5 |
| [Jeanne Fortanier-de Wit](https://www.parlement.com/biografie/jeanne-fortanier-de-wit) | 1951-05-10 | 1953-12-15 | 2 |
| [Jeroen Recourt](https://www.parlement.com/biografie/mr-j-jeroen-recourt) | 2011-09-13 | 2011-09-13 | 1 |
| [Jesse Klaver](https://www.parlement.com/biografie/jf-jesse-klaver) | 2012-01-19 | 2012-01-19 | 1 |
| [Jet Bussemaker](https://www.parlement.com/biografie/profdr-m-jet-bussemaker) | 2015-06-02 | 2015-09-29 | 2 |
| [Jo Ritzen](https://www.parlement.com/biografie/drir-jmm-jo-ritzen) | 1993-10-06 | 1997-11-13 | 2 |
| [Joeri Pool](https://www.parlement.com/biografie/j-joeri-pool) | 2024-02-06 | 2024-12-03 | 2 |
| [Johan Scheps](https://www.parlement.com/biografie/jh-johan-scheps) | 1948-12-09 | 1948-12-09 | 1 |
| [Joop den Uyl](https://www.parlement.com/biografie/dr-jm-joop-den-uyl) | 1967-05-22 | 1967-05-22 | 1 |
| [Joop Wolff](https://www.parlement.com/biografie/jf-joop-wolff) | 1977-02-21 | 1977-02-21 | 1 |
| [Joost Eerdmans](https://www.parlement.com/biografie/bj-joost-eerdmans) | 2023-01-25 | 2023-01-25 | 1 |
| [Joost van Iersel](https://www.parlement.com/biografie/mr-jp-joost-van-iersel) | 1985-10-29 | 1985-10-29 | 1 |
| [Joram van Klaveren](https://www.parlement.com/biografie/drs-jj-joram-van-klaveren) | 2015-09-16 | 2015-09-16 | 1 |
| [Jozias van Aartsen](https://www.parlement.com/biografie/jj-jozias-van-aartsen) | 2005-09-21 | 2005-09-21 | 1 |
| [Karien van Gennip](https://www.parlement.com/biografie/ir-ceg-karien-van-gennip) | 2006-10-19 | 2006-10-19 | 1 |
| [Kati Piri](https://www.parlement.com/biografie/kp-kati-piri) | 2023-01-25 | 2023-01-25 | 1 |
| [Kees van der Staaij](https://www.parlement.com/biografie/mr-cg-kees-van-der-staaij) | 1998-11-04 | 2020-02-20 | 8 |
| [Kees van Dijk](https://www.parlement.com/biografie/drs-cp-kees-van-dijk) | 1980-04-22 | 1980-04-22 | 1 |
| [Klaas Dijkhoff](https://www.parlement.com/biografie/dr-khdm-klaas-dijkhoff) | 2019-09-19 | 2019-09-19 | 1 |
| [Ko Suurhoff](https://www.parlement.com/biografie/jg-ko-suurhoff) | 1955-12-09 | 1957-11-28 | 3 |
| [Koos Andriessen](https://www.parlement.com/biografie/dr-je-koos-andriessen) | 1991-05-14 | 1991-05-14 | 1 |
| [Leoni Sipkes](https://www.parlement.com/biografie/drs-l-leoni-sipkes) | 1992-06-17 | 1997-10-01 | 2 |
| [Lodewijk Asscher](https://www.parlement.com/biografie/dr-lf-lodewijk-asscher) | 2018-06-13 | 2018-06-13 | 1 |
| [M.A. Mieras](https://www.parlement.com/biografie/ma-mieras) | 1966-02-15 | 1966-02-15 | 1 |
| [Maarten Engwirda](https://www.parlement.com/biografie/drs-mb-maarten-engwirda) | 1983-02-09 | 1983-02-09 | 1 |
| [Machteld Versnel-Schmitz](https://www.parlement.com/biografie/mm-machteld-versnel-schmitz) | 1995-03-14 | 1995-03-14 | 1 |
| [Marcial Hernandez](https://www.parlement.com/biografie/mm-marcial-hernandez) | 2010-12-07 | 2011-11-29 | 3 |
| [Marcus Bakker](https://www.parlement.com/biografie/m-marcus-bakker) | 1962-03-07 | 1970-09-02 | 2 |
| [Marijn de Koning](https://www.parlement.com/biografie/mr-jm-marijn-de-koning) | 1994-12-06 | 1997-09-25 | 2 |
| [Marinus van der Goes van Naters](https://www.parlement.com/biografie/jhrdr-m-marinus-van-der-goes-van-naters) | 1949-12-06 | 1949-12-06 | 1 |
| [Mariëtte Hamer](https://www.parlement.com/biografie/dr-mi-mariette-hamer) | 2005-04-26 | 2005-04-26 | 1 |
| [Mark Rutte](https://www.parlement.com/biografie/drs-m-mark-rutte) | 2006-09-27 | 2020-09-09 | 7 |
| [Marten Beinema](https://www.parlement.com/biografie/drs-m-marten-beinema) | 1980-04-28 | 1983-04-21 | 2 |
| [Martien van der Weijden](https://www.parlement.com/biografie/mp-martien-van-der-weijden) | 1958-03-12 | 1958-03-12 | 1 |
| [Martijn van Dam](https://www.parlement.com/biografie/ir-mhp-martijn-van-dam) | 2011-06-08 | 2011-06-08 | 1 |
| [Martin Bosma](https://www.parlement.com/biografie/m-martin-bosma) | 2007-04-19 | 2023-02-01 | 16 |
| [Martin Konings](https://www.parlement.com/biografie/mj-martin-konings) | 1983-02-21 | 1983-02-21 | 1 |
| [Mat Herben](https://www.parlement.com/biografie/m-mat-herben) | 2003-12-18 | 2005-11-17 | 2 |
| [Mei Li Vos](https://www.parlement.com/biografie/dr-ml-mei-li-vos) | 2008-11-26 | 2008-11-26 | 1 |
| [Meindert Leerling](https://www.parlement.com/biografie/m-meindert-leerling) | 1982-12-16 | 1987-06-23 | 2 |
| [Michel van Hulten](https://www.parlement.com/biografie/dr-mhm-michel-van-hulten) | 1976-02-23 | 1976-02-23 | 1 |
| [Michel van Winkel o.s.b.](https://www.parlement.com/biografie/mwm-michel-van-winkel-osb) | 1976-06-17 | 1976-06-17 | 1 |
| [Michiel Patijn](https://www.parlement.com/biografie/mr-m-michiel-patijn) | 1995-11-08 | 1995-11-08 | 1 |
| [Michiel van Veen](https://www.parlement.com/biografie/msj-michiel-van-veen) | 2015-06-02 | 2015-06-02 | 3 |
| [Mohamed Rabbae](https://www.parlement.com/biografie/drs-m-mohamed-rabbae) | 1996-03-19 | 1996-03-19 | 1 |
| [Monique de Vries](https://www.parlement.com/biografie/drs-jm-monique-de-vries) | 1997-11-12 | 1997-11-12 | 1 |
| [Nel Mulder-van Dam](https://www.parlement.com/biografie/pal-nel-mulder-van-dam) | 1992-06-22 | 1992-06-22 | 1 |
| [Niels van den Berge](https://www.parlement.com/biografie/cn-niels-van-den-berge) | 2019-11-06 | 2019-11-06 | 1 |
| [Nilüfer Gündoğan](https://www.parlement.com/biografie/n-nilufer-gundogan) | 2022-09-21 | 2022-09-21 | 1 |
| [Nora Salomons](https://www.parlement.com/biografie/ehc-nora-salomons) | 1978-04-10 | 1978-04-10 | 1 |
| [Olaf Ephraim](https://www.parlement.com/biografie/drs-or-olaf-ephraim) | 2023-02-02 | 2023-02-02 | 1 |
| [P.J. Oud](https://www.parlement.com/biografie/mr-pj-oud) | 1955-03-17 | 1955-03-17 | 1 |
| [Paul de Groot](https://www.parlement.com/biografie/s-paul-de-groot) | 1946-05-06 | 1946-05-06 | 1 |
| [Pepijn van Houwelingen](https://www.parlement.com/biografie/p-pepijn-van-houwelingen) | 2024-03-13 | 2024-03-13 | 1 |
| [Peter Lankhorst](https://www.parlement.com/biografie/drs-pa-peter-lankhorst) | 1985-11-04 | 1985-11-04 | 1 |
| [Peter Valstar](https://www.parlement.com/biografie/pj-peter-valstar) | 2021-11-24 | 2021-11-24 | 1 |
| [Peter van Wijmen](https://www.parlement.com/biografie/dr-pce-peter-van-wijmen) | 1998-09-29 | 1998-09-29 | 1 |
| [Pierre Lardinois](https://www.parlement.com/biografie/ir-pj-pierre-lardinois) | 1968-01-31 | 1968-01-31 | 1 |
| [Piet Dankert](https://www.parlement.com/biografie/p-piet-dankert) | 1976-11-02 | 1976-11-02 | 1 |
| [Piet de Jong](https://www.parlement.com/biografie/pjs-piet-de-jong) | 1959-12-10 | 1959-12-10 | 1 |
| [Piet Hein Donner](https://www.parlement.com/biografie/mr-jph-piet-hein-donner) | 2003-04-17 | 2003-04-17 | 1 |
| [Piet Jongeling](https://www.parlement.com/biografie/p-piet-jongeling) | 1963-10-01 | 1971-10-26 | 8 |
| [Piet van der Sanden](https://www.parlement.com/biografie/pja-piet-van-der-sanden) | 1979-12-12 | 1979-12-12 | 1 |
| [Pieter Gerbrandy](https://www.parlement.com/biografie/mr-ps-pieter-gerbrandy) | 1951-01-23 | 1958-02-05 | 4 |
| [Pieter Omtzigt](https://www.parlement.com/biografie/dr-ph-pieter-omtzigt) | 2016-11-15 | 2016-11-15 | 1 |
| [Pieter van Geel](https://www.parlement.com/biografie/drs-plba-pieter-van-geel) | 2007-03-01 | 2007-03-01 | 1 |
| [Pieter Zandt](https://www.parlement.com/biografie/p-pieter-zandt) | 1946-01-09 | 1960-02-03 | 15 |
| [Raymond de Roon](https://www.parlement.com/biografie/mr-r-raymond-de-roon) | 2009-05-19 | 2009-05-19 | 1 |
| [Raymond Knops](https://www.parlement.com/biografie/drs-rw-raymond-knops) | 2011-11-29 | 2011-11-29 | 1 |
| [Reinier Braams](https://www.parlement.com/biografie/dr-r-reinier-braams) | 1980-04-28 | 1980-04-28 | 1 |
| [Remi Poppe](https://www.parlement.com/biografie/rjl-remi-poppe) | 1998-10-08 | 2009-05-13 | 4 |
| [Renske Leijten](https://www.parlement.com/biografie/rm-renske-leijten) | 2023-01-25 | 2023-01-25 | 1 |
| [Ria Beckers-de Bruijn](https://www.parlement.com/biografie/drs-mbc-ria-beckers-de-bruijn) | 1987-09-10 | 1987-09-10 | 1 |
| [Rick van der Ploeg](https://www.parlement.com/biografie/profdr-f-rick-van-der-ploeg) | 1996-10-23 | 1996-10-23 | 1 |
| [Rie de Boois](https://www.parlement.com/biografie/dr-hm-rie-de-boois) | 1976-06-17 | 1976-06-17 | 1 |
| [Rik Grashoff](https://www.parlement.com/biografie/ir-hj-rik-grashoff) | 2010-12-07 | 2010-12-07 | 1 |
| [Rob Jetten](https://www.parlement.com/biografie/raa-rob-jetten) | 2021-09-23 | 2021-09-23 | 1 |
| [Roelof Bisschop](https://www.parlement.com/biografie/dr-r-roelof-bisschop) | 2015-06-02 | 2020-10-07 | 5 |
| [Ronald van Raak](https://www.parlement.com/biografie/profdr-aagm-ronald-van-raak) | 2018-06-20 | 2018-10-10 | 3 |
| [Roy van Aalst](https://www.parlement.com/biografie/rr-roy-van-aalst) | 2020-10-27 | 2020-10-27 | 1 |
| [Rudolf de Korte](https://www.parlement.com/biografie/dr-rw-rudolf-de-korte) | 1992-11-03 | 1992-11-03 | 1 |
| [Ruud Nijhof](https://www.parlement.com/biografie/refm-ruud-nijhof) | 1980-06-19 | 1980-06-19 | 1 |
| [Sake van der Ploeg](https://www.parlement.com/biografie/s-sake-van-der-ploeg) | 1968-01-31 | 1968-01-31 | 1 |
| [Salima Belhaj](https://www.parlement.com/biografie/s-salima-belhaj) | 2021-07-08 | 2021-07-08 | 1 |
| [Sandra Beckerman](https://www.parlement.com/biografie/sm-sandra-beckerman) | 2023-10-18 | 2024-12-03 | 3 |
| [Sari van Heemskerck Pillis-Duvekot](https://www.parlement.com/biografie/s-sari-van-heemskerck-pillis-duvekot) | 1987-09-10 | 1987-09-10 | 1 |
| [Sef Imkamp](https://www.parlement.com/biografie/dr-mjja-sef-imkamp) | 1967-06-20 | 1967-06-20 | 1 |
| [Servaas Huys](https://www.parlement.com/biografie/js-servaas-huys) | 1993-10-05 | 1993-10-05 | 1 |
| [Simone Kerseboom](https://www.parlement.com/biografie/dr-s-simone-kerseboom) | 2021-05-19 | 2021-05-19 | 1 |
| [Stef Blok](https://www.parlement.com/biografie/drs-sa-stef-blok) | 2015-12-10 | 2015-12-10 | 1 |
| [Stephan van Baarle](https://www.parlement.com/biografie/srt-stephan-van-baarle) | 2021-07-08 | 2021-07-08 | 1 |
| [Thierry Baudet](https://www.parlement.com/biografie/dr-thhph-thierry-baudet) | 2022-11-30 | 2022-11-30 | 1 |
| [Thijs van Vlijmen](https://www.parlement.com/biografie/mbmj-thijs-van-vlijmen) | 1989-02-20 | 1989-02-20 | 1 |
| [Tineke Netelenbos](https://www.parlement.com/biografie/t-tineke-netelenbos) | 1999-11-04 | 1999-11-04 | 1 |
| [Tineke Schilthuis](https://www.parlement.com/biografie/mr-ap-tineke-schilthuis) | 1960-02-18 | 1960-02-18 | 1 |
| [Tjebbe Walburg](https://www.parlement.com/biografie/tj-tjebbe-walburg) | 1972-09-27 | 1972-09-27 | 1 |
| [Tjeerd Krol](https://www.parlement.com/biografie/tj-tjeerd-krol) | 1954-10-27 | 1954-10-27 | 1 |
| [Tjerk Westerterp](https://www.parlement.com/biografie/drs-tjerk-westerterp) | 1965-12-02 | 1967-12-20 | 2 |
| [Tunahan Kuzu](https://www.parlement.com/biografie/drs-t-tunahan-kuzu) | 2017-11-07 | 2023-06-14 | 4 |
| [Ulysse Ellian](https://www.parlement.com/biografie/u-ulysse-ellian) | 2021-09-08 | 2021-09-08 | 1 |
| [Victor Marijnen](https://www.parlement.com/biografie/mr-vgm-victor-marijnen) | 1963-03-06 | 1963-03-06 | 1 |
| [Wilbert Willems](https://www.parlement.com/biografie/mr-wj-wilbert-willems) | 1982-12-16 | 1982-12-16 | 1 |
| [Willem Scholten](https://www.parlement.com/biografie/mr-w-willem-scholten) | 1973-01-24 | 1973-01-24 | 1 |
| [Willibrord van Beek](https://www.parlement.com/biografie/wii-willibrord-van-beek) | 2000-10-03 | 2000-10-03 | 1 |
| [Wim Drees Jr.](https://www.parlement.com/biografie/dr-w-wim-drees-jr) | 1973-01-23 | 1976-09-01 | 2 |
| [Wim Kok](https://www.parlement.com/biografie/dr-w-wim-kok) | 1999-09-23 | 1999-09-23 | 1 |
| [Wim Kortenoeven](https://www.parlement.com/biografie/drs-wrf-wim-kortenoeven) | 2011-09-29 | 2011-09-29 | 1 |
| [Wim Schuijt](https://www.parlement.com/biografie/dr-wj-wim-schuijt) | 1957-10-04 | 1957-10-04 | 1 |
| [Wim van Eekelen](https://www.parlement.com/biografie/dr-wf-wim-van-eekelen) | 1985-08-27 | 1985-08-27 | 1 |
| [Wopke Hoekstra](https://www.parlement.com/biografie/mr-wb-wopke-hoekstra) | 2022-11-24 | 2022-11-24 | 1 |
| [Wouter Gortzak](https://www.parlement.com/biografie/drs-w-wouter-gortzak) | 1999-10-14 | 1999-10-14 | 1 |
| [Ynso Scholten](https://www.parlement.com/biografie/mr-y-ynso-scholten) | 1965-02-23 | 1965-02-23 | 1 |
| [Zsolt Szabó](https://www.parlement.com/biografie/drs-fz-zsolt-szabo) | 2005-11-16 | 2006-10-18 | 5 |
