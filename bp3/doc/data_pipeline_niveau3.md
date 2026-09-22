# Data pipeline (beroepsproduct 3)

This document describes the data pipeline that is to be created for "beroepsproduct 3".

## The data pipeline

The pipeline reads patient data from the hospital EPD, IC machine monitoring data, questionnaire data,
and NZa wachttijden data into one data vault (see `beroepsproduct 3/doc/dwh.puml`, `beroepsproduct 3/scripts/ddl_dwh.sql`),
which feeds a combined dashboard: IC patient statistics, hip replacement KPI's, and a wachttijden
comparison against regional hospitals.

Every step below lists its own tests, plus a **blocks pipeline** verdict — does a failure here stop the
whole run, or just get logged? See the closing section for how this maps onto the leeruitkomsten in
`lessen/lesplanning.md`.

- **Unit tests** — run at development time, on fixtures (small, hand-built sample inputs), not on real
  data. They prove the step handles
  both good and bad input correctly, including a connection that drops mid-operation (simulated with a
  test double, not just checked once at the start — a connection can fail at any moment).
- **Validation** — runs every actual pipeline run, checking today's real data: row counts, referential
  integrity, a report's own numbers against an independent recount.

Not every step needs both.

### A. EPD

1. **Extraction.** Patient data is read in daily from the hospital EPD, from the tables listed in
   `beroepsproduct 3/scripts/ddl_epd_bp3.sql` (`patient`, `eoc`, `eoc_treatment`, `treatment_type`,
   `eoc_treatment_anesthesia`, `hip_treatment_position`, `patient_statistic`,
   `patient_statistic_type`, `patient_observation`). The extracted data is stored in a staging database mirroring the source
   structure, in the cloud storage area for the pipeline. A report is generated listing the number of
   records extracted per table.
   - **Unit tests:** feed the extraction script a small fixture with known rows for each EPD table, and
     check the resulting staging tables have exactly the columns and types defined in
     `ddl_epd_bp3.sql`. Separately, using a test double, make the EPD connection drop partway through
     extraction, and check the failure is logged clearly rather than left as a half-filled staging table.
   - **Validation:** count today's extracted rows per table and compare against a count on the source;
     check that `pid` has no duplicates in the extracted `patient` table.
   - **Blocks pipeline:** Yes — everything downstream depends on this extraction, including if the EPD or
     storage connection fails or drops partway through.

### B. IC-machinedata

2. **Ingestion.** Time series CSV files are uploaded every 30 minutes per ICU machine to a cloud
   storage bucket, together with the patient–machine mapping file (`patient_machine_mapping.csv`).
   The files are copied to the cloud storage area for the pipeline. A report lists, per machine and
   per 30-minute window, whether a file arrived and how many rows it contained.
   - **Unit tests:** point the step at a test folder that is missing one machine's file and contains one
     truncated CSV, and check the report lists both as gaps while the other files still get processed.
     Separately, simulate the bucket connection dropping mid-listing, and check it's reported as one
     bucket-level failure rather than as many unrelated missing-file gaps.
   - **Validation:** compare the files actually received this run against the full list of active
     machines (`patient_machine_mapping.csv`), so every expected file is accounted for, present or
     missing.
   - **Blocks pipeline:** No — gaps and connection failures alike are logged, not blocking (NFR1).

3. **Quality check.** The IC machine data is checked for missing values, out-of-range values, and
   inconsistencies (e.g. an implausible heart rate). A report lists the quality issues found in the
   raw time series data.
   - **Unit tests:** run the checker on a fixture file with one row of negative fluids and one row with a
     400 bpm heart rate, and check both are flagged in the report.
   - **Validation:** independently count how many rows in today's raw data fall outside the defined
     ranges, and compare that to the quality report's own count.
   - **Blocks pipeline:** No — flagged values are cleaned next.

4. **Cleaning.** Identifiers are standardized to the EPD format, and incorrect values are set to NaN
   (no imputation). A report lists the cleaning actions taken.
   - **Unit tests:** run cleaning on a fixture with one badly formatted identifier and one out-of-range
     value, and check the identifier is reformatted and the value becomes NaN.
   - **Validation:** check every identifier in today's cleaned data matches the EPD format, and that the
     number of values set to NaN here equals the number flagged in step 3's report.
   - **Blocks pipeline:** No.

### C. Vragenlijsten

5. **Ingestion.** `.resp` files are uploaded nightly to a cloud storage bucket and copied to a CSV
   staging area, converted to database rows with `can_be_loaded` defaulting to `False`. A report lists
   the number of files ingested.
   - **Unit tests:** add one deliberately malformed `.resp` file to the input fixture, and check it's
     still ingested as a row, with `can_be_loaded` staying `False`. Separately, simulate the questionnaire
     bucket connection dropping mid-listing, and check it's reported as one outage.
   - **Validation:** compare the number of rows ingested this run to the number of `.resp` files actually
     present in the bucket.
   - **Blocks pipeline:** No — a bad file or a bucket outage is logged, neither blocks.

