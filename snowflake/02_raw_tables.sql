-- =============================================================================
-- 02_raw_tables.sql
-- Creates one raw table per CMS source file (see ADR-011, ADR-019).
--
-- Column names come from each file's header row via INFER_SCHEMA. Every
-- column is forced to VARCHAR so loads never fail on unexpected values;
-- typing happens in dbt staging. Two load-metadata columns are added:
--   _SOURCE_FILE  stage path of the file each row came from
--   _LOADED_AT    when the COPY started
--
-- Run as: SYSADMIN, after the release=2024-10 files are in the stage
-- Safe to re-run: IF NOT EXISTS never drops or alters existing tables.
-- In Snowsight, use Run All (Cmd/Ctrl + Shift + Enter).
--
-- Generated file: one block per table, identical apart from names.
-- =============================================================================

USE ROLE SYSADMIN;
USE WAREHOUSE cms_wh;
USE SCHEMA healthcare.raw;

-- nh_provider_info  <-  NH_ProviderInfo_Oct2024.csv
CREATE TABLE IF NOT EXISTS healthcare.raw.nh_provider_info
  USING TEMPLATE (
    SELECT ARRAY_AGG(OBJECT_CONSTRUCT('COLUMN_NAME', column_name, 'TYPE', 'VARCHAR', 'NULLABLE', TRUE))
             WITHIN GROUP (ORDER BY order_id)
    FROM TABLE(INFER_SCHEMA(
      LOCATION    => '@healthcare.raw.cms_stage/release=2024-10/',
      FILES       => 'NH_ProviderInfo_Oct2024.csv',
      FILE_FORMAT => 'healthcare.raw.csv_format'
    ))
  );
ALTER TABLE healthcare.raw.nh_provider_info ADD COLUMN IF NOT EXISTS _source_file VARCHAR;
ALTER TABLE healthcare.raw.nh_provider_info ADD COLUMN IF NOT EXISTS _loaded_at TIMESTAMP_LTZ;

-- nh_ownership  <-  NH_Ownership_Oct2024.csv
CREATE TABLE IF NOT EXISTS healthcare.raw.nh_ownership
  USING TEMPLATE (
    SELECT ARRAY_AGG(OBJECT_CONSTRUCT('COLUMN_NAME', column_name, 'TYPE', 'VARCHAR', 'NULLABLE', TRUE))
             WITHIN GROUP (ORDER BY order_id)
    FROM TABLE(INFER_SCHEMA(
      LOCATION    => '@healthcare.raw.cms_stage/release=2024-10/',
      FILES       => 'NH_Ownership_Oct2024.csv',
      FILE_FORMAT => 'healthcare.raw.csv_format'
    ))
  );
ALTER TABLE healthcare.raw.nh_ownership ADD COLUMN IF NOT EXISTS _source_file VARCHAR;
ALTER TABLE healthcare.raw.nh_ownership ADD COLUMN IF NOT EXISTS _loaded_at TIMESTAMP_LTZ;

-- nh_penalties  <-  NH_Penalties_Oct2024.csv
CREATE TABLE IF NOT EXISTS healthcare.raw.nh_penalties
  USING TEMPLATE (
    SELECT ARRAY_AGG(OBJECT_CONSTRUCT('COLUMN_NAME', column_name, 'TYPE', 'VARCHAR', 'NULLABLE', TRUE))
             WITHIN GROUP (ORDER BY order_id)
    FROM TABLE(INFER_SCHEMA(
      LOCATION    => '@healthcare.raw.cms_stage/release=2024-10/',
      FILES       => 'NH_Penalties_Oct2024.csv',
      FILE_FORMAT => 'healthcare.raw.csv_format'
    ))
  );
ALTER TABLE healthcare.raw.nh_penalties ADD COLUMN IF NOT EXISTS _source_file VARCHAR;
ALTER TABLE healthcare.raw.nh_penalties ADD COLUMN IF NOT EXISTS _loaded_at TIMESTAMP_LTZ;

-- nh_health_citations  <-  NH_HealthCitations_Oct2024.csv
CREATE TABLE IF NOT EXISTS healthcare.raw.nh_health_citations
  USING TEMPLATE (
    SELECT ARRAY_AGG(OBJECT_CONSTRUCT('COLUMN_NAME', column_name, 'TYPE', 'VARCHAR', 'NULLABLE', TRUE))
             WITHIN GROUP (ORDER BY order_id)
    FROM TABLE(INFER_SCHEMA(
      LOCATION    => '@healthcare.raw.cms_stage/release=2024-10/',
      FILES       => 'NH_HealthCitations_Oct2024.csv',
      FILE_FORMAT => 'healthcare.raw.csv_format'
    ))
  );
