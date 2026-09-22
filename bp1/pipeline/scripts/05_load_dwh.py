"""
Pipeline step 5: Load the Data Warehouse (star schema).

Reads:
  - clean machine data (CSV export from step 4)
  - patient-machine mapping (CSV file)
  - EPD staging patient data (CSV export or fallback)
  - EPD staging patient_observation data (CSV export or fallback)

Report saved to: bp1/pipeline/reports/dwh_loading_report.txt
"""

import pathlib
import sqlite3
import pandas as pd
import numpy as np

# ---------------------------------------------------------------------------
# Configuration
# ---------------------------------------------------------------------------

CLEAN_CSV        = pathlib.Path("path/to//machine_data_clean.csv")
MAPPING_FILE     = pathlib.Path("path/to/patient_machine_mapping.csv")
DWH_DB           = pathlib.Path("path/to/dwh.db")
REPORT_PATH      = pathlib.Path("path/to/reports/dwh_loading_report.txt")



# ---------------------------------------------------------------------------
# Your own code goes below
# ---------------------------------------------------------------------------
