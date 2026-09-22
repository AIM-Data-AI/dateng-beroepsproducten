# Data Quality Report — Dashboard Heupoperaties

**Datum:** 2026-06-11  
**Auteur:** Data Analyst  
**Scope:** EPD-databasetabellen (EPD) en vragenlijstgegevens (beroepsproduct 2/data/questionnaires/*.resp)

---

## 1. Inleiding

Dit rapport beoordeelt de kwaliteit van de gegevens die worden gebruikt voor het dashboard Heupoperaties. Het dashboard bedient orthopedisch chirurgen, anesthesiologen en kwaliteitsmedewerkers en rapporteert over zeven KPI's op het gebied van reïnterventies, verpleegdagen en patiëntwelbevinden. De beoordeling is uitgevoerd langs zes standaard kwaliteitsdimensies; bevindingen zijn ingedeeld naar ernst: **critical**, **medium** of **low**.

---

## 2. Databronnen

| Bron | Records | Omschrijving |
|---|---|---|
| tabel `patient` | 3.581 | Patiëntbasisgegevens |
| tabel `eoc` | 3.581 | Opname-episodes (2016–2025) |
| tabel `eoc_treatment` | 4.081 | Behandelingen per opname (3.581 primaire heupvervangingen + 500 reïnterventies) |
| tabel `eoc_treatment_anesthesia` | 4.081 | Anesthesierecords |
| tabel `hip_treatment_position` | 3.581 | Operatieposities |
| tabel `patient_statistic` | 10.743 | BMI, rookstatus en ASA-klasse per patiënt |
| `questionnaires/*.resp` | 2.865 bestanden | Patiëntwelbevinden na interventie |

---

## 3. Kwaliteitsbevindingen per dimensie

### 3.1 Completeness

> *Zijn alle vereiste gegevensvelden aanwezig en gevuld?*

| # | Bevinding | Ernst | Betrokken tabel/bestand |
|---|---|---|---|
| C1 | **20% van de patiënten heeft geen vragenlijst.** 716 van de 3.581 patiënten (20,0%) hebben geen `.resp`-bestand. Coverage per jaar loopt van 75,7% (2021) tot 83,9% (2016). | **critical** | `questionnaires/` |
| C2 | **25,4% van de EOCs heeft uitsluitend niet-standaard anesthesierecords.** 911 van de 3.581 opname-episodes bevatten géén record met type `general anesthesia` of `spinal anesthesia` — uitsluitend `epidural anesthesia` (671 records), `nerve block` (434) of `unknown` (27). Voor deze episodes is het anesthesietype voor KPI3 niet te bepalen. | **critical** | tabel `eoc_treatment_anesthesia` |
| C3 | **175 operatieposities geregistreerd als 'unknown'.** 4,9% van de records in `hip_treatment_position` heeft `position_type = 'unknown'`. Dit beïnvloedt geen huidige KPI direct, maar beperkt uitbreidbaarheid van het dashboard. | **low** | tabel `hip_treatment_position` |

### 3.2 Accuracy

> *Representeren de waarden de werkelijkheid correct?*

| # | Bevinding | Ernst | Betrokken tabel/bestand |
|---|---|---|---|
| A1 | **63 opnames met een verblijfsduur van meer dan 30 dagen.** 1,8% van de EOCs heeft een LOS (length of stay) boven de 30 dagen (maximum: 55 dagen). Dit zijn medisch niet onmogelijke waarden, maar ook plausibele data-invoerfouten; ze hebben disproportioneel effect op LOS-gemiddelden in KPI6. | **medium** | tabel `eoc` |
| A2 | **116 vragenlijsten met een gezondheidsindex op baseline hoger dan na 3 maanden.** Bij 4,1% van de responders is de EQ-5D gezondheidsindex vóór de ingreep hoger dan na 3 maanden. Dit kan medisch correct zijn (tijdelijk verminderd herstel), maar ook duiden op verwisseling van meetmomenten bij data-invoer. | **low** | `questionnaires/` |

### 3.3 Consistency

> *Zijn de waarden consistent over verschillende bronnen en in de tijd?*

| # | Bevinding | Ernst | Betrokken tabel/bestand |
|---|---|---|---|
| CO1 | **133 EOCs hebben zowel een `general anesthesia`- als een `spinal anesthesia`-record.** Het dashboard-filter voor KPI3 vereist een eenduidige classificatie per episode. Als een episode beide typen bevat is niet te bepalen welk type het primaire anesthesietype was. | **critical** | tabel `eoc_treatment_anesthesia` |
| CO2 | **ASA-klasse opgeslagen als vrije tekst in plaats van de standaardnotatie I–IV.** De vier waarden ('healthy', 'mild to moderate systemic abnormality…', 'Severe functionally limiting systemic abnormality', 'systemic abnormality that poses a constant life-threatening danger') komen overeen met ASA I–IV, maar zijn niet uniform gecodeerd. Het dashboard vereist de notatie klasse I t/m IV (zie FR5). Een expliciete mapping is ontbrekend; de beschrijving van ASA III begint als enige met een hoofdletter ('Severe…' vs. 'mild to moderate…' en 'healthy'), wat de tekst-gebaseerde sortering verstoort. | **medium** | tabel `patient_statistic` |
| CO3 | **CHECK-constraint in DDL verwijst naar niet-bestaande kolomnaam.** De CHECK-constraint in de `patient_statistic`-tabel refereert aan `stvalue_boolean`, maar de kolomnaam in zowel DDL als data is `stvalue_bool`. Dit maakt de constraint effectief niet-functioneel en biedt geen integriteitsbescherming tegen meervulling van waardevelden. | **medium** | `ddl_epd_bp2.sql` |

### 3.4 Timeliness

> *Zijn de gegevens actueel en beschikbaar wanneer ze nodig zijn?*

| # | Bevinding | Ernst | Betrokken tabel/bestand |
|---|---|---|---|
| T1 | **Sterke daling van het aantal opnames in 2020–2021.** In 2020 zijn slechts 78 EOCs geregistreerd en in 2021 slechts 115, tegenover 355–512 in andere jaren. Dit is waarschijnlijk een gevolg van COVID-19 maar veroorzaakt zichtbare discontinuïteit in alle KPI-grafieken met een jaardimensie (KPI1–KPI7). Gebruikers moeten worden gewaarschuwd dat vergelijkingen met 2020–2021 niet representatief zijn. | **medium** | tabel `eoc` |
| T2 | **Vragenlijstcoverage is licht variabel per jaar (75,7%–83,9%).** De variatie over jaren is beperkt, maar de lagere coverage in 2021 valt samen met de reeds lage operatievolumes dat jaar, wat de betrouwbaarheid van KPI7-waarden voor dat jaar verder verkleint. | **low** | `questionnaires/` |

### 3.5 Validity

> *Voldoen de waarden aan de verwachte formaten en bereiken?*

| # | Bevinding | Ernst | Betrokken tabel/bestand |
|---|---|---|---|
| V1 | **Anesthesietypen buiten het geldige domein voor KPI3.** KPI3 definieert twee valide waarden: `general anesthesia` en `spinal anesthesia`. De data bevat drie aanvullende waarden: `epidural anesthesia` (671 records, 16,4%), `nerve block` (434 records, 10,6%) en `unknown` (27 records, 0,7%). Er bestaat geen businessregel die bepaalt hoe deze waarden gemappt moeten worden. | **critical** | tabel `eoc_treatment_anesthesia` |
| V2 | **BMI opgeslagen als geheel getal (precisie verlies).** Het `patient_statistic_type`-veld geeft `sttype = 'int'` voor BMI. In de data worden waarden als gehele getallen opgeslagen (bijv. 27, niet 27,4). Voor BMI-grensgevallen (bijv. werkelijk BMI 24,9 vs. 25,0) kan de afronding leiden tot verkeerde BMI-klasse-indeling in KPI5 en KPI6. | **low** | tabel `patient_statistic` |
| V3 | **500 anesthesietijdstips liggen meer dan 1 uur ná het tijdstip van de primaire behandeling.** Dit is deels te verklaren doordat anesthesie-records bij reïnterventies zijn geregistreerd, maar de relatie tussen `eoc_treatment_anesthesia` en de specifieke behandeling ontbreekt in het datamodel (geen directe koppeling via `tid`). | **low** | tabel `eoc_treatment_anesthesia` |

### 3.6 Uniqueness

> *Zijn er duplicaten in de data?*

| # | Bevinding | Ernst | Betrokken tabel/bestand |
|---|---|---|---|
| U1 | **Geen duplicaten aangetroffen.** Alle primaire sleutels (pid, eocid, combinatie eocid+tid, pid+stid) zijn uniek. Er zijn geen dubbele patientenrecords of dubbele vragenlijstbestanden gevonden. | — | alle tabellen |

---

## 4. Impact op KPI-requirements

| KPI | Betrokken bevindingen | Impact |
|---|---|---|
| **KPI1** Percentage primaire heupoperaties met reïnterventie | T1 | Jaaroverzicht vertoont anomalie in 2020–2021; trendinterpretatie vereist voorbehoud. |
| **KPI2** Verdeling reïnterventies naar type | T1 | Zelfde COVID-impact op jaarverdeling. |
| **KPI3** Verdeling reïnterventies per anesthesietype | C2, CO1, V1 | **Zwaarst getroffen KPI.** 25,4% van de EOCs kan niet worden geclassificeerd (geen general/spinal). 133 EOCs zijn ambigu (beide typen). Zonder expliciete bedrijfsregel is KPI3 onbetrouwbaar voor ten minste ~29% van de populatie. |
| **KPI4** Verdeling reïnterventies per ASA-klasse | CO2 | ASA-waarden vereisen een mapping van vrije tekst naar klasse I–IV alvorens het dashboard-filter (FR5) correct werkt. |
| **KPI5** Verdeling reïnterventies per BMI-klasse | V2 | Grensgevallen kunnen in verkeerde BMI-klasse vallen door afronding. Effect is klein maar niet nul. |
| **KPI6** Verpleegdagen | A1, T1 | LOS-outliers (>30 dagen) beïnvloeden gemiddelden; 2020–2021 anomalie geldt ook hier. |
| **KPI7** Patiëntwelbevinden na 3 en 12 maanden | C1, T2 | 20% ontbrekende vragenlijsten betekent dat KPI7 enkel op ~80% van de populatie is gebaseerd. De vraag is of de non-responders systematisch verschillen van responders (bijv. hogere complicatierate). |

---

## 5. Aanbevelingen

| Prioriteit | Aanbeveling |
|---|---|
| **1 (critical)** | Stel een bedrijfsregel vast voor de classificatie van `epidural anesthesia`, `nerve block` en `unknown` voor KPI3. Opties: (a) mappen naar het dichtstbijzijnde valide type, (b) groeperen in categorie 'overig', of (c) uitsluiten met melding in dashboard. Registreer de keuze als metadata. |
| **2 (critical)** | Definieer een prioriteringsregel voor EOCs met zowel `general anesthesia` als `spinal anesthesia`. Overweeg het tijdstip van de primaire behandeling als anker: het anesthesietype met timestamp het dichtst vóór de behandeling is het primaire type. |
| **3 (critical)** | Herstel het questionnaire-responsproces voor de 716 patiënten zonder `.resp`-bestand. Onderzoek of non-respons samenhangt met complicaties of overlijden om selectiebias in KPI7 te kwantificeren. |
| **4 (medium)** | Pas de ASA-opslag aan naar de standaardnotatie (I, II, III, IV). Voer de mapping eenmalig uit op de bestaande data en pas het invoerproces aan. |
| **5 (medium)** | Herstel de CHECK-constraint in `ddl_epd_bp2.sql`: vervang `stvalue_boolean` door `stvalue_bool`. |
| **6 (medium)** | Voeg een contextmarkering toe aan de jaren 2020 en 2021 in het dashboard om de COVID-gerelateerde volumedaling te communiceren aan gebruikers en te voorkomen dat foutieve conclusies worden getrokken uit trendgrafieken. |
| **7 (low)** | Overweeg BMI als `float` (met één decimaal) op te slaan in `stvalue_float` om grensgevallen correct in te delen in BMI-klassen. |
| **8 (low)** | Voeg een directe koppeling tussen `eoc_treatment_anesthesia` en `eoc_treatment` toe (via `tid`), zodat anesthesie-records eenduidig aan een specifieke behandeling binnen een EOC zijn te koppelen. |
