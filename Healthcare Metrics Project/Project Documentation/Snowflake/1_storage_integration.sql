-- =============================================================================
-- 00_storage_integration.sql
-- Creates the Snowflake storage integration that lets Snowflake read the S3
-- landing zone by assuming the IAM role snowflake-cms-role.
--
-- Run as: ACCOUNTADMIN (required to create integrations)
-- Run before: 01_setup.sql
--
-- Order of operations (see docs/setup.md):
--   1. Create IAM role snowflake-cms-role with a placeholder trust policy
--   2. Run this script, replacing <ROLE_ARN> with the role's ARN
--   3. Copy STORAGE_AWS_IAM_USER_ARN and STORAGE_AWS_EXTERNAL_ID from the
--      DESC output into infrastructure/aws/trust_policy.json and apply it
--      to the role in AWS
-- =============================================================================

USE ROLE ACCOUNTADMIN;

CREATE STORAGE INTEGRATION IF NOT EXISTS s3_cms_int
  TYPE = EXTERNAL_STAGE
  STORAGE_PROVIDER = 'S3'
  ENABLED = TRUE
  STORAGE_AWS_ROLE_ARN = '<ROLE_ARN>'   -- arn:aws:iam::<ACCOUNT_ID>:role/snowflake-cms-role
  STORAGE_ALLOWED_LOCATIONS = ('s3://peter-cms-nursing-home-2026/cms_nursing_home/');

-- Values needed for the IAM role's trust policy
DESC INTEGRATION s3_cms_int;

-- Objects are owned by SYSADMIN (see ADR-008), so SYSADMIN needs usage
GRANT USAGE ON INTEGRATION s3_cms_int TO ROLE SYSADMIN;
