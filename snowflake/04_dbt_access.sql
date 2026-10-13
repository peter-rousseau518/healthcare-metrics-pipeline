-- =============================================================================
-- 04_dbt_access.sql
-- Creates the TRANSFORMER role and DBT_SVC service user that dbt runs as
-- (see ADR-020).
--
--   TRANSFORMER  reads raw; creates and owns objects in staging and marts
--   DBT_SVC      service user, key-pair authentication, no password
--
-- Run as: SECURITYADMIN (creates roles and users, manages grants)
-- Before running: replace <PUBLIC_KEY> with the contents of
--   ~/.config/cms_pipeline/dbt_rsa_key.pub, without the BEGIN/END lines
-- In Snowsight, use Run All (Cmd/Ctrl + Shift + Enter).
-- =============================================================================

USE ROLE SECURITYADMIN;

-- Role: owned objects roll up to SYSADMIN
CREATE ROLE IF NOT EXISTS transformer;
GRANT ROLE transformer TO ROLE SYSADMIN;

GRANT USAGE ON WAREHOUSE cms_wh TO ROLE transformer;
GRANT USAGE ON DATABASE healthcare TO ROLE transformer;

-- Read raw, including tables added in future releases
GRANT USAGE ON SCHEMA healthcare.raw TO ROLE transformer;
GRANT SELECT ON ALL TABLES IN SCHEMA healthcare.raw TO ROLE transformer;
GRANT SELECT ON FUTURE TABLES IN SCHEMA healthcare.raw TO ROLE transformer;

-- Build in staging and marts
GRANT USAGE, CREATE TABLE, CREATE VIEW ON SCHEMA healthcare.staging TO ROLE transformer;
GRANT USAGE, CREATE TABLE, CREATE VIEW ON SCHEMA healthcare.marts TO ROLE transformer;

-- Service user for dbt
CREATE USER IF NOT EXISTS dbt_svc
  TYPE = SERVICE
  DEFAULT_ROLE = transformer
  DEFAULT_WAREHOUSE = cms_wh
  RSA_PUBLIC_KEY = '<PUBLIC_KEY>'
  COMMENT = 'dbt transformations (key-pair auth)';
GRANT ROLE transformer TO USER dbt_svc;

-- Account identifier for ~/.dbt/profiles.yml
SELECT CURRENT_ORGANIZATION_NAME() || '-' || CURRENT_ACCOUNT_NAME() AS dbt_account;
