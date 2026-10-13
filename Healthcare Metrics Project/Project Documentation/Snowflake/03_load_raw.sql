-- =============================================================================
-- 03_load_raw.sql
-- Loads every CMS file in the stage into its raw table (see ADR-010, ADR-019).
--
-- Each PATTERN matches that file in ANY release folder, so this same script
-- loads future releases. Snowflake's load history skips files already
-- loaded, so re-running it does not duplicate rows. Raw tables are
-- append-only; staging selects the latest release.
--
-- ON_ERROR = ABORT_STATEMENT: a bad file fails loudly instead of loading
-- partially.
--
-- Run as: SYSADMIN, after 02_raw_tables.sql
-- In Snowsight, use Run All (Cmd/Ctrl + Shift + Enter).
-- =============================================================================

USE ROLE SYSADMIN;
USE WAREHOUSE cms_wh;
USE SCHEMA healthcare.raw;

COPY INTO healthcare.raw.nh_provider_info
  FROM @healthcare.raw.cms_stage
  PATTERN = '.*/NH_ProviderInfo_[^/]*[.]csv'
  FILE_FORMAT = (FORMAT_NAME = 'healthcare.raw.csv_format')
  MATCH_BY_COLUMN_NAME = CASE_SENSITIVE
  INCLUDE_METADATA = (_source_file = METADATA$FILENAME, _loaded_at = METADATA$START_SCAN_TIME)
  ON_ERROR = ABORT_STATEMENT;

COPY INTO healthcare.raw.nh_ownership
  FROM @healthcare.raw.cms_stage
  PATTERN = '.*/NH_Ownership_[^/]*[.]csv'
  FILE_FORMAT = (FORMAT_NAME = 'healthcare.raw.csv_format')
  MATCH_BY_COLUMN_NAME = CASE_SENSITIVE
  INCLUDE_METADATA = (_source_file = METADATA$FILENAME, _loaded_at = METADATA$START_SCAN_TIME)
  ON_ERROR = ABORT_STATEMENT;

COPY INTO healthcare.raw.nh_penalties
  FROM @healthcare.raw.cms_stage
  PATTERN = '.*/NH_Penalties_[^/]*[.]csv'
  FILE_FORMAT = (FORMAT_NAME = 'healthcare.raw.csv_format')
  MATCH_BY_COLUMN_NAME = CASE_SENSITIVE
  INCLUDE_METADATA = (_source_file = METADATA$FILENAME, _loaded_at = METADATA$START_SCAN_TIME)
  ON_ERROR = ABORT_STATEMENT;

COPY INTO healthcare.raw.nh_health_citations
  FROM @healthcare.raw.cms_stage
  PATTERN = '.*/NH_HealthCitations_[^/]*[.]csv'
  FILE_FORMAT = (FORMAT_NAME = 'healthcare.raw.csv_format')
  MATCH_BY_COLUMN_NAME = CASE_SENSITIVE
  INCLUDE_METADATA = (_source_file = METADATA$FILENAME, _loaded_at = METADATA$START_SCAN_TIME)
  ON_ERROR = ABORT_STATEMENT;

COPY INTO healthcare.raw.nh_fire_safety_citations
  FROM @healthcare.raw.cms_stage
  PATTERN = '.*/NH_FireSafetyCitations_[^/]*[.]csv'
  FILE_FORMAT = (FORMAT_NAME = 'healthcare.raw.csv_format')
  MATCH_BY_COLUMN_NAME = CASE_SENSITIVE
  INCLUDE_METADATA = (_source_file = METADATA$FILENAME, _loaded_at = METADATA$START_SCAN_TIME)
  ON_ERROR = ABORT_STATEMENT;

COPY INTO healthcare.raw.nh_citation_descriptions
  FROM @healthcare.raw.cms_stage
  PATTERN = '.*/NH_CitationDescriptions_[^/]*[.]csv'
  FILE_FORMAT = (FORMAT_NAME = 'healthcare.raw.csv_format')
  MATCH_BY_COLUMN_NAME = CASE_SENSITIVE
  INCLUDE_METADATA = (_source_file = METADATA$FILENAME, _loaded_at = METADATA$START_SCAN_TIME)
  ON_ERROR = ABORT_STATEMENT;

