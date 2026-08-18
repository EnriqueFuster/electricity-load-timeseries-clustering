# Data directories

- `demo/`: 24 anonymized residential GoiEner meters covering the complete 2020
  calendar year.
- `raw/`: ignored local source files; never committed.
- `processed/`: ignored intermediate artifacts.

The canonical long schema is `series_id`, `timestamp`, `value`, with optional
`imputed`. The Shiny upload guide and the main repository README document both
supported input layouts and the associated quality checks.

The bundled sample is derived from the **GoiEner smart meters data** published
by Carlos Quesada Granja, Cruz Enrique Borges Hernández, Leire Astigarraga and
Chris Merveille. The source dataset is available from
[Zenodo](https://doi.org/10.5281/zenodo.7362094) under CC BY-SA. Source
identifiers have been replaced by `meter_01` through `meter_24`; no
customer metadata is included. Meters were screened for complete coverage,
activity, weekly repeatability and excessive peak concentration, then selected
near two representative weekly-shape medoids. The sample remains subject to the source
dataset's CC BY-SA terms and is not representative of the full population.
