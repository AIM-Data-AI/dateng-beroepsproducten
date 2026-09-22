"""
Pipeline step 4: Clean raw machine CSV data and produce a single combined file.

Reads all machine CSV files from the raw staging area, applies the following
cleaning steps:
  1. Removes exact duplicate rows.
  2. Replaces out-of-range measurement values with NaN (no imputation).
  3. Strips and normalises the TS (timestamp) column.
  4. Joins with patient_machine_mapping.csv to add PID, MID, BID columns.
  5. Converts PID from text format ('P1234') to integer format (1234) to match
     the EPD patient table.
  6. Excludes rows whose PID does not appear in the EPD staging patient data.

The combined clean output is written to:
    bp1/pipeline/staging/csv_files/clean/machine_data_clean.csv

A cleaning report is written to:
    bp1/pipeline/reports/csv_cleaning_report.txt

NOTE: No imputation is performed. Missing values remain as NaN / empty cells.
"""

import pathlib
import pandas as pd
import numpy as np

# ---------------------------------------------------------------------------
# Configuration
# ---------------------------------------------------------------------------

RAW_STAGING_DIR = pathlib.Path("bp1/pipeline/staging/csv_files/raw")
MAPPING_FILE    = RAW_STAGING_DIR / "patient_machine_mapping.csv"
CLEAN_DIR       = pathlib.Path("bp1/pipeline/staging/csv_files/clean")
CLEAN_OUTPUT    = CLEAN_DIR / "machine_data_clean.csv"
REPORT_PATH     = pathlib.Path("bp1/pipeline/reports/csv_cleaning_report.txt")

# EPD staging patient table — used to filter out rows with unknown PIDs
EPD_PATIENT_STAGING  = pathlib.Path("bp1/pipeline/staging/epd_patient.csv")
EPD_PATIENT_FALLBACK = pathlib.Path("bp1/data/icu_data.csv")

# Plausible value ranges — values outside these are replaced with NaN
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
    """Return a set of valid integer PIDs from the EPD staging patient table."""
    if EPD_PATIENT_STAGING.exists():
        df = pd.read_csv(EPD_PATIENT_STAGING)
        return set(df["pid"].astype(int))
    if EPD_PATIENT_FALLBACK.exists():
        df = pd.read_csv(EPD_PATIENT_FALLBACK)
        pid_col = next(
            (c for c in df.columns if c.lower() in ("pid", "patient_id")), None
        )
        if pid_col:
            return set(
                int(str(v).lstrip("Pp")) for v in df[pid_col].dropna().unique()
            )
    return set()


def pid_str_to_int(pid_str) -> int:
    """Convert 'P1234' → 1234. Returns NaN on failure."""
    try:
        return int(str(pid_str).lstrip("Pp"))
    except (ValueError, TypeError):
        return np.nan


# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------


