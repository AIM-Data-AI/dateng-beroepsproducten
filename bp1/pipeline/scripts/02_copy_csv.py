"""
Pipeline step 2: Copy CSV files from source to staging area.

Copies all machine CSV files from csv_files/ in the source directory
and the patient_machine_mapping.csv file to the staging area:
    bp1/pipeline/staging/csv_files/raw/

Also generates a report listing the number of records per CSV file:
    bp1/pipeline/reports/csv_extraction_report.txt
"""

import os
import shutil
import pathlib
import pandas as pd

# ---------------------------------------------------------------------------
# Configuration
# ---------------------------------------------------------------------------

# Source directory containing machine CSV files and the mapping file.
# In production this would point to the actual cloud storage bucket path.
SOURCE_DIR = pathlib.Path("csv_files")

# Staging destination for raw CSV files
STAGING_DIR = pathlib.Path("bp1/pipeline/staging/csv_files/raw")

# Report output path
REPORT_PATH = pathlib.Path("bp1/pipeline/reports/csv_extraction_report.txt")

# Name of the patient-machine mapping file (must also be copied)
MAPPING_FILE = "patient_machine_mapping.csv"

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------


def ensure_dirs(*paths: pathlib.Path) -> None:
    """Create directories if they do not exist."""
    for path in paths:
        path.mkdir(parents=True, exist_ok=True)


def count_records(csv_path: pathlib.Path) -> int:
    """Return the number of data rows in a CSV file (excluding the header)."""
    df = pd.read_csv(csv_path)
    return len(df)


# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------


def main() -> None:
    ensure_dirs(STAGING_DIR, REPORT_PATH.parent)

    report_lines = [
        "EPD CSV Extraction Report",
        "=" * 40,
    ]

    copied = 0
    errors = 0

    # Collect all CSV files from the source directory
    source_files = sorted(SOURCE_DIR.glob("*.csv"))

    # Ensure the mapping file is included even if it lives in a different path
    mapping_src = SOURCE_DIR / MAPPING_FILE
    all_files = list(source_files)
    if mapping_src not in all_files and mapping_src.exists():
        all_files.append(mapping_src)

    if not all_files:
        report_lines.append(f"WARNING: No CSV files found in {SOURCE_DIR}")
    else:
        for src_file in all_files:
            dest_file = STAGING_DIR / src_file.name
            try:
                shutil.copy2(src_file, dest_file)
                record_count = count_records(dest_file)
                report_lines.append(f"{src_file.name}: {record_count} records")
                copied += 1
            except Exception as exc:
                report_lines.append(f"{src_file.name}: ERROR - {exc}")
                errors += 1

    report_lines.append("")
    report_lines.append(f"Total files copied : {copied}")
    report_lines.append(f"Total errors       : {errors}")

    report_text = "\n".join(report_lines) + "\n"
    REPORT_PATH.write_text(report_text, encoding="utf-8")
    print(report_text)


if __name__ == "__main__":
    main()
