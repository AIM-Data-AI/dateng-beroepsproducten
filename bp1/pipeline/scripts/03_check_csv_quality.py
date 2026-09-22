"""
Pipeline step 3: Check quality issues in the raw CSV machine data.

Reads all machine CSV files and the patient_machine_mapping.csv from the
staging area (bp1/pipeline/staging/csv_files/raw/) and checks for:
  - Missing values (per column)
  - Duplicate rows
  - Invalid patient IDs (PIDs in CSV not present in EPD staging data)
  - Invalid measurement values (outside of plausible physiological ranges)

EPD staging data is read from a plain CSV export of the staging.patient table
stored at bp1/pipeline/staging/epd_patient.csv, OR directly from the
staging SQLite/SQL Server database. For portability this script reads the
staging area CSV files only (the 01_copy_raw_epd.sql script populates the
staging database; here we derive valid PIDs from the mapping file cross-
checked against the EPD staging patient table dump if available, otherwise
from the raw EPD data at bp1/data/icu_data.csv as a fallback).

Plausible ranges (based on clinical knowledge and requirements):
  SBP        :  40 – 300  mmHg
  DBP        :  20 – 200  mmHg
  HR         :  20 – 250  bpm
  Fluids     :   0 – 50   L  (cumulative per session)
  BloodLost  :   0 – 20   L
  BloodGiven :   0 – 20   L

Report is saved to: bp1/pipeline/reports/csv_quality_report.txt
"""

import pathlib
import pandas as pd

# ---------------------------------------------------------------------------
# Configuration
# ---------------------------------------------------------------------------

RAW_STAGING_DIR = pathlib.Path("bp1/pipeline/staging/csv_files/raw")
MAPPING_FILE    = RAW_STAGING_DIR / "patient_machine_mapping.csv"

# EPD patient staging: prefer a CSV dump next to the staging scripts;
# fall back to the source data file used to generate the EPD.
EPD_PATIENT_STAGING = pathlib.Path("bp1/pipeline/staging/epd_patient.csv")
EPD_PATIENT_FALLBACK = pathlib.Path("bp1/data/icu_data.csv")

REPORT_PATH = pathlib.Path("bp1/pipeline/reports/csv_quality_report.txt")

# Plausible value ranges for measurement columns
PLAUSIBLE_RANGES = {
    "SBP":        (40,  300),
    "DBP":        (20,  200),
    "HR":         (20,  250),
    "Fluids":     (0,   50),
    "BloodLost":  (0,   20),
    "BloodGiven": (0,   20),
}

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------


def load_valid_pids() -> set:
    """
    Return the set of valid patient IDs in integer form from the EPD staging
    patient table. PIDs in the mapping CSV use the format 'P1234'; the EPD
    uses plain integers.
    """
    if EPD_PATIENT_STAGING.exists():
        df = pd.read_csv(EPD_PATIENT_STAGING)
        return set(df["pid"].astype(int))
    if EPD_PATIENT_FALLBACK.exists():
        df = pd.read_csv(EPD_PATIENT_FALLBACK)
        # icu_data.csv may store pid as plain int or prefixed string
        pid_col = next(
            (c for c in df.columns if c.lower() in ("pid", "patient_id")), None
        )
        if pid_col:
            return set(
                int(str(v).lstrip("Pp")) for v in df[pid_col].dropna().unique()
            )
    return set()


def pid_str_to_int(pid_str) -> int:
    """Convert 'P1234' → 1234. Returns -1 on failure."""
    try:
        return int(str(pid_str).lstrip("Pp"))
    except ValueError:
        return -1


# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------


