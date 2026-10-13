# Data Profiling Findings

Before designing the warehouse, all source files were loaded into a local DuckDB database and profiled for column types, null rates, key integrity, and value ranges. These findings drive the staging rules and dbt tests (see `decisions.md`, ADR-002). The code is in `profiling/load.py` and `profiling/queries.sql`.

## Dataset

The source is the CMS Nursing Home Care Compare data release for October 2024, along with the FY 2024 Skilled Nursing Facility Value-Based Purchasing (SNF VBP) files and the October 2024 COVID-19 vaccination files. It covers Medicare and Medicaid certified nursing homes in the United States and its territories.

| Source file | Table | Rows | Role |
|---|---|---:|---|
| NH_ProviderInfo_Oct2024.csv | nh_providerinfo_oct2024 | 14,814 | Hub: one row per facility |
| NH_CovidVaxProvider_20241027.csv | nh_covidvaxprovider_20241027 | 14,814 | One row per facility |
| FY_2024_SNF_VBP_Facility_Performance.csv | fy_2024_snf_vbp_facility_performance | 10,858 | One row per scored facility |
| NH_HealthCitations_Oct2024.csv | nh_healthcitations_oct2024 | 402,424 | Many per facility |
| NH_QualityMsr_MDS_Oct2024.csv | nh_qualitymsr_mds_oct2024 | 266,652 | Many per facility (long format) |
| NH_FireSafetyCitations_Oct2024.csv | nh_firesafetycitations_oct2024 | 200,003 | Many per facility |
| NH_SurveyDates_Oct2024.csv | nh_surveydates_oct2024 | 159,723 | Many per facility |
| NH_Ownership_Oct2024.csv | nh_ownership_oct2024 | 145,354 | Many per facility |
| NH_QualityMsr_Claims_Oct2024.csv | nh_qualitymsr_claims_oct2024 | 59,256 | Many per facility (long format) |
| NH_SurveySummary_Oct2024.csv | nh_surveysummary_oct2024 | 44,243 | Many per facility |
| NH_Penalties_Oct2024.csv | nh_penalties_oct2024 | 28,505 | Many per facility |
| NH_CitationDescriptions_Oct2024.csv | nh_citationdescriptions_oct2024 | 641 | Lookup: deficiency tags |
| NH_CovidVaxAverages_20241027.csv | nh_covidvaxaverages_20241027 | 54 | Lookup: state and national |
| NH_StateUSAverages_Oct2024.csv | nh_stateusaverages_oct2024 | 54 | Lookup: state and national |
| NH_HlthInspecCutpointsState_Oct2024.csv | nh_hlthinspeccutpointsstate_oct2024 | 53 | Lookup: state |
| NH_DataCollectionIntervals_Oct2024.csv | nh_datacollectionintervals_oct2024 | 45 | Metadata: reporting periods |
| FY_2024_SNF_VBP_Aggregate_Performance.csv | fy_2024_snf_vbp_aggregate_performance | 1 | National summary |

Two Skilled Nursing Facility Quality Reporting Program files (national and provider data, October 2024) were added after the initial profiling for later analysis. They also contain the CCN and have not yet been profiled in depth.

## Structure

Facility tables join to `nh_providerinfo_oct2024` on the CMS Certification Number (CCN). Citation tables join to the citation descriptions on the deficiency tag. State-level reference tables join on state.

## Findings

### 1. The CCN join key loaded correctly as text

The CCN appears in all 13 facility-level tables and was inferred as `VARCHAR` in every one. Leading zeros are preserved: the minimum value is `015009`.

**Implication:** keep the CCN as text in every layer. A numeric cast would strip leading zeros and silently break joins.

### 2. Source column names are not query-friendly

Original headers contain spaces and punctuation (for example, `CMS Certification Number (CCN)`), which require quoting in SQL. They were normalized to snake_case for profiling.

**Implication:** staging models rename all columns to consistent snake_case.

### 3. Footnote columns are mostly null by design

Several columns hold a CMS footnote code only when a neighboring measure is missing or adjusted. For example, the residents-per-day footnote is 99.68% null and the geocoding footnote is 94.63% null.

**Implication:** these nulls are not data quality defects. Staging keeps footnotes as separate columns, and the data dictionary documents which measure each one explains.

### 4. Placeholder values look like real values

Some fields contain filler instead of nulls, such as a telephone number of `0000001111` and an SSA county code of `000`. Null-rate profiling does not detect these.

**Implication:** staging converts known placeholders to NULL, and dbt tests flag new ones.

### 5. Affiliated entity is missing for about a third of facilities

`Affiliated Entity Name` and `Affiliated Entity ID` are each 33.12% null. This likely indicates facilities with no parent organization.

**Implication:** potentially useful as a chain vs. independent indicator. Validate against the ownership table before relying on it.

### 6. Geography extends beyond the 50 states

ZIP codes starting with `006` and coordinates near latitude 13.5, longitude 144.8 show Puerto Rico and Guam are included. Latitude ranges from 13.49 to 66.90.

**Implication:** state-level comparisons and maps need to account for territories.

### 7. Other partially populated measures

| Column (provider info) | Null % |
|---|---:|
| Number of Citations from Infection Control Inspections | 50.62 |
| Rating Cycle 3 inspection fields | 0.97 |
| Total Weighted Health Survey Score | 0.38 |
| Average Number of Residents per Day | 0.32 |

**Implication:** dashboard metrics built on these columns must state their coverage.

### 8. Referential integrity is clean, with one expected exception

| Child table | CCNs with no matching facility |
|---|---:|
| Health citations | 0 |
| Penalties | 0 |
| Ownership | 0 |
| SNF VBP facility performance | 170 |

The 170 unmatched VBP facilities (about 1.6% of the VBP file) are consistent with VBP scoring an earlier performance period: some of those facilities have since closed or left the program. The VBP file has exactly one row per CCN (10,858 rows, 10,858 distinct CCNs), so 10,688 current facilities have a VBP score and 4,126 have none, since not every nursing home is scored under VBP.

**Implication:** a dbt `relationships` test on CCN for the VBP model is set to `warn` rather than `error`. Analyses joining VBP to facility details must note that they cover only scored, currently listed facilities.

### 9. Value ranges are plausible

Certified beds range from 4 to 843. Total fines per facility range from $0 to $1,133,449.85. All rows carry the same processing date, 2024-10-01, which confirms a single, consistent release.

## Open items

- Profile the remaining facility tables in depth (citations, quality measures, ownership).
- Profile the two SNF Quality Reporting Program files.