6. **Patient id validation.** Patient ids from step 5 are checked against the patient ids already in
   the data vault. A report lists rejected rows; accepted rows get `can_be_loaded = True`.
   - **Unit tests:** build a fixture batch with a known mix of valid and invalid patient ids, run it
     against a fixed, known vault snapshot, and check the accepted/rejected split matches exactly.
     Separately, simulate the vault connection dropping mid-batch, and check the failure is logged
     rather than the remaining rows being silently treated as rejected.
   - **Validation:** for every row accepted this run, look up its patient id in `HUB_PATIENT` and check a
     match exists.
   - **Blocks pipeline:** No.

7. **Quality check.** Remaining rows are checked for missing or out-of-range values (e.g. an EQ-5D
   index outside 0–1). A report lists the issues found; failing rows are set back to
   `can_be_loaded = False`.
   - **Unit tests:** feed the checker a fixture row with an EQ-5D index of 1.4 (outside the valid 0–1
     range) and check it's rejected.
   - **Validation:** independently recount how many of today's rows fall outside the valid ranges, and
     compare to the quality report's own rejected-row count.
   - **Blocks pipeline:** No.

### D. NZa Wachttijden

8. **Live snapshot fetch.** Once per day, a script queries the NZa Wachttijden API for every KvK
   number in `kvk_nummers.csv` (own hospital plus the regional comparison group). The API returns only
   the current situation — it has no history — so each call produces one dated snapshot, stored
   unmodified, tagged with its retrieval date, in the cloud storage area for the pipeline. A report
   lists the number of records retrieved per hospital and any failed calls.
   - **Unit tests:** using a test double for the API, make one hospital's call return an error, and check
     the failure is logged for that hospital only while the others still return data. Separately, make the
     API host itself become unreachable partway through the run, and check it's reported as one clear
     outage rather than as every remaining hospital call failing individually.
   - **Validation:** compare today's per-hospital record count to recent days', and flag any hospital
     whose count has unexpectedly dropped to zero.
   - **Blocks pipeline:** No — a full outage or a single failed call must not block the pipeline (NFR4).

9. **Historical bulk import.** Once per day, in step with the live snapshot fetch (step 8), a script
   filters a national NZa bulk export down to the hospitals in `kvk_nummers.csv`, keeping only rows
   where both KvK number and vestigingsnummer match (`wachttijden_history.csv`). This step supplies the
   wachttijden history for the period *before* step 8's snapshot (FR12), so it has to be refreshed on
   the same daily cadence as step 8 rather than run as a one-off backfill — otherwise the historical
   half of the time series would stop growing while the live half keeps growing, leaving a gap that
   only widens each day. A report lists rows kept versus discarded, and hospitals that could not be
   matched due to a missing vestigingsnummer.
   - **Unit tests:** build a small synthetic export containing one row for a hospital not listed in
     `kvk_nummers.csv`, and check it's excluded from the filtered output. Separately, simulate the
     download connection dropping partway through, and check the failure is logged rather than the
     partial file being filtered as if it were complete.
   - **Validation:** check that rows kept plus rows discarded equals the number of rows in today's input
     file.
   - **Blocks pipeline:** No — a download or parsing failure just leaves the historical layer at its last
     successful import.

10. **Staging and treatment mapping.** The live snapshot and the historical import are combined into
    one staging structure, each row tagged with `load_date` and a `record_source` distinguishing live
    from historical (NFR3). Each row is linked to an EPD `treatment_type` via `treatments.csv` — a
    mapping that is intentionally incomplete (not every treatment has a wachttijd). A report lists how
    many EPD treatments could and could not be mapped.
    - **Unit tests:** build a fixture with one live-sourced and one historical-sourced row for the same
      treatment, and check `record_source` tags each one correctly.
    - **Validation:** independently count how many rows in `treatment_type` have no match in
      `treatments.csv`, and compare that to today's reported unmapped-treatment count.
    - **Blocks pipeline:** No.

### E. Data warehouse (data vault — `beroepsproduct 3/doc/dwh.puml`, `beroepsproduct 3/scripts/ddl_dwh.sql`)

11. **Load EPD hubs, links and satellites.** `HUB_PATIENT`, `HUB_EOC`, `HUB_TREATMENT_TYPE`, their
    links and satellites are loaded from the EPD staging data (step 1). `SAT_PATIENT_OBSERVATION` is
    loaded here too, from the same EPD table. A report lists rows inserted/updated per
    hub/link/satellite.
    - **Unit tests:** build one fixture row per constraint to prove, e.g. a foreign key pointing nowhere,
      a duplicate hash key, a `pain_score` of 15, and check the loader rejects each one. Separately, load
      a fixed fixture snapshot twice in a row and check the second load adds zero new rows (NFR2).
      Separately, simulate the vault connection dropping mid-load, and check the failure is logged
      rather than a partially loaded hub/link/satellite being left looking complete.
    - **Validation:** after today's load, check that no row anywhere has a `NULL` `load_date` or
      `record_source` (NFR3).
    - **Blocks pipeline:** Yes — steps 12–14 and the dashboard depend on this structure.

