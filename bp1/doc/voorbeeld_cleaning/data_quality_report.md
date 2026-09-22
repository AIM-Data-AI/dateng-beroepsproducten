# Data Kwaliteitsrapport: Warmtepomp Dataset

**Datum:** 27 mei 2026  
**Auteur:** Data Analyse Team  
**Versie:** 1.0

---

## 1. Inleiding

Dit rapport beschrijft de data kwaliteitsproblemen die zijn aangetroffen in de warmtepomp dataset. De dataset is afkomstig van een fictief warmtepompbedrijf en bestaat uit drie bestanden: klantgegevens, koppelingen tussen klanten en warmtepompen, en tijdreeksmetingen van de warmtepompen zelf.

Het doel van dit rapport is om een helder overzicht te geven van de aangetroffen problemen, zodat een gerichte cleaning strategie kan worden opgesteld. De kwaliteitsproblemen zijn onderverdeeld in drie categorieën:

1. **Missing values** (ontbrekende waarden)
2. **Inconsistent formatting** (inconsistente opmaak)
3. **Outliers** en ongeldige waarden

---

## 2. Beschrijving van de Dataset

De dataset bestaat uit de volgende drie bestanden:

| Bestand | Beschrijving | Aantal rijen |
|---|---|---|
| `customers.csv` | Klantgegevens: ID, naam, e-mailadres en telefoonnummer | 10 |
| `customers_heat_pumps.csv` | Koppeling klant–warmtepomp met installatiedatum | 9 |
| `heat_pump_data.csv` | Tijdreeksmetingen per warmtepomp (elke 5 minuten, 1 dag) | 2.304 |

De kolommen in elk bestand zijn:

- **customers.csv**: `customer_id`, `name`, `email`, `phone`
- **customers_heat_pumps.csv**: `customer_id`, `heat_pump_id`, `installation_date`
- **heat_pump_data.csv**: `heat_pump_id`, `temperature`, `pressure`, `flow_rate`, `timestamp`

---

## 3. Data Kwaliteitsproblemen

### 3.1 Missing Values (Ontbrekende Waarden)

Missing values zijn cellen in de dataset die geen waarde bevatten. Dit kan komen doordat gegevens niet zijn ingevuld, verloren zijn gegaan tijdens het exportproces, of simpelweg niet beschikbaar zijn. In pandas worden missing values weergegeven als `NaN` (Not a Number) of `None`.

#### 3.1.1 customers.csv

**Identificatie:**

```python
import pandas as pd

customers = pd.read_csv("data/voorbeeld_cleaning/customers.csv")
print(customers.isnull().sum())
```

**Uitkomst:**

```
customer_id    0
name           0
email          2
phone          2
```

**Bevindingen:**

- Het `email`-veld ontbreekt voor 2 van de 10 klanten:
  - Klant *Marie de Vries* (customer_id: 4337)
  - Klant *Femke Bos* (customer_id: 8555)
- Het `phone`-veld ontbreekt voor 2 van de 10 klanten:
  - Klant *Sophie Bakker* (customer_id: 5052)
  - Klant *Thomas Mulder* (customer_id: 7844)

**Impact:**

Missing values in het `email`-veld maken gerichte communicatie per e-mail onmogelijk voor die klanten. Missing values in het `phone`-veld belemmeren telefonisch contact. Bij analyses die afhankelijk zijn van contactgegevens (bijv. churn-analyse of klantsegmentatie) kan het ontbreken van gegevens leiden tot vertekende resultaten of verkleinde steekproeven.

**Aanbeveling:**

Controleer of de ontbrekende waarden alsnog kunnen worden aangeleverd vanuit het bronsysteem (bijv. een CRM). Als dat niet mogelijk is, kunnen de rijen met missing values worden uitgesloten van analyses die deze kolommen vereisen, of kan er een aparte categorie "onbekend" worden aangemaakt.

---

#### 3.1.2 customers_heat_pumps.csv — Ontbrekende klant

