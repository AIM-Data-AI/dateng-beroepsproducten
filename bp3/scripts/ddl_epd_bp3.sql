-- Patient information
CREATE TABLE patient (
   pid INT PRIMARY KEY NOT NULL,
   firstname NVARCHAR(512) NOT NULL,
   lastname NVARCHAR(512) NOT NULL,
   dob DATE NULL
);

-- Types of statistics about the patient, such as BMI, smoking status, ASA score, etc.
CREATE TABLE patient_statistic_type (
    stid INT PRIMARY KEY NOT NULL,
    stname NVARCHAR(512) NOT NULL,
    sttype ENUM ('int', 'float', 'bool', 'string') NOT NULL
);

-- Patient observations, such as pain score, nausea score, etc.
CREATE TABLE patient_observation (
    poid INT PRIMARY KEY NOT NULL,
    pid INT NOT NULL,
    note_ts DATETIME NOT NULL,
    note_text TEXT NOT NULL,
    pain_score INT NOT NULL CHECK (pain_score >= 0 AND pain_score <= 10),
    FOREIGN KEY (pid) REFERENCES patient(pid)
);

-- Patient statistsics, such as BMI, smoking status, ASA score, etc.
CREATE TABLE patient_statistic (
    pid INT NOT NULL,
    stid INT NOT NULL,
    stvalue_int INTEGER NULL,
    stvalue_float FLOAT NULL,
    stvalue_bool BOOLEAN NULL,
    stvalue_string NVARCHAR(512) NULL,
    stat_ts DATETIME NULL,
    stat_note TEXT NULL,
    PRIMARY KEY (pid, stid, stat_ts),
    FOREIGN KEY (pid) REFERENCES patient(pid),
    FOREIGN KEY (stid) REFERENCES patient_statistic_type(stid),
    CHECK (
        (stvalue_int IS NOT NULL AND stvalue_float IS NULL AND stvalue_bool IS NULL AND stvalue_string IS NULL) OR
        (stvalue_int IS NULL AND stvalue_float IS NOT NULL AND stvalue_bool IS NULL AND stvalue_string IS NULL) OR
        (stvalue_int IS NULL AND stvalue_float IS NULL AND stvalue_bool IS NOT NULL AND stvalue_string IS NULL) OR
        (stvalue_int IS NULL AND stvalue_float IS NULL AND stvalue_bool IS NULL AND stvalue_string IS NOT NULL)
    )
);


-- Treatment types, such as "hip replacement surgery", "arthrotomy", "revision (partial)", "revision (complete)" and "reposition"
CREATE TABLE treatment_type (
    tid INT PRIMARY KEY NOT NULL,
    tname NVARCHAR(512) NOT NULL
);


-- EOC (episode of care)
CREATE TABLE eoc (
    eocid INT PRIMARY KEY NOT NULL,
    pid INT NOT NULL,
    intake_date DATE NOT NULL,
    discharge_date DATE NULL,
    FOREIGN KEY (pid) REFERENCES patient(pid)
);

-- Treatments linked to an episode of care, with the time of the treatment and whether it is a primary treatment or a follow up treatment. Each EOC should have at least one primary treatment, and may have multiple follow up treatments.
CREATE TABLE eoc_treatment (
    eocid INT NOT NULL,
    tid INT NOT NULL,
    is_primary BOOLEAN NOT NULL,
    eoc_time DATETIME NOT NULL,
    PRIMARY KEY (eocid, tid),
    FOREIGN KEY (eocid) REFERENCES eoc(eocid),
    FOREIGN KEY (tid) REFERENCES treatment_type(tid)
);

-- Anesthesia linked to treatments. A treatment can have multiple anesthesia records, for example if the patient receives anesthesia multiple times during the treatment or if there are different types of anesthesia used. Not all treatments will have anesthesia records, but if they do, they should be linked to the treatment and have a timestamp for when the anesthesia was administered.
CREATE TABLE eoc_treatment_anesthesia (
    eocid INT NOT NULL,
    anesthesia_type NVARCHAR(512) NOT NULL,
    anesthesia_time DATETIME NOT NULL,
    PRIMARY KEY (eocid, anesthesia_time),
    FOREIGN KEY (eocid) REFERENCES eoc(eocid)
);

-- Position during hip replacement surgery. A treatment can have multiple position records, for example if the patient is repositioned during the treatment. Not all treatments will have position records, but if they do, they should be linked to the treatment and have a timestamp for when the position was recorded.
CREATE TABLE hip_treatment_position (
    eocid INT NOT NULL,
    position_type NVARCHAR(512) NOT NULL,
    position_time DATETIME NOT NULL,
    PRIMARY KEY (eocid, position_time),
    FOREIGN KEY (eocid) REFERENCES eoc(eocid)
)

