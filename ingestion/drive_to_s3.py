"""
drive_to_s3.py — Copy CMS source files from a Google Drive folder to the S3
landing zone.

Files land at:
    s3://<bucket>/cms_nursing_home/release=<YYYY-MM>/<original file name>

Behavior
- Authenticates to Google Drive as the user (OAuth, read-only scope).
- Authenticates to AWS with the cms-ingest CLI profile (write-only to the
  landing prefix).
- Copies every CSV in the folder. Google Sheets are exported as CSV.
- Skips files already in S3 with the same size, so re-runs are safe.
  Use --force to re-upload everything (bucket versioning keeps prior copies).
- Records lineage on each S3 object as metadata: Drive file ID, MD5,
  and modified time.

Usage
    python3 ingestion/drive_to_s3.py --folder-id <DRIVE_FOLDER_ID> --release 2024-10 --dry-run
    python3 ingestion/drive_to_s3.py --folder-id <DRIVE_FOLDER_ID> --release 2024-10

Credentials are read from ~/.config/cms_pipeline/ (outside the repository):
    credentials.json  OAuth client downloaded from Google Cloud (see docs/setup.md)
    token.json        created on first run after browser sign-in
"""
from __future__ import annotations

import argparse
import logging
import os
import pathlib
import re
import sys
import tempfile

import boto3
from google.auth.transport.requests import Request
from google.oauth2.credentials import Credentials
from google_auth_oauthlib.flow import InstalledAppFlow
from googleapiclient.discovery import build
from googleapiclient.http import MediaIoBaseDownload

SCOPES = ["https://www.googleapis.com/auth/drive.readonly"]
CONFIG_DIR = pathlib.Path(
    os.environ.get("CMS_PIPELINE_CONFIG", pathlib.Path.home() / ".config" / "cms_pipeline")
)
CREDENTIALS_FILE = CONFIG_DIR / "credentials.json"
TOKEN_FILE = CONFIG_DIR / "token.json"

SHEET_MIME = "application/vnd.google-apps.spreadsheet"
CHUNK_SIZE = 32 * 1024 * 1024  # 32 MB download chunks

log = logging.getLogger("drive_to_s3")


# --- Google Drive --------------------------------------------------------------

def drive_service():
    """Return an authorized Drive API client, prompting for sign-in if needed."""
    creds = None
    if TOKEN_FILE.exists():
        creds = Credentials.from_authorized_user_file(str(TOKEN_FILE), SCOPES)

    if creds and creds.valid:
        return build("drive", "v3", credentials=creds, cache_discovery=False)

    if creds and creds.expired and creds.refresh_token:
        try:
            creds.refresh(Request())
        except Exception:
            log.warning("Stored Google token could not be refreshed; signing in again.")
            creds = None

    if not creds or not creds.valid:
        if not CREDENTIALS_FILE.exists():
            sys.exit(f"OAuth client file not found: {CREDENTIALS_FILE} (see docs/setup.md)")
        flow = InstalledAppFlow.from_client_secrets_file(str(CREDENTIALS_FILE), SCOPES)
        creds = flow.run_local_server(port=0)

    CONFIG_DIR.mkdir(parents=True, exist_ok=True)
    TOKEN_FILE.write_text(creds.to_json())
    TOKEN_FILE.chmod(0o600)
    return build("drive", "v3", credentials=creds, cache_discovery=False)


def list_drive_files(service, folder_id: str) -> list[dict]:
    """List all non-trashed files directly inside the folder."""
    files, page_token = [], None
    while True:
        resp = service.files().list(
            q=f"'{folder_id}' in parents and trashed = false",
            fields="nextPageToken, files(id, name, mimeType, size, md5Checksum, modifiedTime)",
            pageSize=100,
            pageToken=page_token,
            supportsAllDrives=True,
            includeItemsFromAllDrives=True,
        ).execute()
        files.extend(resp.get("files", []))
        page_token = resp.get("nextPageToken")
        if not page_token:
            return sorted(files, key=lambda f: f["name"])


def download(service, file: dict, dest: pathlib.Path) -> None:
    """Download a Drive file (or export a Google Sheet as CSV) to dest."""
    if file["mimeType"] == SHEET_MIME:
        request = service.files().export_media(fileId=file["id"], mimeType="text/csv")
    else:
        request = service.files().get_media(fileId=file["id"], supportsAllDrives=True)

    with open(dest, "wb") as fh:
        downloader = MediaIoBaseDownload(fh, request, chunksize=CHUNK_SIZE)
        done = False
        while not done:
            _, done = downloader.next_chunk()


