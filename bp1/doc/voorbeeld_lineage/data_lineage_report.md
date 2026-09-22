# Data Lineage Rapport – Warmtepomp Klantdata Pipeline

**Versie:** 1.0  
**Datum:** 27 mei 2026  
**Eigenaar:** Data Engineering Team  

---

## 1. Inleiding

Dit rapport beschrijft de data lineage van de datapijplijn die klantgegevens over warmtepompen verwerkt. Het doel van deze pijplijn is om verkoopgegevens uit het CRM-systeem te combineren met meetdata van warmtepompsystemen, en deze gecombineerde data beschikbaar te stellen via een data mart die als bron dient voor klantdashboards.

De pijplijn levert inzicht in de prestaties van warmtepompen en klanttevredenheid. De data doorloopt meerdere stadia: van ruwe brondata, via een staging database (voor verkoopdata) en een cloud storage staging area (voor tijdreeksdata), via een data warehouse, naar een data mart die door een externe BI-service wordt bevraagd.

Dit rapport is bedoeld als referentiedocument voor junior data engineers die willen begrijpen hoe data door de pijplijn stroomt, waar data vandaan komt, welke transformaties worden toegepast, wie toegang heeft tot welke data, en welke rapporten worden gegenereerd.

---

## 2. Overzicht van de Data Pipeline

### 2.1 Beschrijving op hoog niveau

De pijplijn bestaat uit zes hoofdstappen:

1. **Extractie van verkoopdata** uit het CRM-systeem (dagelijks)
2. **Inlezen van tijdreeksdata** van warmtepompsystemen via CSV-bestanden (dagelijks)
3. **Data cleaning** van de tijdreeksdata
4. **Aggregatie in een data warehouse** (star schema)
5. **Vullen van een data mart** voor klantdashboards (dagelijks)
6. **Bevragen van de data mart** door een externe BI-service (dagelijks)

### 2.2 Diagram

Het onderstaande diagram geeft een schematisch overzicht van de datastroom door de pijplijn.

```
+---------------------+        +---------------------------+
|   CRM Database      |        |  Cloud Storage Bucket     |
|  (IT Services)      |        |  (Maintenance Team)       |
|                     |        |                           |
|  - relation         |        |  - heat_pump_<id>/*.csv   |
|  - interaction      |        |  - customer_heat_pump.csv |
|  - product          |        +---------------------------+
|  - sale             |                    |
+---------------------+                   |
          |                               |
          | Stap 1: SQL extractie         | Stap 2: CSV inlezen
          | (dagelijks)                   | (dagelijks)
          v                               v
+---------------------+     +---------------------------+
|  Staging Database   |     |  Cloud Storage (Staging)  |
|  (CRM mirror)       |     |  (Data Engineering Team)  |
|                     |     |                           |
|  - relation         |     |  - staging_timeseries/    |
|  - interaction      |     |  - rapport:               |
|  - product          |     |    data_quality_report    |
|  - sale             |     |    _raw.md                |
+---------------------+     +---------------------------+
          |                              |
          |                             | Stap 3: Data cleaning
          |                             v
          |              +---------------------------+
          |              |  Cloud Storage (Cleaned)  |
          |              |  (Data Engineering Team)  |
          |              |                           |
          |              |  - cleaned_timeseries/    |
          |              |  - rapport:               |
          |              |    data_cleaning_report.md|
          |              +---------------------------+
          |                            |
          +------------+--------------+
                       | Stap 4: Aggregatie / loading
                       v
+------------------------------------------+
|             Data Warehouse               |
|        (Data Engineering Team)           |
|                                          |
|  Star schema:                            |
|  - fact_customer                         |
|  - fact_machine                          |
|  - fact_measurement                      |
|  - dim_customer                          |
|  - dim_heatpump                          |
|  - dim_time                              |
+------------------------------------------+
                    |
                    | Stap 5: Aggregatie / loading
                    v
+------------------------------------------+
|               Data Mart                  |
|        (Data Engineering Team)           |
|                                          |
|  - flat table: klant + warmtepomp +      |
|    metingen (gemiddeld per uur,          |
|    afgelopen 24 uur)                     |
|  - rapport: datamart_load_report.md      |
+------------------------------------------+
                    |
                    | Stap 6: Dagelijks bevragen
                    v
+------------------------------------------+
|        Externe BI Service                |
|        (extern, read-only toegang)       |
|                                          |
|  Dashboard:                              |
|  - temp, druk, doorstroming per uur      |
|  - klantinformatie                       |
|  - warmtepomp modelinformatie            |
|  - rapport: bi_query_report.md           |
+------------------------------------------+
```