COPY INTO healthcare.raw.nh_survey_dates
  FROM @healthcare.raw.cms_stage
  PATTERN = '.*/NH_SurveyDates_[^/]*[.]csv'
  FILE_FORMAT = (FORMAT_NAME = 'healthcare.raw.csv_format')
  MATCH_BY_COLUMN_NAME = CASE_SENSITIVE
  INCLUDE_METADATA = (_source_file = METADATA$FILENAME, _loaded_at = METADATA$START_SCAN_TIME)
  ON_ERROR = ABORT_STATEMENT;

COPY INTO healthcare.raw.nh_survey_summary
  FROM @healthcare.raw.cms_stage
  PATTERN = '.*/NH_SurveySummary_[^/]*[.]csv'
  FILE_FORMAT = (FORMAT_NAME = 'healthcare.raw.csv_format')
  MATCH_BY_COLUMN_NAME = CASE_SENSITIVE
  INCLUDE_METADATA = (_source_file = METADATA$FILENAME, _loaded_at = METADATA$START_SCAN_TIME)
  ON_ERROR = ABORT_STATEMENT;

COPY INTO healthcare.raw.nh_quality_measures_mds
  FROM @healthcare.raw.cms_stage
  PATTERN = '.*/NH_QualityMsr_MDS_[^/]*[.]csv'
  FILE_FORMAT = (FORMAT_NAME = 'healthcare.raw.csv_format')
  MATCH_BY_COLUMN_NAME = CASE_SENSITIVE
  INCLUDE_METADATA = (_source_file = METADATA$FILENAME, _loaded_at = METADATA$START_SCAN_TIME)
  ON_ERROR = ABORT_STATEMENT;

COPY INTO healthcare.raw.nh_quality_measures_claims
  FROM @healthcare.raw.cms_stage
  PATTERN = '.*/NH_QualityMsr_Claims_[^/]*[.]csv'
  FILE_FORMAT = (FORMAT_NAME = 'healthcare.raw.csv_format')
  MATCH_BY_COLUMN_NAME = CASE_SENSITIVE
  INCLUDE_METADATA = (_source_file = METADATA$FILENAME, _loaded_at = METADATA$START_SCAN_TIME)
  ON_ERROR = ABORT_STATEMENT;

COPY INTO healthcare.raw.nh_state_us_averages
  FROM @healthcare.raw.cms_stage
  PATTERN = '.*/NH_StateUSAverages_[^/]*[.]csv'
  FILE_FORMAT = (FORMAT_NAME = 'healthcare.raw.csv_format')
  MATCH_BY_COLUMN_NAME = CASE_SENSITIVE
  INCLUDE_METADATA = (_source_file = METADATA$FILENAME, _loaded_at = METADATA$START_SCAN_TIME)
  ON_ERROR = ABORT_STATEMENT;

COPY INTO healthcare.raw.nh_health_inspection_cutpoints_state
  FROM @healthcare.raw.cms_stage
  PATTERN = '.*/NH_HlthInspecCutpointsState_[^/]*[.]csv'
  FILE_FORMAT = (FORMAT_NAME = 'healthcare.raw.csv_format')
  MATCH_BY_COLUMN_NAME = CASE_SENSITIVE
  INCLUDE_METADATA = (_source_file = METADATA$FILENAME, _loaded_at = METADATA$START_SCAN_TIME)
  ON_ERROR = ABORT_STATEMENT;

COPY INTO healthcare.raw.nh_data_collection_intervals
  FROM @healthcare.raw.cms_stage
  PATTERN = '.*/NH_DataCollectionIntervals_[^/]*[.]csv'
  FILE_FORMAT = (FORMAT_NAME = 'healthcare.raw.csv_format')
  MATCH_BY_COLUMN_NAME = CASE_SENSITIVE
  INCLUDE_METADATA = (_source_file = METADATA$FILENAME, _loaded_at = METADATA$START_SCAN_TIME)
  ON_ERROR = ABORT_STATEMENT;

