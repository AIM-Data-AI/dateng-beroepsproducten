-- Data Warehouse (Star Schema)
-- Dimensions: dim_pump, dim_customer, dim_product, dim_date
-- Fact table:  fact_measurement (sensor measurements)
--
-- Sources:
--   dim_pump     : sale_products (sid, pid, price, quantity, installation_date)
--   dim_customer : relation (rid, rtype, name, address, email, phone)
--   dim_product  : product (pid, name)
--   dim_date     : derived from measurement.timestamp
--   fact_measurement : measurement CSV (temperature, pressure, flow_rate)
--
-- pump_key is based on pump_id = combination of sid + pid

-- ============================================================
-- Dimensions
-- ============================================================

CREATE TABLE dim_pump (
    pump_key          INT           NOT NULL IDENTITY(1,1),
    pump_id           NVARCHAR(50)  NOT NULL,   -- business key: sid|pid
    sid               INT           NOT NULL,
    pid               INT           NOT NULL,
    price             DECIMAL(10,2),
    quantity          INT,
    installation_date DATE,
    CONSTRAINT PK_dim_pump        PRIMARY KEY (pump_key),
    CONSTRAINT UQ_dim_pump_pumpid UNIQUE (pump_id)
);

CREATE TABLE dim_customer (
    customer_key INT           NOT NULL IDENTITY(1,1),
    rid          INT           NOT NULL,   -- business key from CRM
    rtype        NVARCHAR(50)  NOT NULL,
    name         NVARCHAR(255) NOT NULL,
    address      NVARCHAR(500),
    email        NVARCHAR(255) NOT NULL,
    phone        NVARCHAR(50),
    CONSTRAINT PK_dim_customer     PRIMARY KEY (customer_key),
    CONSTRAINT UQ_dim_customer_rid UNIQUE (rid)
);

CREATE TABLE dim_product (
    product_key INT           NOT NULL IDENTITY(1,1),
    pid         INT           NOT NULL,   -- business key from CRM
    name        NVARCHAR(255) NOT NULL,
    CONSTRAINT PK_dim_product     PRIMARY KEY (product_key),
    CONSTRAINT UQ_dim_product_pid UNIQUE (pid)
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

-- ============================================================
-- Fact table
-- ============================================================

CREATE TABLE fact_measurement (
    pump_key     INT           NOT NULL,
    customer_key INT           NOT NULL,
    product_key  INT           NOT NULL,
    date_key     INT           NOT NULL,
    temperature  DECIMAL(8,2),
    pressure     DECIMAL(8,2),
    flow_rate    DECIMAL(8,2),
    CONSTRAINT PK_fact_measurement PRIMARY KEY (pump_key, date_key),
    CONSTRAINT FK_fact_dim_pump     FOREIGN KEY (pump_key)     REFERENCES dim_pump     (pump_key),
    CONSTRAINT FK_fact_dim_customer FOREIGN KEY (customer_key) REFERENCES dim_customer (customer_key),
    CONSTRAINT FK_fact_dim_product  FOREIGN KEY (product_key)  REFERENCES dim_product  (product_key),
    CONSTRAINT FK_fact_dim_date     FOREIGN KEY (date_key)     REFERENCES dim_date     (date_key)
);