---

## 3. Data Sources

### 3.1 CRM Database – verkoopdata

**Gekoppeld aan:** Stap 1

**Eigenaar:** IT Services

**Fysieke kenmerken:**  
De CRM-database is een relationele database die beheerd wordt door IT Services. Data wordt via SQL queries geëxtraheerd. De extractie vindt dagelijks plaats. De volgende tabellen zijn relevant voor de pijplijn:

| Tabel         | Beschrijving                                                                                 |
|---------------|----------------------------------------------------------------------------------------------|
| `relation`    | Bevat klantinformatie: naam, relatietype, contactgegevens en adres. Alleen records met relatietype `'customer'` worden meegenomen. |
| `interaction` | Bevat informatie over interacties met relaties, zoals telefoongesprekken en e-mails.         |
| `product`     | Bevat informatie over warmtepompen: model en specificaties.                                   |
| `sale`        | Bevat verkooptransacties: verkoopdatum en prijs. Bevat `relation_id`, `product_id` en `interaction_id` als foreign keys. |

**Logische / conceptuele kenmerken:**  
De tabellen bevatten gezamenlijk de commerciële relatie tussen de organisatie en haar klanten. De `sale`-tabel vormt de kern: deze koppelt klanten (`relation`) aan producten (`product`) en aan de interactie (`interaction`) die tot de verkoop heeft geleid.

**Toegang:**  
- De pijplijn heeft read-only toegang tot de tabellen `relation`, `interaction`, `product` en `sale`.  
- Het sales team heeft read-toegang tot `relation` en `product`.  
- Het sales team heeft write-toegang tot `interaction` en `sale`.  
- Toegangscontrole is gebaseerd op role-based access control (RBAC), beheerd door IT Services.

---

### 3.2 Cloud Storage Bucket – tijdreeksdata warmtepompen

**Gekoppeld aan:** Stap 2

**Eigenaar:** Maintenance Team (toegangsbeheer via IT Services)

**Fysieke kenmerken:**  
De tijdreeksdata wordt opgeslagen in een cloud storage bucket. Elke warmtepomp uploadt dagelijks een CSV-bestand met metingen die elke 5 minuten worden vastgelegd. De bestanden worden opgeslagen in een submap die vernoemd is naar het warmtepomp-ID (bijv. `heat_pump_<id>/`).

De CSV-bestanden hebben de volgende kolommen:

| Kolom           | Beschrijving                                  |
|-----------------|-----------------------------------------------|
| `heat_pump_id`  | Unieke identificatie van de warmtepomp        |
| `timestamp`     | Tijdstip van de meting (elke 5 minuten)       |
| `temperature`   | Gemeten temperatuur                           |
| `pressure`      | Gemeten druk                                  |
| `flow_rate`     | Gemeten debiet                                |

Tevens is er een mapping-bestand `customer_heat_pump.csv` aanwezig in de bucket. Dit bestand koppelt `heat_pump_id` aan klantinformatie.

**Logische / conceptuele kenmerken:**  
De tijdreeksdata vertegenwoordigt de operationele prestaties van warmtepompen bij klanten. Door de koppeling via `customer_heat_pump.csv` kan de prestatie per klant worden gemonitord.

**Toegang:**  
- Elke warmtepomp heeft write-toegang tot zijn eigen submap in de bucket. Ze hebben geen toegang tot mappen van andere warmtepompen.  
- Het Maintenance Team heeft read- en write-toegang tot de gehele bucket voor tijdreeksdata.  
- De pijplijn heeft read-toegang tot de gehele bucket (zie Stap 2).

---

## 4. Transformaties

### 4.1 Stap 1 – Extractie verkoopdata uit CRM (SQL extraction)

