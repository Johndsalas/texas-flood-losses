"""Helper functions to build and load the Texas flood claims data."""

# prep.py: helper for loading the Texas claims data.
from pathlib import Path

PARQUET = Path("data/tx_claims.parquet")
EXTRACT_SQL = Path("sql/00_extract.sql")


def load_claims(con):
    """Build the Texas parquet if it's missing, then create the claims view."""
    if PARQUET.exists():
        print("Parquet found, skipping extract.")
    else:
        print("No parquet yet, running extract (this takes a few minutes)...")
        con.sql(EXTRACT_SQL.read_text())
        print("Done.")

    con.sql(f"CREATE OR REPLACE VIEW claims AS SELECT * FROM '{PARQUET}'")