ALTER TABLE healthcare.raw.nh_health_citations ADD COLUMN IF NOT EXISTS _source_file VARCHAR;
ALTER TABLE healthcare.raw.nh_health_citations ADD COLUMN IF NOT EXISTS _loaded_at TIMESTAMP_LTZ;

-- nh_fire_safety_citations  <-  NH_FireSafetyCitations_Oct2024.csv
CREATE TABLE IF NOT EXISTS healthcare.raw.nh_fire_safety_citations
  USING TEMPLATE (
    SELECT ARRAY_AGG(OBJECT_CONSTRUCT('COLUMN_NAME', column_name, 'TYPE', 'VARCHAR', 'NULLABLE', TRUE))
             WITHIN GROUP (ORDER BY order_id)
    FROM TABLE(INFER_SCHEMA(
      LOCATION    => '@healthcare.raw.cms_stage/release=2024-10/',
      FILES       => 'NH_FireSafetyCitations_Oct2024.csv',
      FILE_FORMAT => 'healthcare.raw.csv_format'
    ))
  );
ALTER TABLE healthcare.raw.nh_fire_safety_citations ADD COLUMN IF NOT EXISTS _source_file VARCHAR;
ALTER TABLE healthcare.raw.nh_fire_safety_citations ADD COLUMN IF NOT EXISTS _loaded_at TIMESTAMP_LTZ;

-- nh_citation_descriptions  <-  NH_CitationDescriptions_Oct2024.csv
CREATE TABLE IF NOT EXISTS healthcare.raw.nh_citation_descriptions
  USING TEMPLATE (
    SELECT ARRAY_AGG(OBJECT_CONSTRUCT('COLUMN_NAME', column_name, 'TYPE', 'VARCHAR', 'NULLABLE', TRUE))
             WITHIN GROUP (ORDER BY order_id)
    FROM TABLE(INFER_SCHEMA(
      LOCATION    => '@healthcare.raw.cms_stage/release=2024-10/',
      FILES       => 'NH_CitationDescriptions_Oct2024.csv',
      FILE_FORMAT => 'healthcare.raw.csv_format'
    ))
  );
ALTER TABLE healthcare.raw.nh_citation_descriptions ADD COLUMN IF NOT EXISTS _source_file VARCHAR;
ALTER TABLE healthcare.raw.nh_citation_descriptions ADD COLUMN IF NOT EXISTS _loaded_at TIMESTAMP_LTZ;

-- nh_survey_dates  <-  NH_SurveyDates_Oct2024.csv
CREATE TABLE IF NOT EXISTS healthcare.raw.nh_survey_dates
  USING TEMPLATE (
    SELECT ARRAY_AGG(OBJECT_CONSTRUCT('COLUMN_NAME', column_name, 'TYPE', 'VARCHAR', 'NULLABLE', TRUE))
             WITHIN GROUP (ORDER BY order_id)
    FROM TABLE(INFER_SCHEMA(
      LOCATION    => '@healthcare.raw.cms_stage/release=2024-10/',
      FILES       => 'NH_SurveyDates_Oct2024.csv',
      FILE_FORMAT => 'healthcare.raw.csv_format'
    ))
  );
ALTER TABLE healthcare.raw.nh_survey_dates ADD COLUMN IF NOT EXISTS _source_file VARCHAR;
ALTER TABLE healthcare.raw.nh_survey_dates ADD COLUMN IF NOT EXISTS _loaded_at TIMESTAMP_LTZ;

-- nh_survey_summary  <-  NH_SurveySummary_Oct2024.csv
CREATE TABLE IF NOT EXISTS healthcare.raw.nh_survey_summary
  USING TEMPLATE (
    SELECT ARRAY_AGG(OBJECT_CONSTRUCT('COLUMN_NAME', column_name, 'TYPE', 'VARCHAR', 'NULLABLE', TRUE))
             WITHIN GROUP (ORDER BY order_id)
    FROM TABLE(INFER_SCHEMA(
      LOCATION    => '@healthcare.raw.cms_stage/release=2024-10/',
      FILES       => 'NH_SurveySummary_Oct2024.csv',
      FILE_FORMAT => 'healthcare.raw.csv_format'
    ))
  );