**Transformatietype:** Extractie (SQL queries)

De pijplijn voert dagelijks SQL queries uit op de CRM-database om verkoopdata te extraheren. Daarbij worden de tabellen `relation`, `interaction`, `product` en `sale` samengevoegd via de volgende relaties:
- `sale.relation_id` → `relation.id`
- `sale.product_id` → `product.id`
- `sale.interaction_id` → `interaction.id`

Uit de `relation`-tabel worden alleen records meegenomen waarbij het veld `relation_type = 'customer'`.

De geëxtraheerde data wordt opgeslagen in een staging database in de cloud storage area van de pijplijn. Deze staging database spiegelt de tabelstructuur van de CRM-brondatabase: de tabellen `relation`, `interaction`, `product` en `sale` worden als afzonderlijke tabellen overgenomen, met dezelfde kolomstructuur als in de bron.

**Gegenereerde rapporten:** Geen (in deze stap).

---

### 4.2 Stap 2 – Inlezen tijdreeksdata (CSV ingestion)

**Transformatietype:** Inlezen en valideren (CSV parsing, data quality check)

De pijplijn leest dagelijks de CSV-bestanden van de warmtepompen in vanuit de cloud storage bucket. Tevens wordt het mapping-bestand `customer_heat_pump.csv` ingelezen om de koppeling tussen warmtepompen en klanten te kunnen leggen.

De ingelezen data wordt opgeslagen in de staging area van de cloud storage (`staging_timeseries/`).

Na het inlezen wordt een data quality rapport gegenereerd dat kwaliteitsproblemen in de ruwe tijdreeksdata beschrijft. Dit rapport wordt opgeslagen in de cloud storage area van de pijplijn.

**Gegenereerde rapporten:**
- `data_quality_report_raw.md`: Beschrijft kwaliteitsproblemen in de ruwe tijdreeksdata (ontbrekende waarden, ongeldige timestamps, inconsistente metingen, etc.). Dit rapport wordt niet gegenereerd door dit lineage-rapport; het is een apart product van de pijplijn.

**Toegang tot rapport:** Het Maintenance Team heeft read-toegang tot dit rapport, zodat zij inzicht krijgen in de kwaliteit van de data die zij uploaden. IT Services beheert de toegang.

---

### 4.3 Stap 3 – Data cleaning tijdreeksdata

**Transformatietype:** Data cleaning (imputation, deduplication, standardization)

De ruwe tijdreeksdata wordt gecleaned op basis van de stappen die zijn beschreven in het bestand `data_cleaning_report.md` (dit bestand wordt verondersteld aanwezig te zijn). De volgende acties worden uitgevoerd:
- **Imputation**: Ontbrekende waarden worden aangevuld op basis van interpolatie of gemiddelden.
- **Dropping**: Records met ontbrekende timestamps worden verwijderd.
- **Standardization**: Inconsistente waarden (bijv. afwijkende eenheden of notaties) worden gestandaardiseerd.

De gecleande data wordt opgeslagen in de cloud storage area (`cleaned_timeseries/`).

**Gegenereerde rapporten:**
- `data_cleaning_report.md`: Beschrijft de acties die zijn ondernomen om de data te cleanen. Dit rapport wordt niet gegenereerd door dit lineage-rapport.

**Toegang tot rapport:** Het Maintenance Team heeft read-toegang tot dit rapport. IT Services beheert de toegang.

---

### 4.4 Stap 4 – Aggregatie in data warehouse (ETL naar star schema)

**Transformatietype:** Integratie en aggregatie (ETL, star schema loading)

De verkoopdata uit de staging area en de gecleande tijdreeksdata worden gecombineerd en geladen in het data warehouse. Het data warehouse is georganiseerd in een star schema met de volgende tabellen:

**Fact tables:**
- `fact_customer`: Feiten over klanten (gekoppeld aan `dim_customer`)
- `fact_machine`: Feiten over warmtepompen per klant (gekoppeld aan `dim_heatpump`)
- `fact_measurement`: Feiten over metingen (gekoppeld aan `dim_time` en aan dimensies per meetwaarde)

