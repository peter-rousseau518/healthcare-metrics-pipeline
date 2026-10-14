-- =============================================================================
-- 06_dashboard_access.sql
-- Read-only access for the Streamlit dashboard (see ADR-015).
--
--   DASHBOARD_READER  SELECT on the marts schema only
--   STREAMLIT_SVC     service user, key-pair authentication, no password
--
-- FUTURE TABLES grant matters: dbt recreates mart tables on each run, and
-- the future grant applies SELECT to each new table automatically.
--
-- Run as: SECURITYADMIN
-- Before running: replace <PUBLIC_KEY> (setup.md, step 17 does this for you)
-- In Snowsight, use Run All (Cmd/Ctrl + Shift + Enter).
-- =============================================================================

USE ROLE SECURITYADMIN;

CREATE ROLE IF NOT EXISTS dashboard_reader;
GRANT ROLE dashboard_reader TO ROLE SYSADMIN;

GRANT USAGE ON WAREHOUSE cms_wh TO ROLE dashboard_reader;
GRANT USAGE ON DATABASE healthcare TO ROLE dashboard_reader;
GRANT USAGE ON SCHEMA healthcare.marts TO ROLE dashboard_reader;
GRANT SELECT ON ALL TABLES IN SCHEMA healthcare.marts TO ROLE dashboard_reader;
GRANT SELECT ON FUTURE TABLES IN SCHEMA healthcare.marts TO ROLE dashboard_reader;

CREATE USER IF NOT EXISTS streamlit_svc
  TYPE = SERVICE
  DEFAULT_ROLE = dashboard_reader
  DEFAULT_WAREHOUSE = cms_wh
  RSA_PUBLIC_KEY = '<PUBLIC_KEY>'
  COMMENT = 'Streamlit dashboard (read-only, key-pair auth)';
GRANT ROLE dashboard_reader TO USER streamlit_svc;

-- Verify: the reader can see the marts
SHOW GRANTS TO ROLE dashboard_reader;