12. **Load IC machine data vault objects.** `HUB_MACHINE`, `SAT_MACHINE`, `LINK_PATIENT_MACHINE` and
    `SAT_MACHINE_MEASUREMENT` are loaded from the cleaned IC data (step 4). These four objects are the
    only ones sourced from the IC machine CSVs. A report lists rows inserted/updated.
    - **Unit tests:** build a fixture row that references a machine id not present in `HUB_MACHINE`, and
      check the loader rejects it as a dangling foreign key.
    - **Validation:** for every `patient_machine_hkey` loaded today, check it resolves to an existing
      patient; compare today's inserted row count to step 4's cleaned row count.
    - **Blocks pipeline:** No — IC part of the vault is independent (NFR1).

13. **Load questionnaire satellite.** `SAT_PATIENT_QUESTIONNAIRE` is loaded from the validated
    questionnaire rows (step 7) where `can_be_loaded = True`. A report lists rows inserted/updated.
    - **Unit tests:** build a fixture row with a `gezondheidsindex_*` value of, say, 1.2, and check the
      pre-insert guard rejects it before it ever reaches the database.
    - **Validation:** before inserting today's rows, look up each row's patient in `HUB_PATIENT` (must
      exist) and check every `gezondheidsindex_*` value is between 0 and 1.
    - **Blocks pipeline:** No.

14. **Load NZa wachttijden vault objects.** `HUB_HOSPITAL`, `HUB_NZA_TREATMENT`,
    `LINK_HOSPITAL_TREATMENT`, `LINK_TREATMENT_NZA_TREATMENT`, `SAT_HOSPITAL`, `SAT_NZA_TREATMENT` and
    `SAT_WAITING_TIME` are loaded from the staged wachttijden data (step 10). A report lists rows
    inserted/updated.
    - **Unit tests:** build one fixture row with `insufficient_observations = 'Ja'` and a non-`NULL`
      waiting time (should be rejected), and one fixture row for a hospital not in `kvk_nummers.csv`
      (should also be rejected).
    - **Validation:** run those same two checks against today's staged rows before loading them.
    - **Blocks pipeline:** No — must not block the EPD-based dashboards (NFR4).

### F. Data marts

15. **IC data mart.** Built from the shared data vault. A report lists the number of records
    aggregated.
    - **Unit tests:** load a known fixture into the mart, and check its schema and row shape match what
      the IC dashboard's FR1–FR3 expect. Separately, simulate the mart store connection dropping
      mid-write, and check the failure is logged rather than a half-written mart being left in place.
    - **Validation:** run that same schema/shape check against today's actually rebuilt mart (NFR1).
    - **Blocks pipeline:** No — previous mart snapshot stays live if the rebuild or its connection fails.

16. **Hip replacement data mart.** Built from the shared data vault. Same testing approach as step 15,
    against the hip replacement dashboard's FR1–FR10.
    - **Blocks pipeline:** No, same reason.

17. **Wachttijden comparison data mart.** Built from the wachttijden vault objects (step 14):
    own-hospital and regional wachttijden per treatment/specialism/care type, plus the count and
    percentage of EPD treatments linked to a wachttijden (KPI10/FR13) and a list of unlinked
    treatments. A report lists the number of records aggregated.
    - **Unit tests:** build a fixture with a known number of linked and unlinked treatments, compute the
      expected percentage by hand, and check the mart produces the same number.
    - **Validation:** independently recompute the linked/unlinked percentage from today's data and
      compare it to the mart's own figure; check that rows with `insufficient_observations = 'Ja'` are
      excluded from the average wait time rather than counted as 0 days (FR11).
    - **Blocks pipeline:** No, same reason as steps 15–16.

### G. Dashboard / BI

18. **BI service query and dashboard render.** A separate BI service queries the data marts once per
    day to fill the combined dashboard: the IC view, the hip replacement view, and the wachttijden
    comparison view for hospital managers and executives (FR11–FR13). A report is generated per query,
    listing the number of records read per mart.
    - **Unit tests:** for each functional requirement (IC FR1–FR3, hip replacement FR1–FR10, wachttijden
      FR11–FR13), build a small fixture and check the matching chart or filter returns correctly-shaped,
      non-empty data. Separately, check that a user with each role only sees the views they're allowed
      to see (NFR5). Also simulate the BI service's connection to the data marts dropping mid-query, and
      check the affected view falls back to its last rendered state rather than showing a broken or
      empty page.
    - **Validation:** re-run the same per-requirement checks against today's actual query results, not
      just the fixtures.
    - **Blocks pipeline:** No — one view's failure doesn't take down others; a full outage falls back to
      the last rendered state.


