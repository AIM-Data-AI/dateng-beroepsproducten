-- Staging area for relevant EPD data. This staging area is used to copy data from the EPD. Its DDL is identical to that of the relevant EPD tables.
CREATE TABLE patient (
   pid INT PRIMARY KEY NOT NULL,
   firstname NVARCHAR(512) NOT NULL,
   lastname NVARCHAR(512) NOT NULL,
   dob DATE NULL,
   treatment NVARCHAR(512) NOT NULL
);

CREATE TABLE patient_observation (
    poid INT PRIMARY KEY NOT NULL,
    pid INT NOT NULL,
    note_ts DATETIME NOT NULL,
    note_text TEXT NOT NULL,
    pain_score INT NOT NULL CHECK (pain_score >= 0 AND pain_score <= 10),
    FOREIGN KEY (pid) REFERENCES patient(pid)
);