# --- S3 ------------------------------------------------------------------------

def existing_objects(s3, bucket: str, prefix: str) -> dict[str, int]:
    """Map of existing object keys to sizes under prefix.

    Uses ListBucket only, which the write-only ingestion policy allows
    (HeadObject would require read permission).
    """
    objects = {}
    for page in s3.get_paginator("list_objects_v2").paginate(Bucket=bucket, Prefix=prefix):
        for obj in page.get("Contents", []):
            objects[obj["Key"]] = obj["Size"]
    return objects


def ascii_safe(value: str) -> str:
    """S3 user metadata must be ASCII."""
    return value.encode("ascii", "replace").decode("ascii")


# --- Main ----------------------------------------------------------------------

def parse_args() -> argparse.Namespace:
    p = argparse.ArgumentParser(description="Copy CMS CSVs from Google Drive to S3.")
    p.add_argument("--folder-id", default=os.environ.get("DRIVE_FOLDER_ID"),
                   help="Drive folder ID (the part after /folders/ in the URL)")
    p.add_argument("--release", required=True, help="Data release, YYYY-MM (e.g. 2024-10)")
    p.add_argument("--bucket", default=os.environ.get("S3_BUCKET", "peter-cms-nursing-home-2026"))
    p.add_argument("--prefix", default="cms_nursing_home")
    p.add_argument("--profile", default=os.environ.get("AWS_PROFILE", "cms-ingest"))
    p.add_argument("--force", action="store_true", help="Re-upload files that already exist")
    p.add_argument("--dry-run", action="store_true", help="Show what would happen; upload nothing")
    args = p.parse_args()

    if not args.folder_id:
        p.error("--folder-id is required (or set DRIVE_FOLDER_ID)")
    if not re.fullmatch(r"\d{4}-(0[1-9]|1[0-2])", args.release):
        p.error("--release must be YYYY-MM, e.g. 2024-10")
    return args


def main() -> int:
    logging.basicConfig(level=logging.INFO, format="%(asctime)s %(levelname)-7s %(message)s")
    args = parse_args()

    release_prefix = f"{args.prefix}/release={args.release}/"
    s3 = boto3.Session(profile_name=args.profile).client("s3")
    drive = drive_service()

    files = list_drive_files(drive, args.folder_id)
    already = existing_objects(s3, args.bucket, release_prefix)
    log.info("Found %d items in Drive folder; %d objects already in s3://%s/%s",
             len(files), len(already), args.bucket, release_prefix)

    uploaded, skipped, ignored, failed = [], [], [], []

    with tempfile.TemporaryDirectory() as tmp:
        for f in files:
            name = f["name"]
            is_sheet = f["mimeType"] == SHEET_MIME
            if not (name.lower().endswith(".csv") or is_sheet):
                log.info("IGNORE   %s (not a CSV)", name)
                ignored.append(name)
                continue

            object_name = name if name.lower().endswith(".csv") else f"{name}.csv"
            key = release_prefix + object_name
            drive_size = int(f["size"]) if "size" in f else None

            if not args.force and drive_size is not None and already.get(key) == drive_size:
                log.info("SKIP     %s (already in S3, same size)", name)
                skipped.append(name)
                continue

            if args.dry_run:
                log.info("WOULD    %s -> s3://%s/%s", name, args.bucket, key)
                uploaded.append(name)
                continue

            try:
                local = pathlib.Path(tmp) / object_name
                download(drive, f, local)
                s3.upload_file(
                    str(local), args.bucket, key,
                    ExtraArgs={
                        "ContentType": "text/csv",
                        "Metadata": {
                            "source-system": "google-drive",
                            "source-file-name": ascii_safe(name),
                            "drive-file-id": f["id"],
                            "drive-md5": f.get("md5Checksum", ""),
                            "drive-modified-time": f.get("modifiedTime", ""),
                        },
                    },
                )
                size_mb = local.stat().st_size / 1_048_576
                local.unlink()
                log.info("UPLOAD   %s -> s3://%s/%s (%.1f MB)", name, args.bucket, key, size_mb)
                uploaded.append(name)
            except Exception as exc:
                log.error("FAILED   %s: %s", name, exc)
                failed.append(name)

    verb = "would upload" if args.dry_run else "uploaded"
    log.info("Done: %d %s, %d skipped, %d ignored, %d failed",
             len(uploaded), verb, len(skipped), len(ignored), len(failed))
    return 1 if failed else 0


if __name__ == "__main__":
    sys.exit(main())
