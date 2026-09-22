-- =============================================================
-- Wachttijden MSZ — NZa Wachttijden OpenAPI (WaitingTimeMSZ)
-- =============================================================
-- Target: SQLite3
--
-- Source : https://zorgbeeld.nza.nl/rest-doc/openapi, endpoint
--          GET /WaitingTimeMSZ (schema TL_REST). Fetched via
--          fetch_api_data.py into wachttijden_latest.json, which
--          loads directly into this table (JSON field -> column,
--          see the mapping in each column's comment below).
--
-- This table is a local mirror of the API response, so students can
-- query it repeatedly without hitting the real NZa API each time.
-- Each row is one (vestiging, zorg) wachttijd as reported live on
-- the Zorgbeeldportaal at the time of fetching -- the API itself
-- has no history, so re-running fetch_api_data.py and reloading
-- this table on different days is how a time series gets built up
-- (see snapshot_date). The UNIQUE constraint below stops a re-run
-- on the same day from duplicating rows.
--
-- Note: NZa's separate bulk historical export (see
-- filter_history.py / wachttijden_history.csv) uses different
-- column names for largely the same information (e.g.
-- KVK_INSTELLING / KVK_VESTIGING_NR instead of kvk_number /
-- kvk_location_number) -- reconciling the two is intentionally
-- left out of scope here.
-- =============================================================

DROP TABLE IF EXISTS wachttijden_msz;

CREATE TABLE wachttijden_msz (
    id                         INTEGER NOT NULL,

    -- Date            : moment this snapshot was retrieved from the API
    snapshot_date              TEXT    NOT NULL,

    -- KVKNumber, CareProvider, CareProvider_AGBCode : de onderneming
    kvk_number                 TEXT    NOT NULL,
    care_provider              TEXT    NOT NULL,
    care_provider_agb_code     TEXT,

    -- LocationKey, KVKLocationNumber, Location_AGBCode, Location,
    -- Street, StreetNumber, PostalCode, City : de vestiging
    location_key                TEXT    NOT NULL,   -- portal-assigned GUID for the vestiging
    kvk_location_number         TEXT,                -- vestigingsnummer
    location_agb_code           TEXT,
    location                    TEXT    NOT NULL,
    street                      TEXT,
    street_number                TEXT,
    postal_code                 TEXT,
    city                         TEXT,

    -- TreatmentKey, TreatmentNumber, Treatment, TreatmentType,
    -- Specialism, Description : de zorg (behandeling/polikliniekbezoek/diagnostiek)
    treatment_key                TEXT    NOT NULL,   -- portal-assigned GUID for the zorg
    treatment_number             TEXT,
    treatment                    TEXT    NOT NULL,
    treatment_type                TEXT    NOT NULL,
    specialism                   TEXT,
    description                  TEXT,

    -- WaitingTime, InsufficientObservations : de wachttijd zelf
    waiting_time_days            INTEGER,             -- wachttijd in kalenderdagen; NULL wanneer onvoldoende waarnemingen
    insufficient_observations    TEXT    NOT NULL,

    -- AllCareproviders : niet gedocumenteerd in de PDF-documentatie, wel aanwezig in de API-respons
    all_careproviders            INTEGER NOT NULL DEFAULT 0,

    CONSTRAINT PK_wachttijden_msz          PRIMARY KEY (id),
    CONSTRAINT UQ_wachttijden_msz_snapshot UNIQUE (location_key, treatment_key, snapshot_date),
    CONSTRAINT CK_wachttijden_msz_type     CHECK (treatment_type IN ('Behandeling', 'Polikliniekbezoek', 'Diagnostiek')),
    CONSTRAINT CK_wachttijden_msz_obs      CHECK (insufficient_observations IN ('Ja', 'Nee')),
    CONSTRAINT CK_wachttijden_msz_bool     CHECK (all_careproviders IN (0, 1)),
    CONSTRAINT CK_wachttijden_msz_days     CHECK (waiting_time_days IS NULL OR waiting_time_days >= 0),
    -- WaitingTime is only present when there are enough observations to compute it
    CONSTRAINT CK_wachttijden_msz_consistency CHECK (
        (insufficient_observations = 'Ja'  AND waiting_time_days IS NULL)
        OR
        (insufficient_observations = 'Nee' AND waiting_time_days IS NOT NULL)
    )
);
