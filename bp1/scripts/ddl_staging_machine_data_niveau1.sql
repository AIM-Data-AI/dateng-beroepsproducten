-- DDL for staging table to hold machine data from the source system before loading into the Data Vault.
CREATE TABLE staging_machine_data (
    mid INT PRIMARY KEY NOT NULL,
    pid INT NOT NULL,
    ts DATETIME NOT NULL,
    sbp FLOAT NOT NULL,
    dbp FLOAT NOT NULL,
    hr FLOAT NOT NULL,
    fluids_given FLOAT NOT NULL,
    blood_lost FLOAT NOT NULL,
    blood_given FLOAT NOT NULL
);