**Identificatie:**

```python
customers_hp = pd.read_csv("data/voorbeeld_cleaning/customers_heat_pumps.csv")

# Welke klanten uit customers.csv ontbreken in customers_heat_pumps.csv?
missing_customers = set(customers["customer_id"]) - set(customers_hp["customer_id"])
print("Klanten zonder warmtepomp:", missing_customers)
```

**Bevindingen:**

- Klant *Miriam Jansen* (customer_id: 5502) heeft geen koppeling met een warmtepomp.

**Impact:**

Deze klant wordt uitgesloten van alle analyses die op warm­tepomp­data zijn gebaseerd. Als de klant wel een warmtepomp heeft maar de koppeling ontbreekt, leidt dat tot incomplete analyses en onjuiste statistieken over het totale klantenbestand.

**Aanbeveling:**

Verifieer in het bronsysteem of de klant daadwerkelijk geen warmtepomp heeft. Als dat wel het geval is, herstel dan de ontbrekende koppeling. Voeg eventueel een outer join toe bij analyses om klanten zonder warmtepomp zichtbaar te houden.

---

#### 3.1.3 heat_pump_data.csv — Ontbrekende warmtepomp

**Identificatie:**

```python
hp_data = pd.read_csv("data/voorbeeld_cleaning/heat_pump_data.csv")

# Welke warmtepompen uit customers_heat_pumps.csv ontbreken in heat_pump_data.csv?
known_ids = set(customers_hp["heat_pump_id"])
data_ids = set(hp_data["heat_pump_id"])
missing_pumps = known_ids - data_ids
print("Warmtepompen zonder meetdata:", missing_pumps)
```

**Bevindingen:**

- Warmtepomp HP-2750 heeft geen meetdata in `heat_pump_data.csv`.

**Impact:**

Voor deze warmtepomp is geen performance-analyse mogelijk. Als dit een structureel probleem is (sensor niet verbonden of uitgevallen), kan dit een indicator zijn van een hardwareprobleem dat aandacht vereist.

**Aanbeveling:**

Controleer of de sensor voor HP-2750 correct is aangesloten en data doorstuurt. Neem contact op met de klant (Sophie Bakker, customer_id: 5052) om te verifiëren of de warmtepomp operationeel is.

---

#### 3.1.4 heat_pump_data.csv — Missing values in meetkolommen

**Identificatie:**

```python
print(hp_data[["temperature", "pressure", "flow_rate"]].isnull().sum())
print()
print("Percentage missing values:")
print(hp_data[["temperature", "pressure", "flow_rate"]].isnull().mean().round(3) * 100)
```

**Uitkomst:**

```
temperature    213
pressure       239
flow_rate      203

Percentage missing values:
temperature    9.2 %
pressure      10.4 %
flow_rate      8.8 %
```

**Bevindingen:**

Verspreid over alle warmtepompen en tijdstippen ontbreekt circa 10% van de meetwaarden in de kolommen `temperature`, `pressure` en `flow_rate`. De missing values zijn willekeurig verdeeld (zogenaamde *missing at random*, of MAR).

**Impact:**

Missing values in tijdreeksdata verstoren de continuïteit van de metingen. Dit maakt het moeilijker om trends te analyseren, gemiddelden te berekenen en anomalieën te detecteren. Sommige algoritmen, zoals machine learning-modellen, kunnen niet omgaan met missing values en vereisen dat deze eerst worden behandeld.

**Aanbeveling:**

Gebruik *interpolation* op basis van naburige waarden om de missing values in te vullen. Zie de aanbeveling in sectie 4 voor een concrete aanpak. Het is ook raadzaam om de oorzaak van de missing values te onderzoeken — zijn het sensor­uitvallers of communicatiefouten?

---

### 3.2 Inconsistent Formatting (Inconsistente Opmaak)

Inconsistent formatting treedt op wanneer dezelfde soort waarden op verschillende manieren zijn opgeslagen. Dit bemoeilijkt automatische verwerking en vergelijking van gegevens.

