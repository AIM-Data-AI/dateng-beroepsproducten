-- =============================================================
-- Pipeline step 1: Copy raw EPD data from source to staging
-- =============================================================
-- Source database  : source
-- Staging database : staging
-- Tables           : patient, patient_observation
--
-- Strategy: truncate staging tables and reload from source on
-- each run (full refresh). This matches the pipeline description
-- of a daily full extraction.
--
-- A record count report is written after the copy. Because SQL
-- Server cannot write to the filesystem directly from a plain
-- SQL script, the counts are returned as a result set that the
-- calling process (e.g. the pipeline orchestrator or a Python
-- wrapper) should capture and save as
-- bp1/pipeline/reports/epd_extraction_report.txt
-- =============================================================

-- -------------------------------------------------------
-- 1. Truncate staging tables (respect FK order)
-- -------------------------------------------------------
TRUNCATE TABLE staging.dbo.patient_observation;
TRUNCATE TABLE staging.dbo.patient;

-- -------------------------------------------------------
-- 2. Copy patient
-- -------------------------------------------------------
INSERT INTO staging.dbo.patient (pid, firstname, lastname, dob, treatment)
SELECT pid, firstname, lastname, dob, treatment
FROM source.dbo.patient;

-- -------------------------------------------------------
-- 3. Copy patient_observation
-- -------------------------------------------------------
INSERT INTO staging.dbo.patient_observation (poid, pid, note_ts, note_text, pain_score)
SELECT poid, pid, note_ts, note_text, pain_score
FROM source.dbo.patient_observation;

-- -------------------------------------------------------
-- 4. Record counts (returned as result set for report)
-- -------------------------------------------------------
SELECT 'patient'             AS table_name, COUNT(*) AS record_count FROM staging.dbo.patient
UNION ALL
SELECT 'patient_observation' AS table_name, COUNT(*) AS record_count FROM staging.dbo.patient_observation;