def main() -> None:
    CLEAN_DIR.mkdir(parents=True, exist_ok=True)
    REPORT_PATH.parent.mkdir(parents=True, exist_ok=True)

    report_lines = [
        "CSV Data Cleaning Report",
        "=" * 50,
        "",
    ]

    valid_pids = load_valid_pids()
    if valid_pids:
        report_lines.append(f"Valid PIDs from EPD staging: {len(valid_pids)} patients")
    else:
        report_lines.append(
            "WARNING: Could not load valid PIDs. Unknown-PID filter disabled."
        )
    report_lines.append("")

    # Load mapping file
    mapping_df = pd.read_csv(MAPPING_FILE)
    mapping_df.columns = [c.strip() for c in mapping_df.columns]
    # Ensure column names are normalised: PID, MID, BID
    mapping_df = mapping_df.rename(
        columns={c: c.upper() for c in mapping_df.columns}
    )
    # Convert PID from 'P1234' to integer
    mapping_df["PID_INT"] = mapping_df["PID"].apply(pid_str_to_int)

    machine_files = sorted(RAW_STAGING_DIR.glob("machine_*.csv"))

    all_frames = []

    total_rows_in         = 0
    total_duplicates_removed = 0
    total_invalid_vals_fixed = 0
    total_invalid_pid_rows   = 0
    total_rows_kept       = 0

    for csv_file in machine_files:
        mid = csv_file.stem.replace("machine_", "")
        report_lines.append(f"--- {csv_file.name} (MID={mid}) ---")

        df = pd.read_csv(csv_file)
        rows_in = len(df)
        total_rows_in += rows_in
        report_lines.append(f"  Rows read          : {rows_in}")

        # 1. Remove exact duplicates
        before = len(df)
        df = df.drop_duplicates()
        dups_removed = before - len(df)
        total_duplicates_removed += dups_removed
        report_lines.append(f"  Duplicates removed : {dups_removed}")

        # 2. Replace out-of-range values with NaN (no imputation)
        vals_fixed_this_file = 0
        for col, (lo, hi) in PLAUSIBLE_RANGES.items():
            if col not in df.columns:
                continue
            numeric = pd.to_numeric(df[col], errors="coerce")
            out_of_range = numeric.notna() & ((numeric < lo) | (numeric > hi))
            cnt = int(out_of_range.sum())
            if cnt > 0:
                df[col] = numeric.where(~out_of_range, other=np.nan)
                report_lines.append(
                    f"  '{col}' out-of-range values set to NaN: {cnt}"
                )
                vals_fixed_this_file += cnt
        if vals_fixed_this_file == 0:
            report_lines.append("  Out-of-range fixes : none")
        total_invalid_vals_fixed += vals_fixed_this_file

        # 3. Normalise TS column
        df["TS"] = pd.to_datetime(df["TS"], errors="coerce")

        # 4. Add MID, BID, PID from mapping
        mapping_row = mapping_df[mapping_df["MID"] == mid]
        if mapping_row.empty:
            report_lines.append(
                f"  WARNING: MID {mid} not found in mapping file. Rows excluded."
            )
            total_invalid_pid_rows += len(df)
            report_lines.append(f"  Rows kept          : 0 (no mapping)")
            report_lines.append("")
            continue

        pid_str = mapping_row.iloc[0]["PID"]
        pid_int = mapping_row.iloc[0]["PID_INT"]
        bid     = mapping_row.iloc[0]["BID"]
        df["MID"] = mid
        df["BID"] = bid
        df["PID"] = pid_str      # original text format retained for reference
        df["pid"] = pid_int      # integer format for EPD join

        # 5. Exclude rows with unknown PIDs
        if valid_pids and (pid_int not in valid_pids):
            report_lines.append(
                f"  WARNING: PID {pid_str} (→ {pid_int}) not in EPD. Rows excluded."
            )
            total_invalid_pid_rows += len(df)
            report_lines.append(f"  Rows kept          : 0 (unknown PID)")
            report_lines.append("")
            continue

        rows_kept = len(df)
        total_rows_kept += rows_kept
        report_lines.append(f"  Rows kept          : {rows_kept}")
        report_lines.append("")
        all_frames.append(df)

    # Combine all clean frames
    if all_frames:
        clean_df = pd.concat(all_frames, ignore_index=True)
        # Reorder columns for clarity
        leading_cols = ["pid", "MID", "BID", "TS"]
        measure_cols = [c for c in clean_df.columns if c not in leading_cols + ["PID"]]
        clean_df = clean_df[leading_cols + measure_cols]
        clean_df.to_csv(CLEAN_OUTPUT, index=False)
        report_lines.append(f"Clean file written to: {CLEAN_OUTPUT}")
        report_lines.append(f"Total rows in clean file: {len(clean_df)}")
    else:
        report_lines.append("WARNING: No data written — all files were excluded.")

    # Summary
    report_lines.append("")
    report_lines.append("=" * 50)
    report_lines.append("SUMMARY")
    report_lines.append(f"  Total rows read                 : {total_rows_in}")
    report_lines.append(f"  Duplicate rows removed          : {total_duplicates_removed}")
    report_lines.append(f"  Out-of-range values set to NaN  : {total_invalid_vals_fixed}")
    report_lines.append(f"  Rows excluded (unknown PID)     : {total_invalid_pid_rows}")
    report_lines.append(f"  Rows kept                       : {total_rows_kept}")
    if all_frames:
        report_lines.append(f"  Rows in machine_data_clean.csv  : {len(clean_df)}")

    report_text = "\n".join(report_lines) + "\n"
    REPORT_PATH.write_text(report_text, encoding="utf-8")
    print(report_text)


if __name__ == "__main__":
    main()