**Dimension tables:**
- `dim_customer`: Klantinformatie (naam, contactgegevens, adres)
- `dim_heatpump`: Warmtepomp informatie (model, specificaties)
- `dim_time`: Tijdsdimensie (timestamp, uur, dag, week, maand)

De koppeling tussen klanten en warmtepompen verloopt via het mapping-bestand `customer_heat_pump.csv`.

**Gegenereerde rapporten:** Geen (in deze stap).

---

### 4.5 Stap 5 – Vullen data mart (aggregatie per uur)

**Transformatietype:** Aggregatie en denormalisatie (data mart loading)

Het data warehouse wordt dagelijks gebruikt als bron voor de data mart. De data mart is een gedenormaliseerde flat table met de meest recente 24 uur aan data, gemiddeld per uur per warmtepomp per klant. De volgende kolommen zijn aanwezig:
- Klantinformatie (naam, contactgegevens, adres)
- Warmtepomp informatie (model, specificaties)
- Gemiddelde `temperature`, `pressure`, `flow_rate` per uur

De data mart wordt dagelijks bijgewerkt tegelijk met het data warehouse.

**Gegenereerde rapporten:**
- `datamart_load_report.md`: Beschrijft het aantal records dat per klant en warmtepomp is geaggregeerd tijdens het laden van de data mart. Dit rapport wordt niet gegenereerd door dit lineage-rapport.

**Toegang tot rapport:** De Data Engineering Team heeft toegang tot dit rapport. IT Services beheert de toegang.

---

### 4.6 Stap 6 – Bevragen data mart door externe BI-service

**Transformatietype:** Data consumptie (read-only query door externe service)

Een externe BI-service bevraagt de data mart dagelijks om een dashboard bij te werken. Het dashboard bevat:
- Grafieken van gemiddelde `temperature`, `pressure` en `flow_rate` per warmtepomp per uur over de afgelopen 24 uur
- Klantinformatie
- Warmtepomp model informatie

Elke keer dat de BI-service de data mart bevraagt, wordt een rapport gegenereerd.

**Gegenereerde rapporten:**
- `bi_query_report.md`: Beschrijft de bevraging van de data mart door de BI-service (tijdstip, aantal records bevraagd, etc.). Dit rapport wordt niet gegenereerd door dit lineage-rapport.

**Toegang tot rapport:** De Data Engineering Team heeft toegang tot dit rapport. De toegang van de externe BI-service tot de data mart wordt gelogd.

---

## 5. Data Storage

### 5.1 CRM Database (brondata)

**Locatie:** On-premise of cloud, beheerd door IT Services  
**Inhoud:** Klantdata, productdata, verkooptransacties en interacties  
**Geladen in pipeline stap:** N.v.t. (is een bron, geen doel)  
**Fysiek:** Relationele database met tabellen `relation`, `interaction`, `product`, `sale`  
**Logisch:** Commerciële klant- en verkoopdata  
**Toegang:** RBAC via IT Services (zie sectie 3.1)

---

### 5.2 Cloud Storage Bucket – ruwe tijdreeksdata

**Locatie:** Cloud storage bucket, beheerd door IT Services  
**Inhoud:** CSV-bestanden met tijdreeksdata van warmtepompen; mapping-bestand `customer_heat_pump.csv`  
**Geladen in pipeline stap:** Stap 2 (door warmtepompsystemen zelf, buiten de pijplijn)  
**Fysiek:** CSV-bestanden, georganiseerd per warmtepomp in submappen  
**Logisch:** Operationele meetdata van warmtepompen  
**Toegang:** Per warmtepomp write-toegang tot eigen submap; Maintenance Team read/write; pijplijn read-only

---

### 5.3 Staging Database – verkoopdata (CRM mirror)

**Locatie:** Cloud storage area, eigendom Data Engineering Team  
**Inhoud:** Spiegel van de relevante CRM-tabellen: `relation` (gefilterd op `relation_type = 'customer'`), `interaction`, `product` en `sale`  
**Geladen in pipeline stap:** Stap 1  
**Fysiek:** Relationele database in de cloud storage area van de pijplijn, met dezelfde tabelstructuur als de CRM-brondatabase  
**Logisch:** Tussenopslag van geëxtraheerde verkoopdata vóór aggregatie in het data warehouse  
**Toegang:** Data Engineering Team (read/write); toegangsbeheer via IT Services