ALTER TABLE healthcare.raw.nh_survey_summary ADD COLUMN IF NOT EXISTS _source_file VARCHAR;
ALTER TABLE healthcare.raw.nh_survey_summary ADD COLUMN IF NOT EXISTS _loaded_at TIMESTAMP_LTZ;

-- nh_quality_measures_mds  <-  NH_QualityMsr_MDS_Oct2024.csv
CREATE TABLE IF NOT EXISTS healthcare.raw.nh_quality_measures_mds
  USING TEMPLATE (
    SELECT ARRAY_AGG(OBJECT_CONSTRUCT('COLUMN_NAME', column_name, 'TYPE', 'VARCHAR', 'NULLABLE', TRUE))
             WITHIN GROUP (ORDER BY order_id)
    FROM TABLE(INFER_SCHEMA(
      LOCATION    => '@healthcare.raw.cms_stage/release=2024-10/',
      FILES       => 'NH_QualityMsr_MDS_Oct2024.csv',
      FILE_FORMAT => 'healthcare.raw.csv_format'
    ))
  );
ALTER TABLE healthcare.raw.nh_quality_measures_mds ADD COLUMN IF NOT EXISTS _source_file VARCHAR;
ALTER TABLE healthcare.raw.nh_quality_measures_mds ADD COLUMN IF NOT EXISTS _loaded_at TIMESTAMP_LTZ;

-- nh_quality_measures_claims  <-  NH_QualityMsr_Claims_Oct2024.csv
CREATE TABLE IF NOT EXISTS healthcare.raw.nh_quality_measures_claims
  USING TEMPLATE (
    SELECT ARRAY_AGG(OBJECT_CONSTRUCT('COLUMN_NAME', column_name, 'TYPE', 'VARCHAR', 'NULLABLE', TRUE))
             WITHIN GROUP (ORDER BY order_id)
    FROM TABLE(INFER_SCHEMA(
      LOCATION    => '@healthcare.raw.cms_stage/release=2024-10/',
      FILES       => 'NH_QualityMsr_Claims_Oct2024.csv',
      FILE_FORMAT => 'healthcare.raw.csv_format'
    ))
  );
ALTER TABLE healthcare.raw.nh_quality_measures_claims ADD COLUMN IF NOT EXISTS _source_file VARCHAR;
ALTER TABLE healthcare.raw.nh_quality_measures_claims ADD COLUMN IF NOT EXISTS _loaded_at TIMESTAMP_LTZ;

-- nh_state_us_averages  <-  NH_StateUSAverages_Oct2024.csv
CREATE TABLE IF NOT EXISTS healthcare.raw.nh_state_us_averages
  USING TEMPLATE (
    SELECT ARRAY_AGG(OBJECT_CONSTRUCT('COLUMN_NAME', column_name, 'TYPE', 'VARCHAR', 'NULLABLE', TRUE))
             WITHIN GROUP (ORDER BY order_id)
    FROM TABLE(INFER_SCHEMA(
      LOCATION    => '@healthcare.raw.cms_stage/release=2024-10/',
      FILES       => 'NH_StateUSAverages_Oct2024.csv',
      FILE_FORMAT => 'healthcare.raw.csv_format'
    ))
  );
ALTER TABLE healthcare.raw.nh_state_us_averages ADD COLUMN IF NOT EXISTS _source_file VARCHAR;
ALTER TABLE healthcare.raw.nh_state_us_averages ADD COLUMN IF NOT EXISTS _loaded_at TIMESTAMP_LTZ;

-- nh_health_inspection_cutpoints_state  <-  NH_HlthInspecCutpointsState_Oct2024.csv
CREATE TABLE IF NOT EXISTS healthcare.raw.nh_health_inspection_cutpoints_state
  USING TEMPLATE (
    SELECT ARRAY_AGG(OBJECT_CONSTRUCT('COLUMN_NAME', column_name, 'TYPE', 'VARCHAR', 'NULLABLE', TRUE))
             WITHIN GROUP (ORDER BY order_id)
    FROM TABLE(INFER_SCHEMA(
      LOCATION    => '@healthcare.raw.cms_stage/release=2024-10/',
      FILES       => 'NH_HlthInspecCutpointsState_Oct2024.csv',
      FILE_FORMAT => 'healthcare.raw.csv_format'
    ))
  );
ALTER TABLE healthcare.raw.nh_health_inspection_cutpoints_state ADD COLUMN IF NOT EXISTS _source_file VARCHAR;
ALTER TABLE healthcare.raw.nh_health_inspection_cutpoints_state ADD COLUMN IF NOT EXISTS _loaded_at TIMESTAMP_LTZ;

