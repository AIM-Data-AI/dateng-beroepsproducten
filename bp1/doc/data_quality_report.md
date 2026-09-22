# Datakwaliteitsrapport – ICU Machine Data en EPD Data

**Datum:** 2026-05-27  
**Versie:** 1.0

---

## Inleiding

Dit rapport beoordeelt de kwaliteit van de data die wordt gebruikt voor het IC-dashboard. De data bestaat uit drie bronnen:

1. **EPD-data** – patiëntgegevens en klinische observaties in de tabellen `patient` en `patient_observation` (zie `scripts/ddl_epd_bp1.sql` en `scripts/dml_epd_bp1.sql`).
2. **Koppelingsbestand** – `data/patient_machine_mapping.csv`: koppeling tussen patiënten, IC-machines en bednummers.
3. **Machine data** – tijdreeksmetingen in `data/machine_data/machine_[MID].csv`: één bestand per machine met minuut-voor-minuut metingen van vitale functies en toegediende vloeistoffen/bloed.

De kwaliteit wordt beoordeeld langs zes dimensies: **Completeness**, **Accuracy**, **Consistency**, **Timeliness**, **Validity** en **Uniqueness**. Per bevinding wordt de ernst aangegeven als **kritiek**, **medium** of **laag**.

---

## Overzicht kwaliteitsproblemen

| ID  | Dimensie     | Ernst   | Samenvatting |
|-----|--------------|---------|--------------|
| Q1  | Completeness | Kritiek | 5 machinebestanden bevatten minder dan 30 observaties (M11, M12, M16, M17, M19) |
| Q2  | Consistency  | Kritiek | Inconsistent PID-formaat: integers in EPD vs. `P`-prefix strings in koppelingsbestand |
| Q3  | Consistency  | Medium  | Start-timestamp van `machine_M11.csv` (07:16:00) wijkt 1 minuut af van de `note_ts` van patiënt 19347 (07:15:00) |
| Q4  | Timeliness   | Medium  | Vijf machines bestrijken het vereiste 30-minutenvenster niet volledig |
| Q5  | Validity     | Medium  | De `TS`-kolom in de machine CSV-bestanden is opgeslagen als tekstveld (string), niet als datetime-type |
| Q6  | Completeness | Laag    | Eén ontbrekende waarde (null) voor het veld `HR` in `machine_M19.csv` |
| Q7  | Completeness | Laag    | Het veld `dob` in de tabel `patient` is `NULL`-baar; in de huidige dataset zijn alle waarden ingevuld |
| Q8  | Completeness | Laag    | Slechts één observatierecord per patiënt in `patient_observation` |
| Q9  | Uniqueness   | Laag    | Geen duplicaten aangetroffen in geen van de databronnen (positieve bevinding) |

---

## Bevindingen per dimensie

### 1. Completeness

Completeness beschrijft in welke mate alle vereiste data aanwezig en gevuld is.

#### Machine data (Q1 – Kritiek)

Vijf van de twintig machinebestanden bevatten minder dan de verwachte 30 observaties (één meting per minuut over een aaneengesloten venster van 30 minuten):

| Bestand          | Aanwezig | Verwacht | Ontbrekend | Ontbrekende timestamps |
|------------------|----------|----------|------------|------------------------|
| `machine_M11.csv` | 28       | 30       | 2          | 07:15:00, 07:41:00     |
| `machine_M12.csv` | 28       | 30       | 2          | 07:03:00, 07:23:00     |
| `machine_M16.csv` | 29       | 30       | 1          | 09:25:00               |
| `machine_M17.csv` | 29       | 30       | 1          | 07:38:00               |
| `machine_M19.csv` | 29       | 30       | 1          | 10:14:00               |

De overige 15 machinebestanden zijn volledig (30 rijen, aaneengesloten timestamps met intervallen van precies 1 minuut).

#### Machine data – missing values (Q6 – Laag)

`machine_M19.csv` bevat één ontbrekende waarde (null) voor het veld `HR` (hartslag). Dit is de enige missing value in de gehele machine dataset.

#### EPD-data (Q7 – Laag)

Het veld `dob` (geboortedatum) in de tabel `patient` is in het DDL gedefinieerd als `NULL`-baar. In de huidige dataset zijn alle geboortedata ingevuld. Dit vormt echter een potentieel completeness-risico bij toekomstige data-invoer.

#### EPD-data (Q8 – Laag)

Elke patiënt heeft precies één record in de tabel `patient_observation`. Hoewel dit voldoende is voor de huidige requirements, is het beperkt voor toekomstige uitbreidingen waarbij meerdere observaties per patiënt verwacht worden.

