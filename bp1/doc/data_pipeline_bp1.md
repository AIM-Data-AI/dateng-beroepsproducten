# Data pipeline (beroepsproduct 1)

This document describes the data pipeline that is to be created for "beroepsproduct 1".

## The data pipeline

The data pipeline concerns ICU patient data. It reads in patient data from a hospital EPD and time series data from monitoring devices in the ICU. The data is aggregated in a data warehouse. This data warehouse is then used as the basis for a dashboard that provides insights into patient ICU statistics. The data pipeline consists of the following steps:

1. Patient data is read in from the hospital EPD. This happens on a daily basis. The data comes from a relational database and is extracted using SQL queries. Data is extracted from the tables listed in `beroepsproduct 1/scripts/ddl_epd_bp1.sql`. The extracted data is stored in a staging database in the cloud storage area for the data pipeline. This staging database mirrors the table structure of the source database. A report is generated listing the number of records that were extracted for each table, and this report is stored in the cloud storage area for the data pipeline. The data lineage report should refer to this report but should not generate it. AS THIS IS AN EXAMPLE DATA PIPELINE, THERE IS NO NEED TO FILTER THE DATA TO ONLY INCLUDE CURRENT PATIENT DATA. ALL DATA FROM THE EPD TABLES CAN BE EXTRACTED AND INCLUDED IN THE DATA PIPELINE.

2. ICU machine data is read in from CSV files that are uploaded in a cloud storage bucket for the ICU machines. Each ICU machine uploads a CSV file every 30 minutes with measurements taken every 1 minute. Examples of these CSV files can be found in `beroepsproduct 1/data/machine_data/*.csv`. A separate mapping file mapping patients to  machines is stored in the same bucket. For an example of such a mapping file see `beroepsproduct 1/data/patient_machine_mapping.csv`. The CSV files are copied to the cloud storage area for the data pipeline.

3. The ICU machine data is checked for quality issues. This includes checking for missing values, checking for values that are outside of plausible ranges, and checking for inconsistencies in the data (e.g., a heart rate of 200 bpm is not plausible). A report is generated listing quality issues in the raw time series data, and this report is stored in the cloud storage area for the data pipeline. The data lineage report should refer to this report but should not generate it.

4. The ICU machine data is cleaned up. Identifiers are standardized to conform to the format used in the EPD data (if necessary). Incorrect values are set to NaN. No imputation is done as timeseries values for ICU machine data can not be assumed to be linear. The cleaned data is stored in the cloud storage area for the data pipeline. A report is generated listing actions that have been undertaken to clean up the data, and this report is stored in the cloud storage area for the data pipeline. The data lineage report should refer to this report but should not generate it.

5. The patient data from the EPD and the cleaned ICU machine data are aggregated in a data warehouse. The data warehouse is organized as a star schema (see `beroepsproduct 1/doc/dwh.puml`) and consists of the following tables:
   - **dim_patient** — one row per patient, sourced from the EPD `patient` table (`pid`, `firstname`, `lastname`, `dob`, `treatment`).
   - **dim_machine** — one row per ICU machine, sourced from the patient–machine mapping CSV (`mid`, `bid`).
   - **dim_date** — one row per minute-level timestamp, derived from the machine CSV `TS` column and from EPD `patient_observation.note_ts`. The surrogate key is formatted as `YYYYMMDDHH24MI`.
   - **fact_measurement** — one row per (patient, machine, timestamp), sourced from the cleaned ICU machine CSV files. Measures are `sbp`, `dbp`, `hr`, `fluids`, `blood_lost`, and `blood_given`. All measure columns are nullable because machine readings may be absent. Foreign keys link to `dim_patient`, `dim_machine`, and `dim_date`.
   - **fact_observation** — one row per clinical observation, sourced from the EPD `patient_observation` table. Contains `poid` (degenerate dimension), `note_text`, and `pain_score` (0–10). Foreign keys link to `dim_patient` and `dim_date`.

   The data warehouse is stored in the cloud for the data pipeline.

## Not implemented

6. The data from the data warehouse is used to fill a data mart that is to be used as a source for an ICU dashboard that provides insights into patient ICU statistics (see `beroepsproduct 1/doc/requirements.md` for more information). The data mart is a flat table consisting of patient information and ICU machine measurements. The data mart contains the most recent 30 minutes of data, and is updated every 30 minutes as the data warehouse is updated. A report is generated listing the number of records that were aggregated for each patient and this report is stored in the cloud storage area for the data pipeline. The data lineage report should refer to this report but should not generate it. The data mart is stored in the cloud for the data pipeline.

7. An separate BI service queries the data mart every 10 minutes (meaning not every time the data mart is updated but more often) to fill a dashboard that provides insights into the ICU patient data in accordance with the requirements in `beroepsproduct 1/doc/requirements.md`. It contains graphs for each patient. Each graph shows patient measurements, all on the same graph. A report is generated every time this service queries the data mart. This report is stored in the cloud storage area for the data pipeline. The data lineage report should refer to this report but should not generate it.
