-- =============================================================================
-- 01_setup.sql
-- Creates the warehouse, database, layer schemas, CSV file format, and the
-- external stage pointing at the S3 landing zone.
--
-- Run as: SYSADMIN
-- Run after: 00_storage_integration.sql
-- In Snowsight, use Run All (Cmd/Ctrl + Shift + Enter). The Run button only
-- executes the statement under the cursor.
--
-- All statements are idempotent and safe to re-run.
-- =============================================================================

USE ROLE SYSADMIN;

-- Compute: XSMALL, suspends after 60s idle (see ADR-009)
CREATE WAREHOUSE IF NOT EXISTS cms_wh
  WAREHOUSE_SIZE = 'XSMALL'
  AUTO_SUSPEND = 60
  AUTO_RESUME = TRUE
  INITIALLY_SUSPENDED = TRUE;

-- Storage: one schema per layer (see ADR-001)
CREATE DATABASE IF NOT EXISTS healthcare;
CREATE SCHEMA IF NOT EXISTS healthcare.raw;
CREATE SCHEMA IF NOT EXISTS healthcare.staging;
CREATE SCHEMA IF NOT EXISTS healthcare.marts;

USE WAREHOUSE cms_wh;

-- CSV format: header row parsed for column names, quoted fields supported,
-- empty strings loaded as NULL.
-- ERROR_ON_COLUMN_COUNT_MISMATCH = FALSE: raw tables carry two extra
-- load-metadata columns (_SOURCE_FILE, _LOADED_AT) that are not in the files.
-- Columns are matched by name (MATCH_BY_COLUMN_NAME), so the count
-- difference cannot misalign data.
CREATE OR REPLACE FILE FORMAT healthcare.raw.csv_format
  TYPE = CSV
  PARSE_HEADER = TRUE
  FIELD_OPTIONALLY_ENCLOSED_BY = '"'
  EMPTY_FIELD_AS_NULL = TRUE
  NULL_IF = ('')
  ERROR_ON_COLUMN_COUNT_MISMATCH = FALSE;

-- External stage over the landing path, authenticated by the storage
-- integration rather than stored AWS keys (see ADR-006)
CREATE OR REPLACE STAGE healthcare.raw.cms_stage
  STORAGE_INTEGRATION = s3_cms_int
  URL = 's3://peter-cms-nursing-home-2026/cms_nursing_home/'
  FILE_FORMAT = healthcare.raw.csv_format;

-- Verification: succeeds (even if empty) only when the IAM trust is correct.
-- An "Error assuming AWS_ROLE" here means the trust policy does not match
-- the integration's IAM user ARN or external ID.
LIST @healthcare.raw.cms_stage;