---

### 2. Accuracy

Accuracy beschrijft in hoeverre de datawaarden de werkelijkheid correct weergeven.

#### Machine data (Laag – geen kritieke bevindingen)

Alle meetwaarden liggen binnen medisch aannemelijke grenzen voor IC-patiënten:

| Veld       | Minimum | Maximum | Opmerking |
|------------|---------|---------|-----------|
| SBP        | 90.0    | 175.2   | Plausibel voor IC-patiënten |
| DBP        | 60.0    | 103.6   | Plausibel voor IC-patiënten |
| HR         | 50.0    | 138.5   | Plausibel voor IC-patiënten |
| Fluids     | 1.0     | 4.72    | ml/min, plausibel |
| BloodLost  | 0.0     | 4.98    | Nulwaarden verwacht bij geen actief bloedverlies |
| BloodGiven | 0.0     | 4.83    | Nulwaarden verwacht bij geen bloedtransfusie |

SBP is in alle 593 rijen groter dan DBP, conform de fysiologische verwachting. Er zijn geen negatieve waarden aangetroffen en er zijn geen evidente outliers die de nauwkeurigheid in twijfel trekken.

---

### 3. Consistency

Consistency beschrijft in hoeverre de data intern en tussen bronnen onderling consistent is.

#### PID-formaat inconsistentie (Q2 – Kritiek)

De `pid`-waarden in de EPD-tabellen (`patient`, `patient_observation`) zijn integers (bijv. `13847`). In het koppelingsbestand `patient_machine_mapping.csv` worden dezelfde ID's weergegeven als tekstveld met een `P`-prefix (bijv. `P13847`). Directe joins op basis van dit veld zijn daardoor niet mogelijk zonder datatransformatie. Dit heeft directe impact op **FR1** en **FR2**.

#### Start-timestamp machine_M11 vs. note_ts patiënt 19347 (Q3 – Medium)

De `note_ts` in `patient_observation` voor patiënt 19347 is `2026-05-11 07:15:00`. Volgens de DML-documentatie markeert `note_ts` het begin van het 30-minutenvenster voor IC-machinemonitoring. Het bijbehorende machinebestand `machine_M11.csv` begint echter pas op `2026-05-11 07:16:00`. De eerste minuut van het monitoringvenster (07:15:00) ontbreekt daardoor in de machine data. Deze bevinding hangt samen met Q1 (de ontbrekende timestamp voor M11).

#### TS-opslag als string (Q5/Q9 – Laag)

De timestamp-kolom (`TS`) in alle machine CSV-bestanden is opgeslagen als tekstveld (string). De waarden volgen consistent het formaat `YYYY-MM-DD HH:MM:SS`, maar er is geen formele typedefinitie op bestandsniveau. Dit is beschreven als afzonderlijk Validity-issue (Q5), maar heeft ook een consistency-aspect: bij inlezen zonder expliciete type-conversie kunnen sorteer- en tijdberekeningsbewerkingen incorrect verlopen.

---

### 4. Timeliness

Timeliness beschrijft in hoeverre de data actueel en tijdig beschikbaar is.

#### Onvolledig monitoringvenster (Q4 – Medium)

**FR3** vereist dat het dashboard informatie toont van de afgelopen 30 minuten. Voor vijf van de twintig machines (M11, M12, M16, M17, M19) is het monitoringvenster niet volledig gedekt vanwege ontbrekende timestamps (zie Q1). Voor machine M11 begint de monitoring bovendien pas bij 07:16:00 in plaats van 07:15:00 (zie Q3), waardoor het venster 1 minuut korter is dan vereist.

#### Actualiteit van de data (Laag – geen kritieke bevinding)

Alle data (EPD, machine data en koppelingsbestand) is gegenereerd op 2026-05-11 en vertegenwoordigt een coherente momentopname. De data is consistent in de tijd: alle timestamps liggen op 2026-05-11, met machine-tijdvensters die overeenkomen met de bijbehorende `note_ts`-waarden in de EPD (één uitzondering: M11, zie Q3).

---

### 5. Validity

Validity beschrijft in hoeverre de datawaarden voldoen aan verwachte formaten en domeingrenzen.

#### TS-kolom als string (Q5 – Medium)

De `TS`-kolom in alle machine CSV-bestanden is opgeslagen als tekstveld (string), niet als datetime-type. Hoewel de waarden consistent het formaat `YYYY-MM-DD HH:MM:SS` volgen, bestaat het risico op verwerkingsfouten indien de data zonder expliciete type-conversie wordt ingelezen. Sorteer- en tijdsberekeningsbewerkingen die vereist zijn voor **FR3** (tonen van de afgelopen 30 minuten) zijn foutgevoelig zonder dtype-validatie.

