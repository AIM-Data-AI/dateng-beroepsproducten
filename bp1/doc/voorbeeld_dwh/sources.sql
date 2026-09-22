-- CRM Database

CREATE TABLE sale (
    sid INT NOT NULL,
    CONSTRAINT PK_sale PRIMARY KEY (sid)
);

CREATE TABLE product (
    pid INT NOT NULL,
    name NVARCHAR(255) NOT NULL,
    CONSTRAINT PK_product PRIMARY KEY (pid)
);

CREATE TABLE sale_products (
    sid INT NOT NULL,
    pid INT NOT NULL,
    quantity INT,
    installation_date DATE,
    price DECIMAL(10, 2),
    CONSTRAINT PK_sale_products PRIMARY KEY (sid, pid),
    CONSTRAINT FK_sale_products_sale    FOREIGN KEY (sid) REFERENCES sale (sid),
    CONSTRAINT FK_sale_products_product FOREIGN KEY (pid) REFERENCES product (pid)
);

CREATE TABLE relation (
    rid     INT           NOT NULL,
    rtype   NVARCHAR(50)  NOT NULL,
    name    NVARCHAR(255) NOT NULL,
    address NVARCHAR(500),
    email   NVARCHAR(255) NOT NULL,
    phone   NVARCHAR(50),
    CONSTRAINT PK_relation PRIMARY KEY (rid)
);

CREATE TABLE interaction (
    idts  DATETIME2    NOT NULL,
    rid   INT          NOT NULL,
    type  NVARCHAR(50) NOT NULL,
    sid   INT,
    notes NVARCHAR(MAX),
    CONSTRAINT PK_interaction PRIMARY KEY (idts, rid),
    CONSTRAINT FK_interaction_relation FOREIGN KEY (rid) REFERENCES relation (rid),
    CONSTRAINT FK_interaction_sale     FOREIGN KEY (sid) REFERENCES sale (sid)
);

-- Staging table for measurement CSV files
-- pump_id is a combination of sid and pid (references sale_products)
CREATE TABLE measurement_staging (
    pump_id     NVARCHAR(50) NOT NULL,  -- composite of sid + pid
    timestamp   DATETIME2    NOT NULL,
    temperature DECIMAL(8, 2),
    pressure    DECIMAL(8, 2),
    flow_rate   DECIMAL(8, 2)
);
