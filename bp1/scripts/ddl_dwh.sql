-- =============================================================
-- Data Warehouse (Star Schema) — ICU patient/machine data
-- =============================================================
-- Dimensions : dim_patient, dim_machine, dim_date
-- Facts       : fact_measurement (machine CSV), fact_observation (EPD)
--
-- Sources:
--   dim_patient      : EPD patient table
--   dim_machine      : patient_machine_mapping.csv (mid, bid)
--   dim_date         : derived from machine CSV TS and EPD note_ts
--   fact_measurement : machine_data/*.csv (sbp, dbp, hr, fluids, blood_lost, blood_given)
--   fact_observation : EPD patient_observation (poid, note_text, pain_score)
--
-- Notes:
--   pid is stored as INT: EPD source uses INT; 'P' prefix stripped from CSV format during loading.
--   mid is stored as NVARCHAR(20): CSV uses 'M20' format.
--   bid is stored as NVARCHAR(10): CSV uses 'B01' format.
--   poid is stored as INT: matches EPD patient_observation.poid INT PRIMARY KEY.
--   date_key format: YYYYMMDDHH24MI (e.g. 202605111130)
--   Measurement values are nullable: source files may have empty values.
--   DECIMAL precision:
--     sbp, dbp : DECIMAL(6,2) — mmHg, observed ~60–200
--     hr       : DECIMAL(6,2) — bpm,  observed ~40–200
--     fluids, blood_lost, blood_given : DECIMAL(8,2) — litres
--   pain_score CHECK (0–10) mirrors EPD source validation.
-- =============================================================


-- =============================================================
-- Dimensions
-- =============================================================

CREATE TABLE dim_patient (
    patient_key INT           NOT NULL IDENTITY(1,1),
    pid         INT           NOT NULL,   -- business key; 'P' prefix stripped from CSV format
    firstname   NVARCHAR(512) NOT NULL,
    lastname    NVARCHAR(512) NOT NULL,
    dob         DATE,
    treatment   NVARCHAR(512) NOT NULL,
    CONSTRAINT PK_dim_patient     PRIMARY KEY (patient_key),
    CONSTRAINT UQ_dim_patient_pid UNIQUE (pid)
);

CREATE TABLE dim_machine (
    machine_key INT           NOT NULL IDENTITY(1,1),
    mid         NVARCHAR(20)  NOT NULL,   -- business key; e.g. 'M20'
    bid         NVARCHAR(10)  NOT NULL,   -- batch/session ID; e.g. 'B01'
    CONSTRAINT PK_dim_machine     PRIMARY KEY (machine_key),
    CONSTRAINT UQ_dim_machine_mid UNIQUE (mid)
);

CREATE TABLE dim_date (
    date_key  INT       NOT NULL,   -- surrogate key: YYYYMMDDHH24MI
    timestamp DATETIME2 NOT NULL,
    year      SMALLINT  NOT NULL,
    month     TINYINT   NOT NULL,
    day       TINYINT   NOT NULL,
    hour      TINYINT   NOT NULL,
    minute    TINYINT   NOT NULL,
    CONSTRAINT PK_dim_date PRIMARY KEY (date_key)
);

-- =============================================================
-- Fact tables
-- =============================================================

-- Sensor measurements from machine_data/*.csv
-- All measurement fields are nullable: source files may have empty values.
CREATE TABLE fact_measurement (
    patient_key INT          NOT NULL,
    machine_key INT          NOT NULL,
    date_key    INT          NOT NULL,
    sbp         DECIMAL(6,2),            -- systolic blood pressure (mmHg)
    dbp         DECIMAL(6,2),            -- diastolic blood pressure (mmHg)
    hr          DECIMAL(6,2),            -- heart rate (bpm)
    fluids      DECIMAL(8,2),            -- cumulative fluid intake (L)
    blood_lost  DECIMAL(8,2),            -- cumulative blood lost (L)
    blood_given DECIMAL(8,2),            -- cumulative blood given (L)
    CONSTRAINT PK_fact_measurement         PRIMARY KEY (patient_key, machine_key, date_key),
    CONSTRAINT FK_fact_meas_dim_patient    FOREIGN KEY (patient_key) REFERENCES dim_patient (patient_key),
    CONSTRAINT FK_fact_meas_dim_machine    FOREIGN KEY (machine_key) REFERENCES dim_machine (machine_key),
    CONSTRAINT FK_fact_meas_dim_date       FOREIGN KEY (date_key)    REFERENCES dim_date    (date_key)
);

-- Clinical observations from EPD patient_observation table
CREATE TABLE fact_observation (
    patient_key INT           NOT NULL,
    date_key    INT           NOT NULL,
    poid        INT           NOT NULL,   -- degenerate dimension; business key from EPD
    note_text   NVARCHAR(MAX) NOT NULL,   -- free-form clinical note
    pain_score  INT           NOT NULL,   -- 0–10 scale
    CONSTRAINT PK_fact_observation      PRIMARY KEY (patient_key, date_key, poid),
    CONSTRAINT FK_fact_obs_dim_patient  FOREIGN KEY (patient_key) REFERENCES dim_patient (patient_key),
    CONSTRAINT FK_fact_obs_dim_date     FOREIGN KEY (date_key)    REFERENCES dim_date    (date_key),
    CONSTRAINT CK_fact_obs_pain         CHECK (pain_score >= 0 AND pain_score <= 10)
);