def main() -> None:
    REPORT_PATH.parent.mkdir(parents=True, exist_ok=True)

    report_lines = [
        "CSV Data Quality Report",
        "=" * 50,
        "",
    ]

    valid_pids = load_valid_pids()
    if valid_pids:
        report_lines.append(f"Valid PIDs loaded from EPD staging: {len(valid_pids)} patients")
    else:
        report_lines.append("WARNING: Could not load valid PIDs from EPD staging. PID validation skipped.")
    report_lines.append("")

    # Load mapping to get the MID → PID relationship
    if not MAPPING_FILE.exists():
        report_lines.append(f"ERROR: Mapping file not found: {MAPPING_FILE}")
        REPORT_PATH.write_text("\n".join(report_lines) + "\n", encoding="utf-8")
        print("\n".join(report_lines))
        return

    mapping_df = pd.read_csv(MAPPING_FILE)
    # mapping_df columns: PID, MID, BID
    mid_to_pid = dict(zip(mapping_df["MID"].astype(str), mapping_df["PID"].astype(str)))

    # Find all machine CSV files (exclude the mapping file itself)
    machine_files = sorted(
        f for f in RAW_STAGING_DIR.glob("machine_*.csv")
    )

    if not machine_files:
        report_lines.append(f"WARNING: No machine CSV files found in {RAW_STAGING_DIR}")
        REPORT_PATH.write_text("\n".join(report_lines) + "\n", encoding="utf-8")
        print("\n".join(report_lines))
        return

    total_missing      = 0
    total_duplicates   = 0
    total_invalid_pids = 0
    total_invalid_vals = 0

    for csv_file in machine_files:
        # Derive machine ID from filename, e.g. machine_M01.csv → M01
        mid = csv_file.stem.replace("machine_", "")
        pid_str = mid_to_pid.get(mid, None)

        report_lines.append(f"--- {csv_file.name} (MID={mid}, PID={pid_str}) ---")

        df = pd.read_csv(csv_file)

        # 1. Missing values
        missing = df.isnull().sum()
        missing_total = int(missing.sum())
        total_missing += missing_total
        if missing_total > 0:
            report_lines.append(f"  Missing values ({missing_total} total):")
            for col, cnt in missing[missing > 0].items():
                report_lines.append(f"    {col}: {cnt}")
        else:
            report_lines.append("  Missing values: none")

        # 2. Duplicate rows
        dup_count = int(df.duplicated().sum())
        total_duplicates += dup_count
        report_lines.append(f"  Duplicate rows: {dup_count}")

        # 3. Invalid patient ID (check whether PID from mapping is in EPD)
        if pid_str is None:
            report_lines.append(f"  Invalid patient ID: MID {mid} not found in mapping file")
            total_invalid_pids += len(df)
        elif valid_pids:
            pid_int = pid_str_to_int(pid_str)
            if pid_int not in valid_pids:
                report_lines.append(
                    f"  Invalid patient ID: PID {pid_str} (→ {pid_int}) not in EPD staging"
                )
                total_invalid_pids += len(df)
            else:
                report_lines.append(f"  Patient ID valid: {pid_str}")

        # 4. Out-of-range values
        invalid_vals_this_file = 0
        for col, (lo, hi) in PLAUSIBLE_RANGES.items():
            if col not in df.columns:
                continue
            numeric = pd.to_numeric(df[col], errors="coerce")
            out_of_range = numeric.notna() & ((numeric < lo) | (numeric > hi))
            cnt = int(out_of_range.sum())
            if cnt > 0:
                report_lines.append(
                    f"  Out-of-range '{col}' [{lo}–{hi}]: {cnt} value(s)"
                )
                invalid_vals_this_file += cnt
        if invalid_vals_this_file == 0:
            report_lines.append("  Out-of-range values: none")
        total_invalid_vals += invalid_vals_this_file

        report_lines.append("")

    # Summary
    report_lines.append("=" * 50)
    report_lines.append("SUMMARY")
    report_lines.append(f"  Files checked          : {len(machine_files)}")
    report_lines.append(f"  Total missing values   : {total_missing}")
    report_lines.append(f"  Total duplicate rows   : {total_duplicates}")
    report_lines.append(f"  Total invalid PID rows : {total_invalid_pids}")
    report_lines.append(f"  Total out-of-range vals: {total_invalid_vals}")

    report_text = "\n".join(report_lines) + "\n"
    REPORT_PATH.write_text(report_text, encoding="utf-8")
    print(report_text)


if __name__ == "__main__":
    main()