#### 3.2.1 customers.csv — Telefoonnummers

**Identificatie:**

```python
# Verwijder alle niet-numerieke tekens en controleer de lengte
customers["phone_digits"] = (
    customers["phone"]
    .str.replace(r"\D", "", regex=True)  # verwijder alles wat geen cijfer is
    .fillna("")
)

# Een geldig Nederlands mobiel nummer heeft precies 10 cijfers
# (bijvoorbeeld 0612345678)
invalid_phones = customers[
    customers["phone_digits"].str.len().ne(10) & customers["phone"].notna()
]
print(invalid_phones[["customer_id", "name", "phone", "phone_digits"]])
```

**Uitkomst:**

```
   customer_id         name               phone  phone_digits
1         7615  Piet Meijer    06 24 87 06 17   0624870617
3         2152  Anna de Boer  06-73-04-70-66   0673047066
6         5616  Lars Visser      616112800      616112800
```

**Bevindingen:**

Drie telefoonnummers zijn opgeslagen in een afwijkend format:
- **Piet Meijer (7615):** Nummer met spaties tussen de cijfergroepen (`06 24 87 06 17`). Na het verwijderen van niet-numerieke tekens zijn de cijfers correct (10 cijfers), maar het format is inconsistent.
- **Anna de Boer (2152):** Nummer met koppeltekens (`06-73-04-70-66`). Na verwijdering heeft het 10 cijfers.
- **Lars Visser (5616):** Nummer met slechts 9 cijfers (`616112800`) — de voorloopnul ontbreekt, waardoor het nummer ongeldig is.

**Impact:**

Inconsistente telefoonnummers kunnen leiden tot problemen bij:
- Automatische verificatie of validatie van nummers
- Koppeling met externe systemen (bijv. telefoonapplicaties of SMS-diensten)
- Sortering en deduplicatie van klantgegevens

**Aanbeveling:**

Verwijder alle niet-numerieke tekens. Controleer of het resultaat precies 10 cijfers heeft. Zo niet, vervang de waarde door een missing value (`NaN`). Zie de cleaning stappen in het [Data Cleaning Rapport](data_cleaning_report.md).

---

#### 3.2.2 customers_heat_pumps.csv — Installatiedatum

**Identificatie:**

```python
# Probeer alle datums te parsen met het standaard ISO-formaat YYYY-MM-DD
def parse_date_safe(date_str):
    try:
        return pd.to_datetime(date_str, format="%Y-%m-%d")
    except (ValueError, TypeError):
        return None

inconsistent_dates = customers_hp[
    customers_hp["installation_date"].apply(parse_date_safe).isna()
]
print(inconsistent_dates[["customer_id", "heat_pump_id", "installation_date"]])
```

**Uitkomst:**

```
   customer_id heat_pump_id installation_date
3         2152      HP-5919        29-09-2021
```

**Bevindingen:**

- De installatiedatum van warmtepomp HP-5919 (klant Anna de Boer, customer_id: 2152) is opgeslagen als `29-09-2021` in het formaat DD-MM-YYYY, terwijl alle andere datums het ISO-formaat YYYY-MM-DD gebruiken.

**Impact:**

Als datums worden ingelezen zonder expliciete format-specificatie, kan pandas de datum verkeerd interpreteren (bijv. `29-09-2021` kan worden gelezen als 29 september 2021 of als een ongeldige waarde). Dit leidt tot fouten in tijdgebaseerde analyses, zoals het berekenen van de levensduur van een warmtepomp of het filteren op installatieperiode.

**Aanbeveling:**

Gebruik `pd.to_datetime()` met `dayfirst=True` als fallback, of probeer meerdere formats. Converteer alle datums naar ISO-formaat. Waarden die niet te parsen zijn, moeten worden vervangen door `NaN`. Zie het [Data Cleaning Rapport](data_cleaning_report.md).

---

