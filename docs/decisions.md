# Architecture Decision Log

This log records the significant design decisions in the Healthcare Metrics Pipeline: the context for each choice, what was decided, the alternatives considered, and the consequences. Decisions marked **Planned** are agreed but not yet built.

---

## ADR-001: Layered warehouse architecture (raw → staging → marts)

**Status:** Implemented (schemas created)

**Context:** The source data is 17+ CMS Nursing Home Care Compare CSV files with inconsistent conventions: placeholder values, footnote columns, and mixed-meaning nulls. Analysts need clean, modeled data; engineers need to be able to trace and replay every transformation.

**Decision:** Separate the warehouse into three schemas: `raw` (data exactly as received), `staging` (cleaned, typed, renamed), and `marts` (business-ready star schema).

**Alternatives considered:** Loading directly into cleaned tables; a single schema with naming prefixes.

**Consequences:** Every transformation is reproducible from raw. Permissions can be granted per layer, so the dashboard can read `marts` only. This adds storage and model count, which is negligible at this data volume.

---

## ADR-002: Profile the data locally with DuckDB before designing the warehouse

**Status:** Implemented

**Context:** Staging rules and data tests should be based on evidence from the actual data, not assumptions.

**Decision:** Load all CSVs into a local DuckDB database to profile column types, null rates, key uniqueness, and referential integrity before building warehouse models.

**Alternatives considered:** Profiling directly in Snowflake after loading; skipping profiling.

**Consequences:** Profiling cost no cloud credits and took minutes. Findings (CCN leading-zero risk, placeholder values, 170 VBP facilities absent from the provider table) feed directly into staging logic and dbt tests. See `profiling_findings.md`.

---

## ADR-003: Amazon S3 as the landing zone

**Status:** Implemented

**Context:** The source files live in a Google Drive folder the project has read/download access to but cannot modify. The warehouse should not depend on a source system outside the project's control.

**Decision:** Copy source files into S3 under `s3://peter-cms-nursing-home-2026/cms_nursing_home/`, partitioned by data release.

**Alternatives considered:** Loading from local downloads directly into a Snowflake internal stage; reading from Drive at load time.

**Consequences:** The warehouse is decoupled from the source, so any release can be reloaded even if the Drive files move or disappear. Snowflake reads S3 natively. This adds an AWS account and IAM setup.

---

## ADR-004: Bucket configuration (private, versioned, region-matched)

**Status:** Implemented

**Context:** The landing zone holds the system of record for raw data.

**Decision:** Block all public access, enable versioning, and place the bucket in the same AWS region as the Snowflake account.

**Alternatives considered:** No versioning, which would lower storage cost but make an accidental overwrite unrecoverable.

**Consequences:** Overwritten or deleted files can be recovered. Same-region placement avoids cross-region data transfer charges and latency.

---

## ADR-005: Separate least-privilege identities for writing and reading

**Status:** Implemented

**Context:** Two systems touch the bucket: the ingestion script (writes) and Snowflake (reads).

**Decision:** Create an IAM user `cms-ingest` that can only `PutObject` and list within the landing prefix, and an IAM role `snowflake-cms-role` that can only read within it. The Snowflake role omits the put and delete permissions shown in Snowflake's reference policy, because this pipeline never purges or unloads to S3.

**Alternatives considered:** A single identity with full bucket access.

**Consequences:** A leaked ingestion key cannot read or delete data, and Snowflake cannot alter raw files. This was verified by a test in which `cms-ingest` uploaded successfully and was denied `DeleteObject`.

---

## ADR-006: Snowflake storage integration with an IAM role and external ID

**Status:** Implemented

**Context:** Snowflake needs credentials to read S3.

**Decision:** Use a storage integration that assumes `snowflake-cms-role`, with a trust policy restricted to Snowflake's IAM user and an external ID.

**Alternatives considered:** Embedding AWS access keys in the stage definition.

**Consequences:** No long-lived AWS secrets are stored in Snowflake. The external ID prevents other Snowflake customers from assuming the role. Allowed locations are restricted to the landing prefix.

---

## ADR-007: Snowflake as the data warehouse

**Status:** Implemented

**Context:** The pipeline needs a SQL warehouse that integrates with S3 and dbt and supports role-based access.

**Decision:** Use Snowflake.

**Alternatives considered:** PostgreSQL (lower cost, but requires managing the server); DuckDB in production (excellent for local analysis, but lacks multi-user access control); BigQuery or Redshift (comparable, with less direct S3 integration or more operational overhead).

**Consequences:** Separating storage from compute keeps costs proportional to usage. Native S3 stages, role-based access, and first-class dbt support fit the design.

---

## ADR-008: SYSADMIN owns objects; ACCOUNTADMIN only for account-level grants

**Status:** Implemented

**Context:** Snowflake recommends against routine use of ACCOUNTADMIN.

**Decision:** Create the warehouse, database, schemas, file format, and stage as SYSADMIN. ACCOUNTADMIN is used only to create the storage integration and grant SYSADMIN usage on it.

**Alternatives considered:** Running everything as ACCOUNTADMIN.