COPY INTO healthcare.raw.nh_covid_vax_provider
  FROM @healthcare.raw.cms_stage
  PATTERN = '.*/NH_CovidVaxProvider_[^/]*[.]csv'
  FILE_FORMAT = (FORMAT_NAME = 'healthcare.raw.csv_format')
  MATCH_BY_COLUMN_NAME = CASE_SENSITIVE
  INCLUDE_METADATA = (_source_file = METADATA$FILENAME, _loaded_at = METADATA$START_SCAN_TIME)
  ON_ERROR = ABORT_STATEMENT;

COPY INTO healthcare.raw.nh_covid_vax_averages
  FROM @healthcare.raw.cms_stage
  PATTERN = '.*/NH_CovidVaxAverages_[^/]*[.]csv'
  FILE_FORMAT = (FORMAT_NAME = 'healthcare.raw.csv_format')
  MATCH_BY_COLUMN_NAME = CASE_SENSITIVE
  INCLUDE_METADATA = (_source_file = METADATA$FILENAME, _loaded_at = METADATA$START_SCAN_TIME)
  ON_ERROR = ABORT_STATEMENT;

COPY INTO healthcare.raw.snf_vbp_facility_performance
  FROM @healthcare.raw.cms_stage
  PATTERN = '.*/FY_[0-9]{4}_SNF_VBP_Facility_Performance[.]csv'
  FILE_FORMAT = (FORMAT_NAME = 'healthcare.raw.csv_format')
  MATCH_BY_COLUMN_NAME = CASE_SENSITIVE
  INCLUDE_METADATA = (_source_file = METADATA$FILENAME, _loaded_at = METADATA$START_SCAN_TIME)
  ON_ERROR = ABORT_STATEMENT;

COPY INTO healthcare.raw.snf_vbp_aggregate_performance
  FROM @healthcare.raw.cms_stage
  PATTERN = '.*/FY_[0-9]{4}_SNF_VBP_Aggregate_Performance[.]csv'
  FILE_FORMAT = (FORMAT_NAME = 'healthcare.raw.csv_format')
  MATCH_BY_COLUMN_NAME = CASE_SENSITIVE
  INCLUDE_METADATA = (_source_file = METADATA$FILENAME, _loaded_at = METADATA$START_SCAN_TIME)
  ON_ERROR = ABORT_STATEMENT;

COPY INTO healthcare.raw.snf_qrp_provider
  FROM @healthcare.raw.cms_stage
  PATTERN = '.*/Skilled_Nursing_Facility_Quality_Reporting_Program_Provider_Data_[^/]*[.]csv'
  FILE_FORMAT = (FORMAT_NAME = 'healthcare.raw.csv_format')
  MATCH_BY_COLUMN_NAME = CASE_SENSITIVE
  INCLUDE_METADATA = (_source_file = METADATA$FILENAME, _loaded_at = METADATA$START_SCAN_TIME)
  ON_ERROR = ABORT_STATEMENT;

COPY INTO healthcare.raw.snf_qrp_national
  FROM @healthcare.raw.cms_stage
  PATTERN = '.*/Skilled_Nursing_Facility_Quality_Reporting_Program_National_Data_[^/]*[.]csv'
  FILE_FORMAT = (FORMAT_NAME = 'healthcare.raw.csv_format')
  MATCH_BY_COLUMN_NAME = CASE_SENSITIVE
  INCLUDE_METADATA = (_source_file = METADATA$FILENAME, _loaded_at = METADATA$START_SCAN_TIME)
  ON_ERROR = ABORT_STATEMENT;

COPY INTO healthcare.raw.swing_bed_snf
  FROM @healthcare.raw.cms_stage
  PATTERN = '.*/Swing_Bed_SNF_data_[^/]*[.]csv'
  FILE_FORMAT = (FORMAT_NAME = 'healthcare.raw.csv_format')
  MATCH_BY_COLUMN_NAME = CASE_SENSITIVE
  INCLUDE_METADATA = (_source_file = METADATA$FILENAME, _loaded_at = METADATA$START_SCAN_TIME)
  ON_ERROR = ABORT_STATEMENT;

-- Verify: row counts per table (compare with docs/profiling_findings.md)
SELECT table_name, row_count
FROM healthcare.information_schema.tables
WHERE table_schema = 'RAW' AND table_type = 'BASE TABLE'
ORDER BY table_name;