#### EPD – pain_score constraint (Laag – positieve bevinding)

Het DDL-schema voor `patient_observation` bevat een `CHECK`-constraint die `pain_score` beperkt tot het bereik 0–10. Alle waarden in de DML-data voldoen aan deze constraint (waarden variëren van 2 tot 9). Dit versterkt de validity van de EPD-data.

#### Numerieke velden als float64 (Laag)

Alle numerieke meetvelden in de machine CSV-bestanden zijn opgeslagen als float64. Dit is technisch acceptabel voor de gemeten waarden; de requirements stellen geen expliciete precisie-eisen aan de meetwaarden.

---

### 6. Uniqueness

Uniqueness beschrijft in hoeverre de data vrij is van duplicaten.

#### Geen duplicaten gevonden (Q9 – Laag, positieve bevinding)

- **Machine data**: Er zijn geen dubbele timestamps per machinebestand aangetroffen.
- **Koppelingsbestand**: Elke patiënt (PID) en elke machine (MID) komt precies één keer voor. Elk bed (BID) is eveneens uniek.
- **EPD-data**: Alle `pid`-waarden in de tabel `patient` zijn uniek; alle `poid`-waarden in de tabel `patient_observation` zijn uniek.

---

## Impact op requirements

| Quality Issue | Betrokken requirement | Impact |
|--------------|----------------------|--------|
| Q1 – Incomplete time series | FR3, FR1 | Hiaten in het monitoringvenster kunnen leiden tot ontbrekende datapunten in de grafieken voor 5 van de 20 patiënten. |
| Q2 – PID-formaat inconsistentie | FR1, FR2 | Koppeling van machine data aan EPD-gegevens (naam, geboortedatum, behandeling, bednummer) vereist expliciete datatransformatie. Zonder deze stap is het dashboard niet te vullen. |
| Q3 – M11 start-timestamp mismatch | FR3 | De eerste minuut van het 30-minutenvenster voor patiënt 19347 (machine M11) ontbreekt. |
| Q4 – Onvolledig monitoringvenster | FR3 | Voor 5 van de 20 patiënten is de eis van 30 minuten monitoringsdata niet volledig haalbaar. |
| Q5 – TS als string | FR1, FR3 | Sorteer- en filteroperaties op timestamp vereisen expliciete type-conversie; ontbrekende conversie kan leiden tot incorrecte volgorde of vergelijkingsfouten. |
| Q6 – Missing HR | FR1 | De hartslag van patiënt 14102 (machine M19) ontbreekt op één tijdstip; dit resulteert in een gat in de hartslaggrafiek. |
| Q7 – Nullable dob | FR2 | Geboortedatum kan in toekomstige datasets ontbreken; het dashboard moet hier rekening mee houden (bijv. fallback-weergave). |
| Q8 – Één observatie per patiënt | FR2 | Voldoende voor huidige requirements; geen directe blocker. |

---

## Aanbevelingen

1. **[Q1, Q4]** Voeg een detectie- en signaleringsmechanisme toe voor ontbrekende timestamps in de datapipeline. Overweeg voor het dashboard een visuele aanduiding (bijv. een onderbroken lijn of melding) bij ontbrekende meetpunten.
2. **[Q2]** Standaardiseer het PID-formaat: verwijder de `P`-prefix in `patient_machine_mapping.csv`, of voeg een expliciete transformatiestap toe in de datapipeline die de PID-waarden normaliseert vóór het joinen van de bronnen.
3. **[Q3]** Onderzoek waarom `machine_M11.csv` begint op 07:16:00 terwijl `note_ts` van patiënt 19347 07:15:00 is. Corrigeer ofwel de start-timestamp in het machinebestand, ofwel de `note_ts` in de EPD-data.
4. **[Q5]** Documenteer expliciet dat de `TS`-kolom bij inlezen geconverteerd dient te worden naar een datetime-type (bijv. `pd.to_datetime(df['TS'])`). Overweeg een validatiestap toe te voegen aan de data-inleespipeline.
5. **[Q6]** Voeg bij de dataverwerking een interpolatie- of imputatiestap toe voor de ontbrekende `HR`-waarde in `machine_M19.csv`, of toon een expliciete leemte in de grafiek voor dat tijdstip.
6. **[Q7]** Zorg dat het dashboard een fallback-weergave heeft voor patiënten met een ontbrekende geboortedatum (bijv. "onbekend").
