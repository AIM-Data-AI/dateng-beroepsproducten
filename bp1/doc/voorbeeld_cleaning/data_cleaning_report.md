# Data Cleaning Rapport: Warmtepomp Dataset

**Datum:** 27 mei 2026  
**Auteur:** Data Analyse Team  
**Versie:** 1.0

---

## 1. Introductie

Dit rapport beschrijft het cleaning proces dat is uitgevoerd op de warmtepomp dataset. Het doel van data cleaning is om de dataset geschikt te maken voor betrouwbare analyse door onjuiste, ontbrekende of inconsistente waarden te corrigeren of te verwijderen.

De dataset bestaat uit drie bestanden:

- `data/voorbeeld_cleaning/customers.csv` — klantgegevens
- `data/voorbeeld_cleaning/customers_heat_pumps.csv` — koppeling klant–warmtepomp
- `data/voorbeeld_cleaning/heat_pump_data.csv` — tijdreeksmetingen

De kwaliteitsproblemen in deze dataset zijn beschreven in het [Data Kwaliteitsrapport](data_quality_report.md). Dit rapport verwijst per stap naar het betreffende probleem in dat document.

---

## 2. Uitgevoerde Stappen (Steps Taken)

### Stap 1 — Cleaning van telefoonnummers in `customers.csv`