---

### 5.4 Cloud Storage Area – staging tijdreeksdata

**Locatie:** Cloud storage, eigendom Data Engineering Team  
**Inhoud:**  
- `staging_timeseries/`: ingelezen ruwe tijdreeksdata  
- `data_quality_report_raw.md`: rapport over kwaliteit ruwe tijdreeksdata  
**Geladen in pipeline stap:** Stap 2  
**Fysiek:** Bestanden in cloud storage  
**Logisch:** Tussenopslag van ruwe tijdreeksdata vóór cleaning  
**Toegang:** Data Engineering Team (read/write); Maintenance Team read-toegang tot kwaliteitsrapport

---

### 5.5 Cloud Storage Area – gecleande tijdreeksdata

**Locatie:** Cloud storage, eigendom Data Engineering Team  
**Inhoud:**  
- `cleaned_timeseries/`: gecleande tijdreeksdata  
- `data_cleaning_report.md`: rapport over uitgevoerde cleaning-acties  
**Geladen in pipeline stap:** Stap 3  
**Fysiek:** Bestanden in cloud storage  
**Logisch:** Gecleande en gestandaardiseerde meetdata, klaar voor aggregatie  
**Toegang:** Data Engineering Team (read/write); Maintenance Team read-toegang tot cleaning-rapport

---

### 5.6 Data Warehouse

**Locatie:** Cloud, eigendom Data Engineering Team  
**Inhoud:** Star schema met fact tables en dimension tables voor klanten, warmtepompen en metingen  
**Geladen in pipeline stap:** Stap 4  
**Fysiek:** Relationele database (cloud), star schema  
**Logisch:** Geïntegreerde en geaggregeerde data over klanten, warmtepompen en prestatiemetingen  
**Toegang:** Data Engineering Team; toegangsbeheer via IT Services  
**Gegenereerde rapporten:** Geen

---

### 5.7 Data Mart

**Locatie:** Cloud, eigendom Data Engineering Team  
**Inhoud:** Flat table met klantinformatie, warmtepomp informatie en uurgemiddelden van metingen over de afgelopen 24 uur  
**Geladen in pipeline stap:** Stap 5 (dagelijks bijgewerkt)  
**Fysiek:** Gedenormaliseerde flat table in cloud opslag  
**Logisch:** Geaggregeerde en kant-en-klare data voor gebruik in klantdashboards  
**Toegang:** Data Engineering Team (read/write); externe BI-service (read-only, toegang gelogd); toegangsbeheer via IT Services  
**Gegenereerde rapporten:** `datamart_load_report.md` bij elke update

---

## 6. Data Access en Eigenaarschap

De onderstaande tabel geeft een overzicht van het eigenaarschap en de toegangsrechten voor alle datastores en rapportages in de pijplijn.

| Data store / Rapport                        | Eigenaar                  | Read toegang                                              | Write toegang                                          | Toegangsbeheer  |
|---------------------------------------------|---------------------------|-----------------------------------------------------------|--------------------------------------------------------|-----------------|
| CRM Database – `relation`                   | IT Services               | Pijplijn, Sales Team                                      | –                                                      | IT Services (RBAC) |
| CRM Database – `interaction`                | IT Services               | Pijplijn, Sales Team                                      | Sales Team                                             | IT Services (RBAC) |
| CRM Database – `product`                    | IT Services               | Pijplijn, Sales Team                                      | –                                                      | IT Services (RBAC) |
| CRM Database – `sale`                       | IT Services               | Pijplijn                                                  | Sales Team                                             | IT Services (RBAC) |
| Cloud Storage Bucket – tijdreeksdata        | Maintenance Team          | Maintenance Team, pijplijn                                | Maintenance Team, individuele warmtepompen (eigen map) | IT Services     |
| Staging Database (CRM mirror)               | Data Engineering Team     | Data Engineering Team                                     | Data Engineering Team                                  | IT Services     |
| Cloud Storage Area – staging tijdreeksdata  | Data Engineering Team     | Data Engineering Team                                     | Data Engineering Team                                  | IT Services     |
| `data_quality_report_raw.md`                | Data Engineering Team     | Data Engineering Team, Maintenance Team                   | Data Engineering Team                                  | IT Services     |
| Cloud Storage Area – gecleande data         | Data Engineering Team     | Data Engineering Team                                     | Data Engineering Team                                  | IT Services     |
| `data_cleaning_report.md`                   | Data Engineering Team     | Data Engineering Team, Maintenance Team                   | Data Engineering Team                                  | IT Services     |
| Data Warehouse                              | Data Engineering Team     | Data Engineering Team                                     | Data Engineering Team                                  | IT Services     |
| Data Mart                                   | Data Engineering Team     | Data Engineering Team, externe BI-service (read, gelogd)  | Data Engineering Team                                  | IT Services     |
| `datamart_load_report.md`                   | Data Engineering Team     | Data Engineering Team                                     | Data Engineering Team                                  | IT Services     |
| `bi_query_report.md`                        | Data Engineering Team     | Data Engineering Team                                     | Data Engineering Team (gegenereerd door BI-service)    | IT Services     |