-- nh_data_collection_intervals  <-  NH_DataCollectionIntervals_Oct2024.csv
CREATE TABLE IF NOT EXISTS healthcare.raw.nh_data_collection_intervals
  USING TEMPLATE (
    SELECT ARRAY_AGG(OBJECT_CONSTRUCT('COLUMN_NAME', column_name, 'TYPE', 'VARCHAR', 'NULLABLE', TRUE))
             WITHIN GROUP (ORDER BY order_id)
    FROM TABLE(INFER_SCHEMA(
      LOCATION    => '@healthcare.raw.cms_stage/release=2024-10/',
      FILES       => 'NH_DataCollectionIntervals_Oct2024.csv',
      FILE_FORMAT => 'healthcare.raw.csv_format'
    ))
  );
ALTER TABLE healthcare.raw.nh_data_collection_intervals ADD COLUMN IF NOT EXISTS _source_file VARCHAR;
ALTER TABLE healthcare.raw.nh_data_collection_intervals ADD COLUMN IF NOT EXISTS _loaded_at TIMESTAMP_LTZ;

-- nh_covid_vax_provider  <-  NH_CovidVaxProvider_20241027.csv
CREATE TABLE IF NOT EXISTS healthcare.raw.nh_covid_vax_provider
  USING TEMPLATE (
    SELECT ARRAY_AGG(OBJECT_CONSTRUCT('COLUMN_NAME', column_name, 'TYPE', 'VARCHAR', 'NULLABLE', TRUE))
             WITHIN GROUP (ORDER BY order_id)
    FROM TABLE(INFER_SCHEMA(
      LOCATION    => '@healthcare.raw.cms_stage/release=2024-10/',
      FILES       => 'NH_CovidVaxProvider_20241027.csv',
      FILE_FORMAT => 'healthcare.raw.csv_format'
    ))
  );
ALTER TABLE healthcare.raw.nh_covid_vax_provider ADD COLUMN IF NOT EXISTS _source_file VARCHAR;
ALTER TABLE healthcare.raw.nh_covid_vax_provider ADD COLUMN IF NOT EXISTS _loaded_at TIMESTAMP_LTZ;

-- nh_covid_vax_averages  <-  NH_CovidVaxAverages_20241027.csv
CREATE TABLE IF NOT EXISTS healthcare.raw.nh_covid_vax_averages
  USING TEMPLATE (
    SELECT ARRAY_AGG(OBJECT_CONSTRUCT('COLUMN_NAME', column_name, 'TYPE', 'VARCHAR', 'NULLABLE', TRUE))
             WITHIN GROUP (ORDER BY order_id)
    FROM TABLE(INFER_SCHEMA(
      LOCATION    => '@healthcare.raw.cms_stage/release=2024-10/',
      FILES       => 'NH_CovidVaxAverages_20241027.csv',
      FILE_FORMAT => 'healthcare.raw.csv_format'
    ))
  );
ALTER TABLE healthcare.raw.nh_covid_vax_averages ADD COLUMN IF NOT EXISTS _source_file VARCHAR;
ALTER TABLE healthcare.raw.nh_covid_vax_averages ADD COLUMN IF NOT EXISTS _loaded_at TIMESTAMP_LTZ;

-- snf_vbp_facility_performance  <-  FY_2024_SNF_VBP_Facility_Performance.csv
CREATE TABLE IF NOT EXISTS healthcare.raw.snf_vbp_facility_performance
  USING TEMPLATE (
    SELECT ARRAY_AGG(OBJECT_CONSTRUCT('COLUMN_NAME', column_name, 'TYPE', 'VARCHAR', 'NULLABLE', TRUE))
             WITHIN GROUP (ORDER BY order_id)
    FROM TABLE(INFER_SCHEMA(
      LOCATION    => '@healthcare.raw.cms_stage/release=2024-10/',
      FILES       => 'FY_2024_SNF_VBP_Facility_Performance.csv',
      FILE_FORMAT => 'healthcare.raw.csv_format'
    ))
  );
ALTER TABLE healthcare.raw.snf_vbp_facility_performance ADD COLUMN IF NOT EXISTS _source_file VARCHAR;
ALTER TABLE healthcare.raw.snf_vbp_facility_performance ADD COLUMN IF NOT EXISTS _loaded_at TIMESTAMP_LTZ;