**Verwijzing:** [Data Kwaliteitsrapport §3.2.1](data_quality_report.md#321-customerscsv--telefoonnummers)

**Rationale:**

De telefoonnummers in `customers.csv` zijn opgeslagen in drie verschillende formats: zonder separatoren, met spaties, en met koppeltekens. Daarnaast is één nummer te kort doordat de voorloopnul ontbreekt. Om te kunnen valideren of een telefoonnummer geldig is, worden eerst alle niet-numerieke tekens verwijderd. Vervolgens wordt gecontroleerd of het resultaat precies 10 cijfers telt — het vereiste aantal voor een geldig Nederlands telefoonnummer (inclusief netnummer). Nummers die deze controle niet doorstaan, worden vervangen door een missing value (`NaN`).

**Implementatie:**

```python
import pandas as pd

customers = pd.read_csv("data/voorbeeld_cleaning/customers.csv")

# Verwijder alle niet-numerieke tekens uit het telefoonnummer
customers["phone_cleaned"] = (
    customers["phone"]
    .str.replace(r"\D", "", regex=True)  # \D = alles wat géén cijfer is
)

# Een geldig Nederlands telefoonnummer (mobiel of vast) telt precies 10 cijfers.
# Nummers met een andere lengte (bijv. te kort of te lang) worden als ongeldig
# beschouwd en vervangen door NaN.
VALID_PHONE_LENGTH = 10

customers["phone_cleaned"] = customers["phone_cleaned"].where(
    customers["phone_cleaned"].str.len() == VALID_PHONE_LENGTH
)

# Vervang de originele kolom door de gecleande versie
customers["phone"] = customers["phone_cleaned"]
customers = customers.drop(columns=["phone_cleaned"])

print(customers[["customer_id", "name", "phone"]])
```

**Resultaat:**

| customer_id | name | phone (voor) | phone (na) |
|---|---|---|---|
| 7615 | Piet Meijer | `06 24 87 06 17` | `0624870617` |
| 2152 | Anna de Boer | `06-73-04-70-66` | `0673047066` |
| 5616 | Lars Visser | `616112800` | `NaN` |
| 5052 | Sophie Bakker | `NaN` | `NaN` |
| 7844 | Thomas Mulder | `NaN` | `NaN` |

Het nummer van Lars Visser is vervangen door `NaN` omdat het slechts 9 cijfers bevat na het verwijderen van niet-numerieke tekens. De andere inconsistente nummers zijn succesvol genormaliseerd naar het standaardformat.

---

### Stap 2 — Normalisatie van installatiedatums in `customers_heat_pumps.csv`

**Verwijzing:** [Data Kwaliteitsrapport §3.2.2](data_quality_report.md#322-customers_heat_pumpscsv--installatiedatum)

**Rationale:**

Eén installatiedatum is opgeslagen in het format `DD-MM-YYYY` (bijv. `29-09-2021`) in plaats van het standaard ISO-format `YYYY-MM-DD`. Pandas' `pd.to_datetime()` ondersteunt meerdere formats, maar bij het aanroepen zonder expliciete formatparameter kan het de datum verkeerd interpreteren. Daarom wordt een expliciete parse-strategie gehanteerd: eerst het ISO-format, dan het dag-eerst-format als fallback. Datums die met geen van beide formats geparseerd kunnen worden, worden vervangen door `NaT` (Not a Time — het equivalent van `NaN` voor datums).

**Implementatie:**

```python
import pandas as pd

customers_hp = pd.read_csv("data/voorbeeld_cleaning/customers_heat_pumps.csv")


def parse_installation_date(date_str: str) -> pd.Timestamp | None:
    """Probeer een datumstring te parsen in ISO-format (YYYY-MM-DD) of in
    het alternatieve format DD-MM-YYYY. Geeft NaT terug als parsen mislukt."""
    if pd.isna(date_str):
        return pd.NaT
    # Probeer eerst het standaard ISO-format
    try:
        return pd.to_datetime(date_str, format="%Y-%m-%d")
    except ValueError:
        pass
    # Probeer als fallback het dag-eerst-format (zoals gebruikt in Nederland)
    try:
        return pd.to_datetime(date_str, format="%d-%m-%Y")
    except ValueError:
        return pd.NaT


customers_hp["installation_date"] = customers_hp["installation_date"].apply(
    parse_installation_date
)

# Sla de datums op als ISO-string voor consistente opslag
customers_hp["installation_date"] = customers_hp["installation_date"].dt.strftime(
    "%Y-%m-%d"
)

print(customers_hp[["customer_id", "heat_pump_id", "installation_date"]])
```

**Resultaat:**

| customer_id | heat_pump_id | installation_date (voor) | installation_date (na) |
|---|---|---|---|
| 2152 | HP-5919 | `29-09-2021` | `2021-09-29` |

Alle overige datums waren al in het ISO-format en zijn ongewijzigd gebleven. De inconsistente datum is correct omgezet naar `2021-09-29`.

---

### Stap 3 — Correctie van temperatuurwaarden in Fahrenheit (`heat_pump_data.csv`)

**Verwijzing:** [Data Kwaliteitsrapport §3.3.1](data_quality_report.md#331-heat_pump_datacsv--temperatuur-in-fahrenheit)

**Rationale:**

De sensor van warmtepomp HP-1394 registreert temperaturen in Fahrenheit in plaats van Celsius. Dit is herkenbaar doordat de temperatuurwaarden van deze pomp systematisch buiten het verwachte Celsius-bereik voor warmtepompen liggen (35–55 °C). Waarden in Fahrenheit voor datzelfde bereik liggen tussen 95 °F en 131 °F.

**Identificatie:**

De identificatie van de betreffende warmtepomp gebeurt door te controleren welke pompen systematisch temperatuurwaarden boven 60 °C rapporteren. Een incidentele uitschieter boven 60 °C zou kunnen voorkomen door een tijdelijke anomalie, maar wanneer álle waarden van één pomp boven dit punt liggen, is een unit-fout de meest waarschijnlijke oorzaak.

```python
import pandas as pd

hp_data = pd.read_csv("data/voorbeeld_cleaning/heat_pump_data.csv")

# Bepaal voor elke warmtepomp het percentage van temperatuurmetingen boven 60 °C
temp_above_60 = (
    hp_data.groupby("heat_pump_id")["temperature"]
    .apply(lambda x: (x > 60).mean())
    .rename("fraction_above_60")
)
print(temp_above_60)

# Pompen waarbij vrijwel alle waarden boven 60 °C liggen, zijn waarschijnlijk
# in Fahrenheit opgeslagen
fahrenheit_pumps = temp_above_60[temp_above_60 > 0.95].index.tolist()
print("Mogelijk Fahrenheit-pompen:", fahrenheit_pumps)
```

**Implementatie:**

```python
# Converteer Fahrenheit naar Celsius met de standaardformule: °C = (°F - 32) × 5/9
def fahrenheit_to_celsius(temp_f: float) -> float:
    return (temp_f - 32) * 5.0 / 9.0


# Pas de correctie alleen toe op de geïdentificeerde Fahrenheit-pompen
mask = hp_data["heat_pump_id"].isin(fahrenheit_pumps)
hp_data.loc[mask, "temperature"] = hp_data.loc[mask, "temperature"].apply(
    fahrenheit_to_celsius
).round(1)

print(hp_data[hp_data["heat_pump_id"].isin(fahrenheit_pumps)]["temperature"].describe())
```

**Resultaat:**

| | Voor (Fahrenheit) | Na (Celsius) |
|---|---|---|
| Gemiddelde | 113.9 °F | 45.5 °C |
| Min | 95.0 °F | 35.0 °C |
| Max | 131.0 °F | 55.0 °C |

Na de conversie liggen de temperatuurwaarden van HP-1394 in het verwachte bereik van 35–55 °C, consistent met de overige warmtepompen.

---

### Stap 4 — Verwijdering van epoch timestamps (`heat_pump_data.csv`)

**Verwijzing:** [Data Kwaliteitsrapport §3.3.2](data_quality_report.md#332-heat_pump_datacsv--epoch-timestamps-1970-01-01)

**Rationale:**

Warmtepomp HP-7095 heeft 30 metingen met timestamps die op 1 januari 1970 liggen — de *Unix epoch*, het beginpunt van de Unix-tijdrekening (01-01-1970 00:00:00 UTC). Dit is een bekende artefact die optreedt wanneer een sensor of data-acquisitiesysteem opnieuw wordt opgestart of geïnitialiseerd zonder dat de systeemklok correct is ingesteld. De tijdstempel "0" in Unix-tijd (gelijk aan de Unix epoch) wordt dan als standaardwaarde gebruikt.

Deze metingen zijn vrijwel zeker foutief: de warmtepomp was op dat moment niet eens geïnstalleerd (installatiedatum: 25-06-2025), en de meetwaarden zijn niet betrouwbaar te koppelen aan een werkelijk tijdstip. Ze dienen dan ook te worden verwijderd.

```python
import pandas as pd

hp_data["timestamp"] = pd.to_datetime(hp_data["timestamp"])

# Identificeer epoch-rijen: timestamp valt in het jaar 1970
epoch_mask = hp_data["timestamp"].dt.year == 1970
print(f"Aantal epoch-rijen te verwijderen: {epoch_mask.sum()}")

# Verwijder de epoch-rijen
hp_data_cleaned = hp_data[~epoch_mask].copy()
print(f"Rijen na verwijdering: {len(hp_data_cleaned)}  (was: {len(hp_data)})")
```

**Resultaat:**

- 30 rijen met epoch-timestamps zijn verwijderd.
- Het totale aantal rijen daalde van 2.304 naar 2.274.
- HP-7095 heeft na de cleaning nog 258 geldige metingen over.

---

### Stap 5 — Imputation van missing values in meetkolommen (`heat_pump_data.csv`)

**Verwijzing:** [Data Kwaliteitsrapport §3.1.4](data_quality_report.md#314-heat_pump_datacsv--missing-values-in-meetkolommen)

**Rationale:**

In de kolommen `temperature`, `pressure` en `flow_rate` ontbreekt circa 10% van de waarden. Omdat het gaat om tijdreeksdata — metingen op vaste intervallen van 5 minuten — is *linear interpolation* op basis van de vorige en volgende waarde een geschikte imputatiemethode. Deze aanpak gaat er vanuit dat de werkelijke waarde tussen twee naburige metingen in ligt, wat voor continue fysieke grootheden als temperatuur, druk en debiet een realistische aanname is.

**Aanpak:**

De data wordt per warmtepomp gesorteerd op timestamp, waarna de interpolatie wordt uitgevoerd. Hiervoor wordt de pandas-methode `interpolate(method="linear")` gebruikt. Deze methode vult missing values in door lineaire interpolatie tussen de vorige en volgende geldige waarde.

Voor missing values aan het begin of einde van de tijdreeks — waar geen naburige waarde aan één kant beschikbaar is — werkt lineaire interpolatie standaard niet. In dat geval wordt de dichtstbijzijnde beschikbare waarde herhaald: `fillna(method="ffill")` voor het einde (forward fill) en `fillna(method="bfill")` voor het begin (backward fill). Op die manier blijft de tijdreeks compleet zonder dat aannames worden gemaakt over trends buiten het gemeten bereik.

```python
import pandas as pd

MEASUREMENT_COLS = ["temperature", "pressure", "flow_rate"]

# Sorteer per warmtepomp op timestamp om de volgorde te garanderen
hp_data_cleaned = hp_data_cleaned.sort_values(
    ["heat_pump_id", "timestamp"]
).copy()

# Pas interpolation toe per warmtepomp (groupby), zodat de reeks van één pomp
# niet "overloopt" naar de reeks van een andere pomp
hp_data_cleaned[MEASUREMENT_COLS] = (
    hp_data_cleaned
    .groupby("heat_pump_id")[MEASUREMENT_COLS]
    .transform(
        lambda group: group
        .interpolate(method="linear")   # vul tussenliggende NaN's in
        .ffill()                        # vul ontbrekende waarden aan het einde
        .bfill()                        # vul ontbrekende waarden aan het begin
    )
)

# Controleer of er nog missing values over zijn
print(hp_data_cleaned[MEASUREMENT_COLS].isnull().sum())
```

**Resultaat:**

```
temperature    0
pressure       0
flow_rate      0
```

Alle missing values zijn succesvol ingevuld. De interpolatiemethode is toegepast per warmtepomp om te voorkomen dat de tijdreeks van de ene pomp wordt gebruikt om die van een andere pomp te vullen.

---

## 3. Uitdagingen en Oplossingen (Challenges and Solutions)

### Uitdaging 1 — Identificatie van de Fahrenheit-pomp

**Uitdaging:** Er is geen metadata beschikbaar die aangeeft in welke eenheid de sensor van een warmtepomp meet. De enige manier om Fahrenheit-waarden te detecteren is door ze te vergelijken met het verwachte Celsius-bereik.

**Oplossing:** Door te controleren welke pompen consistent temperatuurwaarden boven 60 °C rapporteren (een waarde die in normale werking nauwelijks bereikt wordt), kan de Fahrenheit-pomp worden geïdentificeerd. Een drempelwaarde van 95% (bijna alle metingen van de pomp liggen boven 60 °C) wordt gehanteerd om te onderscheiden van pompen met incidentele uitschieters. In productiesystemen zou de eenheid als metadata bij de sensor moeten worden opgeslagen.

---

### Uitdaging 2 — Parsen van gemengde datumformats

**Uitdaging:** `customers_heat_pumps.csv` bevat installatiedatums in zowel `YYYY-MM-DD` als `DD-MM-YYYY` formaat. Pandas' standaard `pd.to_datetime()` probeert de format automatisch te detecteren, maar kan hierbij fouten maken — zo kan `05-06-2022` worden geïnterpreteerd als 5 juni (DD-MM) of als 6 mei (MM-DD), afhankelijk van de instellingen.

**Oplossing:** Een expliciete parse-functie is geïmplementeerd die beide formats sequentieel probeert. Hiermee wordt het risico op stille fouten door automatische detectie vermeden. Datums die met geen van beide formats parseerbaar zijn, worden expliciet als `NaT` gemarkeerd in plaats van stil te worden overgeslagen.

---

### Uitdaging 3 — Herkenning van de typo in het heat pump ID

**Uitdaging:** De typo in het heat pump ID (`HP-8734` in plaats van `HP-7834`) is subtiel en wordt niet gedetecteerd door simpele checks op aanwezigheid van het ID in de referentielijst.

**Oplossing:** Door een vergelijking te maken tussen de ID's in `heat_pump_data.csv` en de verwachte ID's uit `customers_heat_pumps.csv`, kunnen zowel ontbrekende als onverwachte ID's worden geïdentificeerd. Wanneer een onverwacht ID lijkt op een verwacht ID (bijv. door het uitvoeren van *edit distance* of *fuzzy matching*), kan worden geconcludeerd dat er sprake is van een typo. In dit geval was handmatige inspectie voldoende om de fout te bevestigen.

---

### Uitdaging 4 — Epoch timestamps als artefact, niet als echte meting

**Uitdaging:** De epoch timestamps (1970-01-01) zijn geldig als datetime-waarden — ze geven geen parse-fout. Ze zijn echter inhoudelijk onjuist en moeten worden herkend als sensorartefacten.

**Oplossing:** Door een redenering op basis van domeinkennis (een warmtepomp geïnstalleerd in 2025 kan onmogelijk metingen hebben uit 1970) worden deze rijen geïdentificeerd en verwijderd. In een robuuster systeem zou een validatieregel kunnen worden ingebouwd die timestamps afwijst die vóór de installatiedatum van de warmtepomp liggen.

---

## 4. Kwaliteit van de Gecleande Data (Quality of Cleaned Data)

Na het uitvoeren van de cleaning stappen zijn de volgende verbeteringen bereikt:

| Probleem | Voor cleaning | Na cleaning |
|---|---|---|
| Missing values in `email` (customers) | 2 (20%) | 2 (20%) — niet aanpasbaar zonder bronsysteem |
| Missing values in `phone` (customers) | 2 (20%) | 3 (30%) — Lars Visser toegevoegd als NaN |
| Inconsistente telefoonnummers | 3 | 0 (2 genormaliseerd, 1 → NaN) |
| Inconsistente installatiedatum | 1 | 0 (omgezet naar ISO-format) |
| Fahrenheit temperatuurwaarden | 288 rijen (1 pomp) | 0 (gecorrigeerd naar Celsius) |
| Epoch timestamps | 30 rijen | 0 (verwijderd) |
| Missing values in meetkolommen | ~10% per kolom | 0% (geïmputeerd via interpolation) |

De gecleande data is geschikt voor:
- Tijdreeksanalyse van temperatuur, druk en debiet per warmtepomp
- Vergelijking van prestaties tussen warmtepompen
- Koppeling van meetdata aan klantgegevens via heat pump ID en customer ID

---

## 5. Resterende Problemen (Remaining Issues)

### Restprobleem 1 — Ontbrekende e-mailadressen en telefoonnummers

**Probleem:** De e-mailadressen van Marie de Vries (4337) en Femke Bos (8555), en het telefoonnummer van Lars Visser (5616) konden niet worden aangevuld omdat de gegevens simpelweg ontbreken in het bronbestand.

**Aanbeveling:** Raadpleeg het originele CRM-systeem of contacteer de klanten direct om de ontbrekende contactgegevens aan te vullen. Als de gegevens structureel ontbreken, kan een imputation op basis van andere klanten worden overwogen, maar dit is niet aanbevolen voor contactgegevens (het risico op het benaderen van de verkeerde persoon is te groot).

---

### Restprobleem 2 — Klant zonder warmtepomp (Miriam Jansen)

**Probleem:** Klant Miriam Jansen (customer_id: 5502) heeft geen koppeling met een warmtepomp in `customers_heat_pumps.csv`.

**Aanbeveling:** Verifieer in het bronsysteem of deze klant daadwerkelijk geen warmtepomp heeft (bijv. potentiële klant of klant zonder product) of dat de koppeling per abuis ontbreekt. Pas `customers_heat_pumps.csv` aan als de koppeling hersteld kan worden. Als de klant daadwerkelijk geen warmtepomp heeft, is dit geen datafout maar een legitieme toestand, en kan een aparte categorie worden aangemaakt.

---

### Restprobleem 3 — Warmtepomp zonder meetdata (HP-2750)

**Probleem:** Warmtepomp HP-2750 (gekoppeld aan klant Sophie Bakker, customer_id: 5052) heeft geen meetdata in `heat_pump_data.csv`.

**Aanbeveling:** Controleer of de datasensorverbinding voor HP-2750 correct functioneert. Als de sensor defect is of niet communiceert met het data-acquisitiesysteem, dient dit technisch te worden opgelost. Tot die tijd is HP-2750 niet mee te nemen in prestatie- of trendanalyses.

---

### Restprobleem 4 — Typo in heat pump ID niet gecorrigeerd in brondata

**Probleem:** De typo in het heat pump ID (`HP-8734` in plaats van `HP-7834`) is in dit rapport geïdentificeerd, maar de correctie in het bronbestand (`heat_pump_data.csv`) vereist verificatie met het bronsysteem voordat ze definitief kan worden doorgevoerd.

**Aanbeveling:** Bevestig via het bronsysteem (bijv. het installatiesysteem of de sensor-metadata) dat `HP-8734` en `HP-7834` inderdaad hetzelfde apparaat betreffen. Voer de correctie uit in `heat_pump_data.csv` en zorg voor een *audit trail* zodat de wijziging aantoonbaar en herleidbaar is. Implementeer daarnaast een validatieregel bij de inname van nieuwe data die controleert of alle heat pump ID's in de meetdata voorkomen in de referentielijst.