---

## 7. Rapporten

De volgende rapporten worden gegenereerd in de loop van de pijplijn. De rapporten zelf worden niet gegenereerd door dit lineage-rapport; ze worden als referentie beschreven.

### 7.1 Data Quality Rapport – ruwe tijdreeksdata

**Bestandsnaam:** `data_quality_report_raw.md`  
**Gegenereerd in:** Stap 2  
**Locatie:** Cloud storage area van de pijplijn  
**Inhoud:** Overzicht van kwaliteitsproblemen in de ruwe tijdreeksdata, zoals ontbrekende waarden, ongeldige of ontbrekende timestamps, en inconsistente meetwaarden. Dit rapport geeft het Maintenance Team inzicht in de kwaliteit van de data die zij uploaden.  
**Doel:** Transparantie over de kwaliteit van ruwe brondata; basis voor eventuele verbeteringen aan de kant van de warmtepompsystemen.  
**Toegang:** Data Engineering Team (eigenaar); Maintenance Team (read-only). Toegangsbeheer via IT Services.

---

### 7.2 Data Cleaning Rapport

**Bestandsnaam:** `data_cleaning_report.md`  
**Gegenereerd in:** Stap 3  
**Locatie:** Cloud storage area van de pijplijn  
**Inhoud:** Overzicht van alle acties die zijn ondernomen om de tijdreeksdata te cleanen: welke records zijn verwijderd, welke waarden zijn geïmputeerd, en hoe inconsistenties zijn gestandaardiseerd.  
**Doel:** Traceerbaarheid van de cleaning-stappen; basis voor audit en verantwoording.  
**Toegang:** Data Engineering Team (eigenaar); Maintenance Team (read-only). Toegangsbeheer via IT Services.

---

### 7.3 Data Mart Load Rapport

**Bestandsnaam:** `datamart_load_report.md`  
**Gegenereerd in:** Stap 5  
**Locatie:** Cloud storage area van de pijplijn  
**Inhoud:** Overzicht van het aantal records dat per klant en per warmtepomp is geaggregeerd tijdens het dagelijks laden van de data mart.  
**Doel:** Monitoring van de volledigheid van de dagelijkse data mart update; signalering van eventuele afwijkingen.  
**Toegang:** Data Engineering Team. Toegangsbeheer via IT Services.

---

### 7.4 BI Service Query Rapport

**Bestandsnaam:** `bi_query_report.md`  
**Gegenereerd in:** Stap 6  
**Locatie:** Cloud storage area van de pijplijn  
**Inhoud:** Logboek van elke bevraging van de data mart door de externe BI-service, inclusief tijdstip van bevraging en het aantal opgehaalde records.  
**Doel:** Audit trail van externe toegang tot de data mart; monitoring van het gebruik van de data door de BI-service.  
**Toegang:** Data Engineering Team. De toegang van de externe BI-service tot de data mart wordt gelogd (de service heeft zelf geen toegang tot dit rapport). Toegangsbeheer via IT Services.

---

*Einde van het Data Lineage Rapport*
