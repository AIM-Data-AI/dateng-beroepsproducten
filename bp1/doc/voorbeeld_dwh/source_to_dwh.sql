-- =============================================================
-- ETL: CRM + CSV (source) → Data Warehouse (Star Schema)
-- =============================================================
-- Load order:
--   1. dim_date        (from measurement timestamps)
--   2. dim_customer    (from relation)
--   3. dim_product     (from product)
--   4. dim_pump        (from sale_products + interaction)
--   5. fact_measurement (from measurement_staging)
--
-- Pump derivation:
--   A pump is the (product, customer) combination derived from
--   sale_products joined to a customer via interaction.
--   When a customer bought the same product in multiple sales,
--   the earliest sale (MIN sid) is used to determine pump_id.
--
-- dim_date key format: YYYYMMDDHH24MI (e.g. 202406171435)
-- pump_id format     : '<sid>|<pid>'
-- =============================================================

BEGIN TRANSACTION;

-- =============================================================
-- 1. dim_date  (source: measurement_staging)
-- =============================================================
INSERT INTO dim_date (date_key, timestamp, year, month, day, hour, minute)
SELECT DISTINCT
    CAST(FORMAT(ms.timestamp, 'yyyyMMddHHmm') AS INT) AS date_key,
    DATEADD(MINUTE, DATEDIFF(MINUTE, 0, ms.timestamp), 0)  AS timestamp,  -- truncate to minute
    YEAR(ms.timestamp)   AS year,
    MONTH(ms.timestamp)  AS month,
    DAY(ms.timestamp)    AS day,
    DATEPART(HOUR,   ms.timestamp) AS hour,
    DATEPART(MINUTE, ms.timestamp) AS minute
FROM measurement_staging ms
WHERE NOT EXISTS (
    SELECT 1 FROM dim_date dd
    WHERE dd.date_key = CAST(FORMAT(ms.timestamp, 'yyyyMMddHHmm') AS INT)
);

-- =============================================================
-- 2. dim_customer  (source: relation)
-- =============================================================
INSERT INTO dim_customer (rid, rtype, name, address, email, phone)
SELECT r.rid, r.rtype, r.name, r.address, r.email, r.phone
FROM relation r
WHERE NOT EXISTS (
    SELECT 1 FROM dim_customer dc WHERE dc.rid = r.rid
);

-- =============================================================
-- 3. dim_product  (source: product)
-- =============================================================
INSERT INTO dim_product (pid, name)
SELECT p.pid, p.name
FROM product p
WHERE NOT EXISTS (
    SELECT 1 FROM dim_product dp WHERE dp.pid = p.pid
);

-- =============================================================
-- 4. dim_pump  (source: sale_products + interaction)
-- One row per (product, customer) combination.
-- When a customer bought the same product multiple times,
-- the earliest sale (MIN sid) determines sid and installation_date.
-- =============================================================
WITH pump_source AS (
    SELECT
        sp.pid,
        i.rid,
        MIN(sp.sid)               AS sid,
        MIN(sp.installation_date) AS installation_date,
        MAX(sp.price)             AS price,
        MAX(sp.quantity)          AS quantity
    FROM sale_products sp
    JOIN interaction i ON i.sid = sp.sid
    GROUP BY sp.pid, i.rid
)
INSERT INTO dim_pump (pump_id, sid, pid, price, quantity, installation_date)
SELECT
    CAST(ps.sid AS NVARCHAR(20)) + '|' + CAST(ps.pid AS NVARCHAR(20)) AS pump_id,
    ps.sid,
    ps.pid,
    ps.price,
    ps.quantity,
    ps.installation_date
FROM pump_source ps
WHERE NOT EXISTS (
    SELECT 1 FROM dim_pump dp
    WHERE dp.pump_id = CAST(ps.sid AS NVARCHAR(20)) + '|' + CAST(ps.pid AS NVARCHAR(20))
);

-- =============================================================
-- 5. fact_measurement  (source: measurement_staging)
-- pump_id format: '<sid>|<pid>'
-- Deduplication: skip rows already present for (pump_key, date_key).
-- =============================================================
INSERT INTO fact_measurement (pump_key, customer_key, product_key, date_key,
                              temperature, pressure, flow_rate)
SELECT
    dp.pump_key,
    dc.customer_key,
    dpr.product_key,
    CAST(FORMAT(ms.timestamp, 'yyyyMMddHHmm') AS INT) AS date_key,
    ms.temperature,
    ms.pressure,
    ms.flow_rate
FROM measurement_staging ms
JOIN dim_pump dp ON dp.pump_id = ms.pump_id
CROSS APPLY (
    SELECT
        CAST(LEFT (ms.pump_id, CHARINDEX('|', ms.pump_id) - 1)               AS INT) AS sid,
        CAST(RIGHT(ms.pump_id, LEN(ms.pump_id) - CHARINDEX('|', ms.pump_id)) AS INT) AS pid
) parsed
JOIN interaction i   ON i.sid  = parsed.sid
JOIN dim_customer dc ON dc.rid = i.rid
JOIN dim_product  dpr ON dpr.pid = parsed.pid
WHERE NOT EXISTS (
    SELECT 1 FROM fact_measurement fm
    WHERE fm.pump_key = dp.pump_key
      AND fm.date_key = CAST(FORMAT(ms.timestamp, 'yyyyMMddHHmm') AS INT)
);

COMMIT TRANSACTION;
