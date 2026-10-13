# Setup Runbook

How to rebuild this pipeline's infrastructure from scratch. Steps are listed in the order they must run. The reasoning behind each choice is in `decisions.md`.

## Prerequisites

- An AWS account and an administrator IAM user (not the root account)
- A Snowflake account and access to the `ACCOUNTADMIN` role
- macOS with Homebrew, Python 3, and the AWS CLI (`brew install awscli`)

Find the Snowflake account's region before creating anything in AWS. In a Snowsight worksheet, run `SELECT CURRENT_REGION();`. A result such as `AWS_US_EAST_1` corresponds to AWS region `us-east-1`. The S3 bucket must be in the same region to avoid cross-region transfer charges.

## 1. Create the S3 bucket (AWS console)

1. Create bucket `peter-cms-nursing-home-2026` in the Snowflake account's region.
2. **Permissions** tab: confirm **Block all public access** is on.
3. **Properties** tab: under **Bucket Versioning**, choose **Edit**, then **Enable**.

Files land under the prefix `cms_nursing_home/`, which S3 creates on first upload.

## 2. Create the IAM policies

Go to **IAM → Policies → Create policy**, switch the editor to **JSON**, and create:

| Policy name | File | Grants |
|---|---|---|
| `cms-ingest-writer` | `infrastructure/aws/ingest_writer_policy.json` | Write and list on the landing prefix |
| `snowflake-cms-reader` | `infrastructure/aws/snowflake_reader_policy.json` | Read and list on the landing prefix |

## 3. Create the ingestion user

1. **IAM → Users → Create user**, name `cms-ingest`. Do **not** enable console access.
2. **Attach policies directly**: `cms-ingest-writer`.
3. Open the user, then **Security credentials → Create access key**, with use case **Local code**.
4. Store the keys in a named CLI profile, outside the repository:

```bash
aws configure --profile cms-ingest
```

Enter the region as a code (`us-east-1`), not the console's display name. Then confirm the identity:

```bash
aws sts get-caller-identity --profile cms-ingest
```

The returned ARN should end in `user/cms-ingest`. Delete any downloaded key `.csv` file.

## 4. Create the Snowflake IAM role with a placeholder trust

The role's final trust policy needs two values Snowflake generates in the next step, so the role starts with a placeholder.

1. **IAM → Roles → Create role**. Trusted entity: **AWS account → This account**.
2. Check **Require external ID** and enter `0000` temporarily.
3. Attach `snowflake-cms-reader` and name the role `snowflake-cms-role`.
4. Copy the role ARN from its summary page.

## 5. Create the storage integration (Snowflake)

Run `snowflake/00_storage_integration.sql` as `ACCOUNTADMIN`, with `<ROLE_ARN>` replaced by the ARN from step 4. From the `DESC INTEGRATION` output, copy `STORAGE_AWS_IAM_USER_ARN` and `STORAGE_AWS_EXTERNAL_ID`.

![Storage integration created](images/Create_Integration_with_AWS_IAM_Role.png)

## 6. Apply the final trust policy (AWS console)

Open `snowflake-cms-role`, then **Trust relationships → Edit trust policy**. Paste `infrastructure/aws/trust_policy.json` with the two placeholders replaced by the values from step 5.

![Trust policy](images/trust_policy_json.png)

## 7. Create the warehouse, database, schemas, and stage (Snowflake)

Run `snowflake/01_setup.sql` using **Run All** (Cmd/Ctrl + Shift + Enter).

## 8. Verify access

**Ingestion user can write but not delete:**

```bash
echo "test" > test.txt
aws s3 cp test.txt s3://peter-cms-nursing-home-2026/cms_nursing_home/test.txt --profile cms-ingest
aws s3 rm s3://peter-cms-nursing-home-2026/cms_nursing_home/test.txt --profile cms-ingest
```

Expected: the upload succeeds and the delete fails with `AccessDenied`.

![Write succeeds, delete denied](images/Terminal_Test_for_appropriate_access.png)

**Snowflake can read the bucket:**

```bash
printf "a,b\n1,2\n" > test.csv
aws s3 cp test.csv s3://peter-cms-nursing-home-2026/cms_nursing_home/test/test.csv --profile cms-ingest
```

```sql
LIST @healthcare.raw.cms_stage;
```

Expected: one row for `test/test.csv`. Afterward, delete the test files in the S3 console with **Show versions** turned on, because versioning keeps deleted files as hidden versions otherwise.

## 9. Set up Google Drive API access (Google Cloud console)

1. At console.cloud.google.com, create a project named `cms-pipeline`.
2. **APIs & Services → Library**: search for **Google Drive API** and click **Enable**.
3. **Google Auth Platform** (OAuth consent screen): click **Get started**, enter an app name and your email, choose **External** as the audience, and finish.
4. Under **Audience → Test users**, add your own Google account.
5. Under **Clients → Create client**, choose application type **Desktop app**, create it, and **download the JSON**.
6. Move the downloaded file outside the repository:

```bash
mkdir -p ~/.config/cms_pipeline
mv ~/Downloads/client_secret_*.json ~/.config/cms_pipeline/credentials.json
chmod 600 ~/.config/cms_pipeline/credentials.json
```

## 10. Run the ingestion

Create a virtual environment from the repository root and install dependencies:

```bash
python3 -m venv .venv
source .venv/bin/activate
pip install -r ingestion/requirements.txt
```

The Drive folder ID is the part of the folder's URL after `/folders/`. Run a dry run first, then the real copy:

```bash
python3 ingestion/drive_to_s3.py --folder-id <FOLDER_ID> --release 2024-10 --dry-run
python3 ingestion/drive_to_s3.py --folder-id <FOLDER_ID> --release 2024-10
```

On the first run, a browser window opens for Google sign-in. Google warns that the app isn't verified; that's expected for your own app in testing, so choose **Continue**. The token is saved to `~/.config/cms_pipeline/token.json` and lasts about seven days.

Confirm the files landed:

```sql
LIST @healthcare.raw.cms_stage/release=2024-10/;
```

## Local profiling environment

```bash
pip3 install duckdb
brew install duckdb
python3 profiling/load.py
duckdb ~/Documents/"Healthcare Metrics Project"/healthcare.duckdb
```

Profiling queries are in `profiling/queries.sql`, and results are summarized in `docs/profiling_findings.md`.

## Problems encountered

| Symptom | Cause | Fix |
|---|---|---|
| Terminal prompt changed to `function if function>` after pasting Python | Python was pasted into the zsh shell, which tried to read it as shell commands | Press Ctrl+C. Save code to a `.py` file and run it with `python3` |
| `zsh: command not found` when running SQL | SQL was typed at the shell's `%` prompt instead of DuckDB's `D` prompt | Start DuckDB first. Shell commands go at `%`, SQL at `D` |
| Result view in DuckDB would not exit | Long output opened in a pager | Press `q`. Run `.pager off` to disable |
| `Provided region_name 'US East (N. Virginia) us-east-1' doesn't match a supported format` | The console's display name was entered as the CLI region | `aws configure set region us-east-1 --profile cms-ingest` |
| `File format 'CSV_FORMAT' does not exist or not authorized`, then `Object does not exist` | Snowsight's Run button executes only the statement under the cursor, so earlier setup statements never ran | Use **Run All** and fully qualify object names (`healthcare.raw.csv_format`) |