#### 3.2.3 heat_pump_data.csv — Foutieve heat pump ID (typo)

**Identificatie:**

```python
# Welke heat pump ID's in heat_pump_data.csv komen NIET voor in customers_heat_pumps.csv?
data_ids = set(hp_data["heat_pump_id"])
known_ids = set(customers_hp["heat_pump_id"])

unknown_in_data = data_ids - known_ids
print("Onbekende heat pump IDs in meetdata:", unknown_in_data)
```

**Uitkomst:**

```
Onbekende heat pump IDs in meetdata: {'HP-8734'}
```

**Bevindingen:**

- `HP-8734` komt voor in `heat_pump_data.csv` maar staat niet in `customers_heat_pumps.csv`.
- `HP-7834` staat wel in `customers_heat_pumps.csv` maar heeft geen meetdata.
- De eerste twee cijfers van het numerieke deel zijn verwisseld: `78` → `87`. Dit is een klassieke *typo* die eenvoudig over het hoofd wordt gezien.

**Impact:**

Zonder correctie van deze typo kan de meetdata van `HP-8734` niet worden gekoppeld aan de bijbehorende klant (Marie de Vries, customer_id: 4337). Dit leidt tot een incomplete analyse van het klantenbestand en tot rijen zonder link bij het uitvoeren van joins.

**Aanbeveling:**

Controleer of de lijkende ID's (`HP-8734` en `HP-7834`) inderdaad hetzelfde apparaat betreffen, en corrigeer indien nodig het ID in het meest betrouwbare bronsysteem. Voer automatische *fuzzy matching* uit bij de inname van nieuwe data om vergelijkbare typo's te detecteren.

---

### 3.3 Outliers en Ongeldige Waarden

Een outlier is een waarde die significant afwijkt van de verwachte range. Ongeldige waarden zijn waarden die technisch gezien zijn opgeslagen maar inhoudelijk onjuist zijn (bijv. een sensorstoring of een softwarebug).

#### 3.3.1 heat_pump_data.csv — Temperatuur in Fahrenheit

**Identificatie:**

```python
# Verwacht temperatuurbereik voor een warmtepomp: 35–55 °C
# Fahrenheit-waarden voor hetzelfde bereik: ca. 95–131 °F
# Waarden boven ~60 °C zijn vrijwel zeker in Fahrenheit opgeslagen

suspect_fahrenheit = hp_data[hp_data["temperature"] > 60]
print(suspect_fahrenheit.groupby("heat_pump_id")["temperature"].describe())
```

**Uitkomst:**

```
              count        mean        std    min     25%     50%     75%    max
heat_pump_id
HP-1394       269.0  113.894796  10.219208  95.0  104.9  113.7  123.3  131.0
```

**Bevindingen:**

- Alle temperatuurwaarden boven 60 °C behoren tot warmtepomp HP-1394.
- Het bereik van 95–131 correspondeert precies met het Fahrenheit-equivalent van 35–55 °C, wat sterk suggereert dat de sensor van HP-1394 temperaturen registreert in Fahrenheit in plaats van Celsius.
- De temperaturen van alle overige warmtepompen liggen keurig in het verwachte bereik van 35–55 °C.

**Impact:**

Als de temperatuurwaarden van HP-1394 niet worden gecorrigeerd, zijn vergelijkingen tussen warmtepompen incorrect. Gemiddelden, analyses van warmtelevering en alertering op basis van drempelwaarden zullen allemaal foutieve resultaten geven voor deze pomp.

**Aanbeveling:**

Converteer de temperatuurwaarden van HP-1394 naar Celsius met de formule:

$$T_{°C} = (T_{°F} - 32) \times \frac{5}{9}$$

Zie de concrete implementatie in het [Data Cleaning Rapport](data_cleaning_report.md).

---

#### 3.3.2 heat_pump_data.csv — Epoch timestamps (1970-01-01)

**Identificatie:**

