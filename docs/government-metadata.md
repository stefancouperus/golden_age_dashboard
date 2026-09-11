# Government affiliations and positions

The website uses the research repository's dated Parlement.com review for all
70 government contributions by 47 people. The review fills 69 missing party
affiliations and confirms the existing CHU affiliation for Willem Scholten.
It covers 51 ministerial and 19 state-secretary contributions, with 49 distinct
dated primary offices.

The [complete research audit](https://github.com/hjmschoonvelde/gouden_eeuw_project/blob/6bc139b3d9068f3640faa4e05ca8afc0c1f185bf/docs/government_metadata.md)
links every person and office to Parlement.com. Its
[machine-readable ledger](https://github.com/hjmschoonvelde/gouden_eeuw_project/blob/6bc139b3d9068f3640faa4e05ca8afc0c1f185bf/data/metadata/government_metadata.json)
preserves the preceding values, source links, dates and explicit speech assignments.

The dashboard imports the enriched research CSV directly through the versioned
snapshot in `data/research/`. No runtime biography lookup or metadata overlay is
applied. Existing translations remain joined by speech ID only.

`party_ref` describes the verified affiliation at the speech date; `role` remains
`government`. Party-filter counts therefore include government speakers with
that affiliation. Combine party and speaking-role filters to isolate MP or
government contributions. Affiliation does not imply that a minister speaks for
a party's parliamentary group.

The English position (`speaking_capacity`) appears in government speech cards
and in the reader. The reader also carries the Dutch title on the position's
hover text. Both English and Dutch positions are searchable. The website data
retains the Dutch primary portfolio, office dates and source URL. These are not
exhaustive lists of delegated responsibilities or concurrent deputy-premier roles.

Office dates use the source's start date and departure date; matching includes
the start and excludes the departure date. None of the reviewed speeches falls
on a departure date. Eric Wiebes and Jo Ritzen have different positions for
different included speech dates. Historic ministry names are preserved.

The research CSVs and website retain all 447 contributions and all original
speech text, evidence, coding, names and scope notes. All 1,870 evidence fragments
still align with the full speeches. The research party table and figure are
regenerated; other analytical outputs are unchanged. Dataset preservation,
dated office matching, party/role filters and rendered government details are
covered by the research checks and the website's 12 existing tests.