**Consequences:** This follows Snowflake's role hierarchy and limits use of the most privileged role.

---

## ADR-009: XSMALL warehouse with 60-second auto-suspend

**Status:** Implemented

**Context:** About 1.3 million rows across all tables, loaded monthly, queried lightly.

**Decision:** A single XSMALL warehouse (`cms_wh`) with auto-suspend after 60 seconds and auto-resume.

**Alternatives considered:** Larger warehouses; separate warehouses for loading, transformation, and dashboards.

**Consequences:** Minimal credit consumption. Separate per-workload warehouses can be added if concurrency grows.

---

## ADR-010: Batch COPY INTO rather than Snowpipe

**Status:** Implemented

**Context:** CMS publishes this dataset on a monthly refresh cycle.

**Decision:** Load with scheduled batch `COPY INTO`.

**Alternatives considered:** Snowpipe auto-ingest via S3 event notifications.

**Consequences:** Simpler setup with no event plumbing. Snowpipe would add continuous-ingest capability that a monthly source doesn't need. COPY INTO's load history also prevents duplicate loads of the same file.

---

## ADR-011: Raw tables store all columns as text, plus load metadata

**Status:** Implemented

**Context:** Profiling showed placeholder values and inconsistent conventions in the source files.

**Decision:** Raw tables keep the source column structure with text types and add `_source_file` and `_loaded_at` columns. Type casting happens in staging.

**Alternatives considered:** Typed raw tables.

**Consequences:** Loads never fail on an unexpected value. Every row is traceable to its source file. Type logic is versioned and tested in dbt rather than hidden in load scripts.

---

## ADR-012: dbt for transformations

**Status:** In progress

**Context:** Transformations need to be version-controlled, tested, and documented.

**Decision:** Build staging and marts models in dbt.

**Alternatives considered:** Snowflake stored procedures; Python transformation scripts.

**Consequences:** SQL models live in Git. Built-in tests (unique, not_null, relationships) encode the profiling findings, such as a relationships test on CCN set to warn for the 170 expected VBP orphans. `dbt docs generate` produces the data dictionary and lineage graph.

---

## ADR-013: Lightweight orchestration

**Status:** Planned

**Context:** The pipeline runs monthly.

**Decision:** Run the pipeline with a single Python runner, optionally scheduled with GitHub Actions.

**Alternatives considered:** Apache Airflow, Dagster.

**Consequences:** No orchestration infrastructure to maintain. Airflow is the documented path to scale up if the pipeline gains more sources or dependencies.

---

## ADR-014: Streamlit on Community Cloud for the dashboard

**Status:** Planned

**Context:** The dashboard must be viewable by reviewers who have no Snowflake account.

**Decision:** Build the dashboard in Streamlit and deploy it on Streamlit Community Cloud from the GitHub repo.

**Alternatives considered:** Power BI (strong self-service, but not code-based and requires licensing to share); Streamlit in Snowflake (no credentials to manage, but every viewer needs a Snowflake login).

**Consequences:** The dashboard is version-controlled Python alongside the rest of the pipeline, viewable from a public or invite-only URL. It provides defined views rather than ad hoc drag-and-drop exploration.

---

## ADR-015: Dashboard connects with a read-only service identity

**Status:** Planned

**Context:** The deployed app needs Snowflake credentials.

**Decision:** A dedicated `TYPE = SERVICE` user with key-pair authentication, and a role with `SELECT` on the `marts` schema only. Credentials are stored in Streamlit secrets, and query results are cached with `st.cache_data`.

**Alternatives considered:** Using a personal login; password authentication.

**Consequences:** Viewers never hold warehouse credentials. A compromised key could only read marts. Caching keeps the warehouse suspended during routine page views.

---

## ADR-016: AWS resources configured in the console; policies saved as code

**Status:** Implemented

**Context:** AWS resources can be created through the console, the CLI, or infrastructure-as-code.

**Decision:** Create the bucket, policies, user, and role in the AWS console, and commit the IAM policy JSON to `infrastructure/aws/` as the record of configuration.

**Alternatives considered:** Terraform or CloudFormation.

**Consequences:** Fast to set up for a single-environment project, with the exact permissions still documented in the repo. Terraform is the next step if the pipeline needs multiple environments or repeatable teardown and rebuild.

---

## ADR-017: Google Drive access through user OAuth with a read-only scope

**Status:** Implemented

**Context:** The source folder belongs to another party. The project can view and download its files but cannot modify them or change their sharing.

**Decision:** The ingestion script authenticates to the Google Drive API as the project owner through OAuth (a desktop-app client) with the `drive.readonly` scope. The OAuth client file and token are stored in `~/.config/cms_pipeline/`, outside the repository.

**Alternatives considered:** A Google service account, which would need the folder shared with the service account's email address, and that sharing change isn't permitted. Manual download followed by upload, which isn't repeatable or auditable.

**Consequences:** The script can read exactly what the owner can read and nothing more, and it can never modify the source. Because the OAuth app runs in Google's "Testing" status, its token expires after about seven days, so a monthly run requires signing in again in the browser. Fully unattended scheduling (ADR-013) would need either a published OAuth app or a source that grants access to a machine identity.