-- snf_vbp_aggregate_performance  <-  FY_2024_SNF_VBP_Aggregate_Performance.csv
CREATE TABLE IF NOT EXISTS healthcare.raw.snf_vbp_aggregate_performance
  USING TEMPLATE (
    SELECT ARRAY_AGG(OBJECT_CONSTRUCT('COLUMN_NAME', column_name, 'TYPE', 'VARCHAR', 'NULLABLE', TRUE))
             WITHIN GROUP (ORDER BY order_id)
    FROM TABLE(INFER_SCHEMA(
      LOCATION    => '@healthcare.raw.cms_stage/release=2024-10/',
      FILES       => 'FY_2024_SNF_VBP_Aggregate_Performance.csv',
      FILE_FORMAT => 'healthcare.raw.csv_format'
    ))
  );
ALTER TABLE healthcare.raw.snf_vbp_aggregate_performance ADD COLUMN IF NOT EXISTS _source_file VARCHAR;
ALTER TABLE healthcare.raw.snf_vbp_aggregate_performance ADD COLUMN IF NOT EXISTS _loaded_at TIMESTAMP_LTZ;

-- snf_qrp_provider  <-  Skilled_Nursing_Facility_Quality_Reporting_Program_Provider_Data_Oct2024.csv
CREATE TABLE IF NOT EXISTS healthcare.raw.snf_qrp_provider
  USING TEMPLATE (
    SELECT ARRAY_AGG(OBJECT_CONSTRUCT('COLUMN_NAME', column_name, 'TYPE', 'VARCHAR', 'NULLABLE', TRUE))
             WITHIN GROUP (ORDER BY order_id)
    FROM TABLE(INFER_SCHEMA(
      LOCATION    => '@healthcare.raw.cms_stage/release=2024-10/',
      FILES       => 'Skilled_Nursing_Facility_Quality_Reporting_Program_Provider_Data_Oct2024.csv',
      FILE_FORMAT => 'healthcare.raw.csv_format'
    ))
  );
ALTER TABLE healthcare.raw.snf_qrp_provider ADD COLUMN IF NOT EXISTS _source_file VARCHAR;
ALTER TABLE healthcare.raw.snf_qrp_provider ADD COLUMN IF NOT EXISTS _loaded_at TIMESTAMP_LTZ;

-- snf_qrp_national  <-  Skilled_Nursing_Facility_Quality_Reporting_Program_National_Data_Oct2024.csv
CREATE TABLE IF NOT EXISTS healthcare.raw.snf_qrp_national
  USING TEMPLATE (
    SELECT ARRAY_AGG(OBJECT_CONSTRUCT('COLUMN_NAME', column_name, 'TYPE', 'VARCHAR', 'NULLABLE', TRUE))
             WITHIN GROUP (ORDER BY order_id)
    FROM TABLE(INFER_SCHEMA(
      LOCATION    => '@healthcare.raw.cms_stage/release=2024-10/',
      FILES       => 'Skilled_Nursing_Facility_Quality_Reporting_Program_National_Data_Oct2024.csv',
      FILE_FORMAT => 'healthcare.raw.csv_format'
    ))
  );
ALTER TABLE healthcare.raw.snf_qrp_national ADD COLUMN IF NOT EXISTS _source_file VARCHAR;
ALTER TABLE healthcare.raw.snf_qrp_national ADD COLUMN IF NOT EXISTS _loaded_at TIMESTAMP_LTZ;

-- swing_bed_snf  <-  Swing_Bed_SNF_data_Oct2024.csv
CREATE TABLE IF NOT EXISTS healthcare.raw.swing_bed_snf
  USING TEMPLATE (
    SELECT ARRAY_AGG(OBJECT_CONSTRUCT('COLUMN_NAME', column_name, 'TYPE', 'VARCHAR', 'NULLABLE', TRUE))
             WITHIN GROUP (ORDER BY order_id)
    FROM TABLE(INFER_SCHEMA(
      LOCATION    => '@healthcare.raw.cms_stage/release=2024-10/',
      FILES       => 'Swing_Bed_SNF_data_Oct2024.csv',
      FILE_FORMAT => 'healthcare.raw.csv_format'
    ))
  );
ALTER TABLE healthcare.raw.swing_bed_snf ADD COLUMN IF NOT EXISTS _source_file VARCHAR;
ALTER TABLE healthcare.raw.swing_bed_snf ADD COLUMN IF NOT EXISTS _loaded_at TIMESTAMP_LTZ;

-- Verify: 20 tables
SHOW TABLES IN SCHEMA healthcare.raw;