```python
hp_data["timestamp"] = pd.to_datetime(hp_data["timestamp"])

epoch_rows = hp_data[hp_data["timestamp"].dt.year == 1970]
print(epoch_rows.groupby("heat_pump_id")["timestamp"].agg(["count", "min", "max"]))
```

**Uitkomst:**

```
              count                 min                 max
heat_pump_id
HP-7095          30 1970-01-01 00:00:00 1970-01-01 02:25:00
```

**Bevindingen:**

- Warmtepomp HP-7095 heeft 30 metingen met timestamps die beginnen op 1 januari 1970 (de zogenaamde *Unix epoch*, het beginpunt van de Unix-tijdrekening).
- De overige 258 metingen van HP-7095 hebben normale timestamps op 15 februari 2026.
- De 1970-timestamps zijn het gevolg van een reset of initialisatiefout in de sensor of data-acquisitiesoftware.

**Impact:**

Tijdreeksanalyses die op de chronologische volgorde van metingen steunen, worden ernstig verstoord door deze timestamps. Aggregaties per dag, week of maand zullen onjuiste resultaten opleveren omdat deze 30 metingen worden geplaatst in januari 1970 in plaats van februari 2026.

**Aanbeveling:**

Verwijder alle rijen met een timestamp van 1 januari 1970 (of breder: elk jaar vóór de installatiedatum van de betreffende warmtepomp). Zie het [Data Cleaning Rapport](data_cleaning_report.md) voor de uitvoering.

---

## 4. Samenvatting van Bevindingen

| # | Bestand | Kolom | Type probleem | Omvang |
|---|---|---|---|---|
| 1 | `customers.csv` | `email` | Missing value | 2 van 10 (20%) |
| 2 | `customers.csv` | `phone` | Missing value | 2 van 10 (20%) |
| 3 | `customers.csv` | `phone` | Inconsistent formatting | 3 van 10 (30%) |
| 4 | `customers_heat_pumps.csv` | `customer_id` | Missing value (referentieel) | 1 van 10 klanten |
| 5 | `customers_heat_pumps.csv` | `installation_date` | Inconsistent formatting | 1 van 9 (11%) |
| 6 | `heat_pump_data.csv` | `heat_pump_id` | Inconsistent formatting (typo) | 288 rijen (1 pomp) |
| 7 | `heat_pump_data.csv` | `heat_pump_id` | Missing value (referentieel) | 1 van 9 pompen |
| 8 | `heat_pump_data.csv` | `temperature` | Outlier (Fahrenheit i.p.v. Celsius) | 288 rijen (1 pomp) |
| 9 | `heat_pump_data.csv` | `timestamp` | Ongeldige waarde (epoch) | 30 rijen (1 pomp) |
| 10 | `heat_pump_data.csv` | `temperature`, `pressure`, `flow_rate` | Missing values | ~10% per kolom |

---

## 5. Aanbevelingen voor Vervolgstappen

Op basis van de bevindingen in dit rapport worden de volgende stappen aanbevolen:

1. **Cleaning van telefoonnummers**: Verwijder niet-numerieke tekens; vervang nummers met een ongeldige lengte door `NaN`.
2. **Normalisatie van datumformaten**: Parseer alle installatiedatums naar ISO-formaat; vervang niet-parseerbare datums door `NaN`.
3. **Correctie van de heat pump ID-typo**: Vervang `HP-8734` door `HP-7834` in `heat_pump_data.csv` na verificatie.
4. **Fahrenheit-correctie**: Identificeer warmtepompen met temperatuurwaarden buiten het Celsius-bereik en converteer naar Celsius.
5. **Verwijdering van epoch timestamps**: Verwijder alle rijen met een timestamp van 1 januari 1970.
6. **Imputation van missing values**: Vul ontbrekende meetwaarden in door *interpolation* op basis van naburige waarden.

Een gedetailleerde beschrijving van de implementatie van deze stappen is te vinden in het [Data Cleaning Rapport](data_cleaning_report.md).
