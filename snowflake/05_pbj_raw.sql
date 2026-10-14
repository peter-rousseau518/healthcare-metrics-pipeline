-- =============================================================================
-- 05_pbj_raw.sql
-- Creates and loads raw.pbj_daily_nurse_staffing from the CMS Payroll-Based
-- Journal daily nurse staffing file(s) (see ADR-023).
--
-- PBJ is published quarterly, so files land under
--   cms_nursing_home/pbj/quarter=YYYYQn/
-- The load pattern matches every quarter; load history skips files already
-- loaded, so this script also loads future quarters.
--
-- PBJ uses its own file format with ISO-8859-1 encoding. CMS PBJ files are
-- commonly Latin-1 encoded; ISO-8859-1 also reads plain ASCII correctly, so
-- it is safe either way.
--
-- Run as: SYSADMIN, after the file is uploaded to S3
-- In Snowsight, use Run All (Cmd/Ctrl + Shift + Enter).
-- =============================================================================

USE ROLE SYSADMIN;
USE WAREHOUSE cms_wh;
USE SCHEMA healthcare.raw;

CREATE OR REPLACE FILE FORMAT healthcare.raw.pbj_csv_format
  TYPE = CSV
  PARSE_HEADER = TRUE
  FIELD_OPTIONALLY_ENCLOSED_BY = '"'
  EMPTY_FIELD_AS_NULL = TRUE
  NULL_IF = ('')
  ERROR_ON_COLUMN_COUNT_MISMATCH = FALSE
  ENCODING = 'ISO-8859-1';

-- pbj_daily_nurse_staffing  <-  PBJ_Daily_Nurse_Staffing_Q2_2024.csv
CREATE TABLE IF NOT EXISTS healthcare.raw.pbj_daily_nurse_staffing
  USING TEMPLATE (
    SELECT ARRAY_AGG(OBJECT_CONSTRUCT('COLUMN_NAME', column_name, 'TYPE', 'VARCHAR', 'NULLABLE', TRUE))
             WITHIN GROUP (ORDER BY order_id)
    FROM TABLE(INFER_SCHEMA(
      LOCATION    => '@healthcare.raw.cms_stage/pbj/quarter=2024Q2/',
      FILES       => 'PBJ_Daily_Nurse_Staffing_Q2_2024.csv',
      FILE_FORMAT => 'healthcare.raw.pbj_csv_format'
    ))
  );
ALTER TABLE healthcare.raw.pbj_daily_nurse_staffing ADD COLUMN IF NOT EXISTS _source_file VARCHAR;
ALTER TABLE healthcare.raw.pbj_daily_nurse_staffing ADD COLUMN IF NOT EXISTS _loaded_at TIMESTAMP_LTZ;

COPY INTO healthcare.raw.pbj_daily_nurse_staffing
  FROM @healthcare.raw.cms_stage
  PATTERN = '.*/PBJ_Daily_Nurse_Staffing_[^/]*[.]csv'
  FILE_FORMAT = (FORMAT_NAME = 'healthcare.raw.pbj_csv_format')
  MATCH_BY_COLUMN_NAME = CASE_SENSITIVE
  INCLUDE_METADATA = (_source_file = METADATA$FILENAME, _loaded_at = METADATA$START_SCAN_TIME)
  ON_ERROR = ABORT_STATEMENT;

-- Verify: expect 1,325,324 rows for Q2 2024 (file has 1,325,325 lines incl. header)
SELECT COUNT(*) AS pbj_rows FROM healthcare.raw.pbj_daily_nurse_staffing;
