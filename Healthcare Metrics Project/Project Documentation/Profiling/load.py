"""
load.py — Load all CMS CSV files into a local DuckDB database for profiling.

Each CSV becomes one table named after its file (lowercase, non-alphanumeric
characters replaced with underscores). Column names are normalized the same
way so they can be queried without quoting.

Usage:
    pip3 install duckdb
    python3 profiling/load.py

Set DATA_DIR to the folder holding the CSVs. The source CSVs and the
generated .duckdb file are excluded from the repo via .gitignore.
"""
import os
import pathlib
import re

import duckdb

DATA_DIR = pathlib.Path(
    os.environ.get(
        "DATA_DIR",
        pathlib.Path.home() / "Documents" / "Healthcare Metrics Project",
    )
)
DB_PATH = DATA_DIR / "healthcare.duckdb"


def table_name(path: pathlib.Path) -> str:
    name = re.sub(r"\W+", "_", path.stem).strip("_").lower()
    return f"t_{name}" if name[0].isdigit() else name


def main() -> None:
    con = duckdb.connect(str(DB_PATH))
    files = sorted(DATA_DIR.glob("*.csv"))
    if not files:
        raise SystemExit(f"No CSV files found in {DATA_DIR}")

    for f in files:
        name = table_name(f)
        # sample_size = -1 scans the whole file before inferring types,
        # so a stray value late in the file cannot break type detection
        con.execute(
            f"""
            CREATE OR REPLACE TABLE {name} AS
            SELECT * FROM read_csv_auto(?, sample_size = -1, normalize_names = true)
            """,
            [str(f)],
        )
        rows = con.execute(f"SELECT COUNT(*) FROM {name}").fetchone()[0]
        print(f"{f.name:45} -> {name:40} {rows:>10,} rows")

    con.close()


if __name__ == "__main__":
    main()
