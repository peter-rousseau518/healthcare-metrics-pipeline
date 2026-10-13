-- =============================================================================
-- queries.sql — DuckDB profiling queries
-- Run inside the DuckDB CLI:  duckdb healthcare.duckdb
-- Tip: .pager off   prints long results directly instead of opening a pager
-- Findings are written up in docs/profiling_findings.md
-- =============================================================================

-- 1. Inventory -----------------------------------------------------------------
SHOW TABLES;

SELECT table_name, column_name, data_type
FROM information_schema.columns
ORDER BY table_name, ordinal_position;

-- 2. Join key type check -------------------------------------------------------
-- CCNs are 6-character codes that can start with zero. If any table inferred
-- the CCN as a number, leading zeros are lost and joins silently drop rows.
SELECT table_name, column_name, data_type
FROM information_schema.columns
WHERE column_name ILIKE '%ccn%'
   OR column_name ILIKE '%certification%'
ORDER BY table_name;

-- 3. Column profiling ----------------------------------------------------------
SUMMARIZE nh_providerinfo_oct2024;

-- Wide tables: query SUMMARIZE as a table and filter to columns with nulls
SELECT column_name, column_type, null_percentage, approx_unique
FROM (SUMMARIZE nh_providerinfo_oct2024)
WHERE null_percentage > 0
ORDER BY null_percentage DESC;

-- 4. Grain check ---------------------------------------------------------------
-- Provider info should have exactly one row per facility
SELECT cms_certification_number_ccn, COUNT(*) AS n
FROM nh_providerinfo_oct2024
GROUP BY 1
HAVING COUNT(*) > 1;

-- 5. Referential integrity -----------------------------------------------------
-- CCNs in child tables with no matching facility in provider info
SELECT 'health_citations' AS tbl, COUNT(DISTINCT c.cms_certification_number_ccn) AS orphan_ccns
FROM nh_healthcitations_oct2024 c
LEFT JOIN nh_providerinfo_oct2024 p USING (cms_certification_number_ccn)
WHERE p.cms_certification_number_ccn IS NULL
UNION ALL
SELECT 'penalties', COUNT(DISTINCT c.cms_certification_number_ccn)
FROM nh_penalties_oct2024 c
LEFT JOIN nh_providerinfo_oct2024 p USING (cms_certification_number_ccn)
WHERE p.cms_certification_number_ccn IS NULL
UNION ALL
SELECT 'ownership', COUNT(DISTINCT c.cms_certification_number_ccn)
FROM nh_ownership_oct2024 c
LEFT JOIN nh_providerinfo_oct2024 p USING (cms_certification_number_ccn)
WHERE p.cms_certification_number_ccn IS NULL
UNION ALL
SELECT 'snf_vbp', COUNT(DISTINCT c.cms_certification_number_ccn)
FROM fy_2024_snf_vbp_facility_performance c
LEFT JOIN nh_providerinfo_oct2024 p USING (cms_certification_number_ccn)
WHERE p.cms_certification_number_ccn IS NULL;