---

## ADR-018: Landing-zone layout and re-run safety

**Status:** Implemented

**Context:** The landing zone must support monthly releases, reloads, and tracing every file back to its source.

**Decision:** Files land at `cms_nursing_home/release=YYYY-MM/<original file name>`. Before uploading, the script lists the release folder and skips files whose size already matches. Each object carries metadata recording its Drive file ID, MD5 checksum, and modified time.

**Alternatives considered:** One folder per table (more structure, but depends on parsing inconsistent CMS file names); partitioning by run date (mixes up when data was published with when it was copied); comparing checksums against S3 (requires read permission the ingestion user deliberately lacks).

**Consequences:** Re-running the script is safe and only fills gaps. Keeping original file names preserves a direct match to the CMS source. The size check works with the write-only policy because listing is permitted. `--force` re-uploads everything, and bucket versioning keeps the previous copies.

---

## ADR-019: Raw tables generated from file headers, with stable names and append-only loads

**Status:** Implemented

**Context:** There are 20 source files with 10 to 100+ columns each, and file names change every release (`NH_ProviderInfo_Oct2024.csv`, then `..._Nov2024.csv`).

**Decision:** Each raw table's columns are generated from its file's header row with `INFER_SCHEMA`, overriding the inferred types to `VARCHAR`, and keep the original CMS column names exactly. Table names drop the release date (`nh_provider_info`). Each `COPY INTO` uses a pattern that matches its file in any release folder, so the same load script handles every release. Tables are append-only, and Snowflake's load history prevents loading the same file twice.

**Alternatives considered:** Hand-written DDL (error-prone across 20 wide tables); `CREATE OR REPLACE` with each load (would discard prior releases); one table per release (multiplies tables and complicates staging).

**Consequences:** The raw layer exactly matches the source, and adding a release needs no code changes. Staging is responsible for renaming columns and selecting the latest release by `_source_file`. Snowflake retains load history for 64 days, so files are expected to be loaded soon after landing.

---

## ADR-020: dbt runs as a dedicated service user with a scoped role

**Status:** Implemented

**Context:** dbt needs Snowflake credentials to build staging and marts. Personal logins require MFA, which interrupts every run, and they carry more privilege than transformations need.

**Decision:** A `TRANSFORMER` role with read-only access to `raw` (including future tables) and create rights in `staging` and `marts`, assigned to a `DBT_SVC` user of `TYPE = SERVICE` that authenticates with an RSA key pair. The private key is stored in `~/.config/cms_pipeline/`, and the connection profile in `~/.dbt/profiles.yml`, both outside the repository. `TRANSFORMER` is granted to `SYSADMIN`, so objects dbt creates stay manageable by the administrator role. Roles and users are created by `SECURITYADMIN`, following Snowflake's separation of administrative duties.

**Alternatives considered:** A personal login with password and MFA; reusing `SYSADMIN`.

**Consequences:** dbt cannot modify raw data. Runs need no interactive sign-in, so they can later be scheduled. A leaked key could only affect staging and marts, and the key can be rotated by updating `RSA_PUBLIC_KEY`. A custom `generate_schema_name` macro makes dbt write to `healthcare.staging` and `healthcare.marts` exactly, rather than dbt's default prefixed schema names.

---

## ADR-021: Model only the tables the dashboard uses

**Status:** Implemented

**Context:** All 20 source files are loaded into raw. Staging and modeling every one would more than double the transformation work, and many tables (survey dates, COVID files, the QRP files, swing-bed data) don't feed the planned analysis.

**Decision:** Build staging and mart models for 8 tables: provider info, penalties, health citations, citation descriptions, ownership, MDS quality measures, claims quality measures, and SNF VBP facility performance. The other 12 remain in raw, documented as sources and available for future work.

**Alternatives considered:** Staging all 20 tables up front.

**Consequences:** Effort goes to the models that produce the deliverables. Because ingestion and raw loading already cover every file, adding any remaining table later only takes a new staging model.

---

## ADR-022: Staging conventions

**Status:** Implemented

**Context:** Raw columns are all text, with CMS's original names, placeholder values, and footnote codes.

**Decision:** Every staging model follows the same rules:
- Columns are renamed to snake_case, with shorter names where the CMS header is long (`hprd` for hours per resident per day).
- Types are cast with Snowflake's `TRY_` functions, so a value that can't be converted becomes NULL instead of failing the build.
- Y/N flags become booleans.
- Placeholder values found in profiling become NULL.
- Footnote columns stay as text codes beside the measures they explain.
- Each row carries `release`, `source_file`, and `loaded_at` for lineage, and only the latest release is kept.
- Staging models are views; marts are tables.

**Alternatives considered:** Strict casts (`TO_NUMBER`), which fail the whole build on one bad value; keeping all releases in staging.

**Consequences:** Builds are resilient to unexpected values. That resilience could hide data loss, so key columns carry dbt tests, and a reconciliation check compares non-null counts between raw and staging after each cast.
