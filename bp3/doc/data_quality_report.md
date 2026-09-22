# Datakwaliteitsrapport — beroepsproduct 3: Gecombineerd Dashboard + Wachttijden

## 1. Inleiding

Dit rapport beschrijft de kwaliteit van de data die wordt gebruikt voor het gecombineerde
dashboard van beroepsproduct 3: het samengevoegde EPD (IC-data, heupoperaties en nieuwe
patiënten 2016–2025), de IC-machinedata, de vragenlijsten over patiëntwelbevinden en de
NZa-wachttijdendata. De kwaliteit is beoordeeld op zes dimensies: Completeness, Accuracy,
Consistency, Timeliness, Validity en Uniqueness. Per bevinding staat de ernst
(**kritiek**, **gemiddeld** of **laag**) en het effect op de requirements uit
[requirements.md](requirements.md), aangevuld met de KPI's/FR's uit beroepsproduct 1 en beroepsproduct 2
die nog steeds gelden.

De volgende bronnen zijn onderzocht:

- EPD (gecombineerd): `patient`, `eoc`, `eoc_treatment`, `treatment_type`,
  `eoc_treatment_anesthesia`, `hip_treatment_position`, `patient_statistic`,
  `patient_statistic_type`, `patient_observation` (`beroepsproduct 3/data/*_combined.csv`,
  DDL in `ddl_epd_bp3.sql`).
- IC-machinedata: `patient_machine_mapping.csv` en `machine_data/machine_[MID].csv`.
- Vragenlijsten: `questionnaires/<pid>.resp`.
- NZa-wachttijden: `wachttijden_history.csv`, `wachttijden_latest.json`,
  `kvk_nummers.csv` en `treatments.csv`.

Omdat de data grotendeels synthetisch is gegenereerd, kan Accuracy niet worden getoetst
tegen een externe waarheid. Voor deze dimensie is daarom gekeken naar interne
plausibiliteit: kloppen de waarden onderling en logisch gezien met elkaar.

---

## 2. Completeness

Zijn alle verplichte velden aanwezig en gevuld?

**C1 — Vragenlijsten ontbreken voor 20% van de beroepsproduct 2-patiënten — Ernst: kritiek**
Van de 3.581 patiënten uit beroepsproduct 2 (heupoperaties) hebben 716 patiënten (20%) geen
`.resp`-bestand. Dit ontbreken is gelijk verdeeld over de jaren 2016–2025 en hangt dus niet
samen met een te korte follow-up periode. Dit raakt **KPI7/FR10** (patiëntwelbevinden):
gemiddelden per jaar worden op een kleinere en mogelijk niet-toevallige steekproef
berekend, wat de betrouwbaarheid van de trends aantast.

**C2 — Ontbrekende operatiepositie bij heupoperaties — Ernst: laag**
Van de 4.367 primaire heupoperaties ontbreekt bij 290 (6,6%) een `position_type`-record.
`hip_treatment_position` wordt niet direct in een KPI gebruikt, dus de impact op de
requirements is beperkt.

**C3 — `kvk_nummers.csv` bevat niet alle vestigingen — Ernst: gemiddeld**
De live wachttijden-API levert voor meerdere ziekenhuizen meer vestigingen dan er in
`kvk_nummers.csv` staan (bijvoorbeeld 9 vestigingen voor Sint Maartenskliniek in de
API-snapshot tegenover 1 vestiging in het bestand). Zolang gefilterd wordt op
KvK-nummer van de instelling werkt **FR11** nog correct, maar een filter op individuele
vestiging mist data.

**C4 — Vestiging ontbreekt in actuele momentopname — Ernst: laag**
CWZ Polikliniek Jonkerbosch (vestigingsnummer 22387455) staat wel in
`kvk_nummers.csv`, maar komt niet voor in `wachttijden_latest.json`. Voor deze vestiging
is op het moment van de snapshot geen actuele wachttijd beschikbaar (**KPI8/FR11**).

---

## 3. Accuracy

Komen de waarden overeen met de werkelijkheid die ze moeten weergeven?

Aangezien de data synthetisch is gegenereerd, is een echte accuracy-toets niet mogelijk.
De volgende interne controles zijn wel uitgevoerd en laten geen probleem zien:

- Geboortedatums liggen altijd vóór alle klinische timestamps van dezelfde patiënt
  (`patient_statistic.stat_ts`, `eoc.intake_date`, `patient_observation.note_ts`).
- `discharge_date` in `eoc` ligt nooit vóór `intake_date`.
- BMI-, ASA- en rookstatuswaarden vallen binnen plausibele klinische grenzen (BMI
  15–43).
- Elke primaire heupoperatie heeft een anesthesierecord, wat klinisch verwacht mag
  worden.

**A1 — Extreme wachttijdwaarde zonder referentie om te toetsen — Ernst: laag**
`wachttijden_history.csv` bevat een wachttijd van 900 dagen voor "Transgender zorg" bij
Radboudumc (meerdere metingen). Dit is een plausibele, bekende situatie in de
Nederlandse zorg, maar zonder externe referentie is dit niet te verifiëren. Aanbevolen
wordt een plausibiliteitscontrole (bijvoorbeeld een bovengrens met handmatige review) op
te nemen in de pipeline, gezien de grote invloed die uitschieters kunnen hebben op
**KPI8/KPI9**.

---

## 4. Consistency

Zijn de waarden onderling en tussen bronnen consistent?

**CO1 — Anesthesietype heeft meer categorieën dan de KPI verwacht — Ernst: kritiek**
`eoc_treatment_anesthesia` bevat vijf waarden voor `anesthesia_type`: `general
anesthesia`, `spinal anesthesia`, `epidural anesthesia`, `nerve block` en `unknown`.
**KPI3/FR4** verwacht precies twee categorieën (algehele narcose en spinale
anesthesie). Binnen de heupoperatie-scope valt 27% van de anesthesierecords
(epidural, nerve block, unknown) buiten deze twee categorieën. Zonder een duidelijke
regel over hoe deze records worden behandeld (uitsluiten, samenvoegen in "overig")
telt FR4 niet correct op tot 100%.

**CO2 — Extra positietype "unknown" en "anterior" — Ernst: gemiddeld**
`hip_treatment_position.position_type` bevat naast de drie in beroepsproduct 2 genoemde
posities ook `anterior` en `unknown` (5% van de records). Position wordt niet in een
KPI gebruikt, maar de inconsistentie kan verwarring geven zodra dit veld wel getoond
wordt.

**CO3 — `InsufficientObservations` is niet uniform tussen de twee NZa-bronnen — Ernst: gemiddeld**
In `wachttijden_history.csv` is dit een boolean (`TRUE`/`FALSE`), in
`wachttijden_latest.json` een tekstveld (`'Ja'`/`'Nee'`). Bij het samenvoegen van
historie en momentopnames voor **FR12** (ontwikkeling over tijd) moeten beide waarden
eerst naar dezelfde representatie worden omgezet, anders ontstaan foutieve
"onvoldoende data"-markeringen.

**CO4 — KvK- en vestigingsnummers zijn inconsistent geformatteerd tussen bronnen — Ernst: kritiek**
KvK- en vestigingsnummers worden in `kvk_nummers.csv` en `wachttijden_history.csv` als
tekst met voorloopnullen opgeslagen (bijvoorbeeld `09096140`,
`000080262783`), terwijl de live API een ander aantal cijfers gebruikt voor hetzelfde
vestigingsnummer (bijvoorbeeld `80262783` in plaats van `000080262783`). Als deze
velden bij het inlezen als getal in plaats van tekst worden behandeld, gaan
voorloopnullen verloren en sluiten de koppelsleutels niet meer op elkaar aan. Dit
raakt de koppeling die nodig is voor **FR11, FR12, FR13 en NFR3** (herleidbaarheid
naar bron).

**CO5 — Meerdere EPD-behandelingen wijzen naar dezelfde NZa-behandeling — Ernst: gemiddeld**
In `treatments.csv` mappen 5 NZa-behandelingen naar telkens twee verschillende
EPD-behandelingen (bijvoorbeeld "Primary percutaneous coronary intervention" én
"Coronary angioplasty" naar "Dotterbehandeling (cardiologie)"; drie EPD-behandelingen
naar "Gastroscopie"). Dit is op zich toegestaan, maar bij het tellen van "aantal
behandelingen gekoppeld aan een NZa-wachttijd" voor **KPI10/FR13** moet dit per
EPD-behandeling geteld worden, niet per unieke NZa-wachttijd, anders lijkt de
koppelgraad lager dan hij is.

**CO6 — EOC's met intake in 2026, buiten de gedocumenteerde periode 2016–2025 — Ernst: gemiddeld**
20 episodes of care (alle IC-patiënten, band beroepsproduct 1) hebben een `intake_date` in
2026, terwijl de requirements de dataset omschrijven als "2016 tot en met 2025". Het
jaarfilter uit **FR1 (beroepsproduct 2)** werkt op de hele gecombineerde dataset en krijgt
hierdoor een extra jaar te zien met uitsluitend niet-heupoperatie-behandelingen, wat
verwarrend kan zijn omdat de documentatie dit jaar niet noemt.

---

## 5. Timeliness

Zijn de gegevens actueel en op tijd beschikbaar?

**T1 — IC-machinedata is een vaste momentopname uit het verleden — Ernst: gemiddeld**
Alle bestanden in `machine_data/` en de bijbehorende `patient_observation`-records voor
IC-patiënten zijn gedateerd op 11 mei 2026. **FR3** vereist dat het dashboard "de
afgelopen 30 minuten" toont. Zolang deze data niet doorlopend ververst wordt, toont het
dashboard geen actuele situatie meer zodra de kalenderdatum verder vordert.

**T2 — Momentopnames van de wachttijden-API zijn niet gelijktijdig per ziekenhuis — Ernst: laag**
`wachttijden_latest.json` bevat voor elk ziekenhuis een eigen ophaalmoment, verspreid
over 17–25 augustus 2026. Voor lineage is dit geen probleem (elke rij heeft een eigen
`Date`), maar de "actuele" wachttijd in **KPI8/FR11** is daardoor per ziekenhuis
een ander moment, wat de onderlinge vergelijkbaarheid iets vermindert.

**T3 — Onregelmatige meetdichtheid in de historische wachttijden — Ernst: laag**
Het aantal metingen per maand in `wachttijden_history.csv` varieert sterk (van 1.045
tot 3.027 per maand over de periode augustus 2025–augustus 2026). Dit kan de
trendlijn in **FR12** ongelijkmatig maken.

---

## 6. Validity

Voldoen de waarden aan het verwachte formaat en de verwachte waardebereiken?

**V1 — ASA-klasse is een vrije tekstomschrijving in plaats van een klasse-aanduiding — Ernst: kritiek**
Het veld `asa` in `patient_statistic` bevat volledige Engelstalige omschrijvingen
("mild to moderate systemic abnormality that does not result in functional
impairment", "healthy", "Severe functionally limiting systemic abnormality",
"systemic abnormality that poses a constant life-threatening danger") in plaats van de
klasse-aanduiding I t/m IV die **KPI4, FR5 en FR8** gebruiken. Er is bovendien geen
uniforme hoofdlettergebruik (één omschrijving begint met een hoofdletter, de rest
niet). Zonder een mapping van omschrijving naar klasse I–IV kunnen deze grafieken niet
gebouwd worden.

**V2 — Enkele ontbrekende metingen in de machinedata — Ernst: laag**
5 van de 20 machinebestanden hebben één ontbrekende meting per minuut (interval van
120 in plaats van 60 seconden) en 1 bestand heeft één ontbrekende hartslagwaarde. Dit
raakt **FR1/FR3 (beroepsproduct 1)** in beperkte mate.

De vragenlijstwaarden zijn wel volledig valide: alle scores en de gezondheidsindex
(0–1) vallen binnen de verwachte bereiken, en alle 2.865 bestanden bevatten precies de
9 verwachte velden zonder parsefouten.

---

## 7. Uniqueness

Zijn er dubbele records of waarden?

Er zijn geen dubbele primaire sleutels gevonden: `pid`, `eocid`, `poid` en de
samengestelde sleutels van `patient_statistic`, `eoc_treatment`,
`eoc_treatment_anesthesia` en `hip_treatment_position` zijn stuk voor stuk uniek. In
de wachttijden-API-snapshot zijn geen volledig identieke rijen aangetroffen; ogenschijnlijke
duplicaten (zelfde behandeling, zelfde ziekenhuis) bleken bij nadere controle telkens
verschillende vestigingen van dezelfde zorgaanbieder te betreffen. Op dit vlak zijn
geen bevindingen om te rapporteren.

---

## 8. Samenvatting per ernst

| Ernst | Bevindingen |
|---|---|
| **Kritiek** | C1, CO1, CO4, V1 |
| **Gemiddeld** | C3, CO2, CO3, CO5, CO6, T1 |
| **Laag** | C2, C4, A1, T2, T3, V2 |

---

## 9. Aanbevelingen

1. **Vragenlijsten (C1)**: onderzoek waarom 20% van de beroepsproduct 2-patiënten geen
   `.resp`-bestand heeft en documenteer dit als bekende beperking bij KPI7, of vul de
   ontbrekende bestanden aan indien mogelijk.
2. **ASA-klasse (V1)**: bouw een mapping van de vrije-tekstomschrijving naar de
   klasse-aanduiding I–IV vóórdat KPI4/FR5/FR8 gebouwd worden.
3. **Anesthesietype (CO1)**: leg vast hoe `epidural anesthesia`, `nerve block` en
   `unknown` worden behandeld in FR4 (uitsluiten of samenvoegen tot "overig"), zodat de
   percentages kloppen.
4. **Sleutel-formattering (CO4)**: lees KvK- en vestigingsnummers overal expliciet als
   tekst in (niet als geheel getal), en leg een expliciete mapping vast tussen de
   vestigingsnummer-notatie van `kvk_nummers.csv` en die van de live API.
5. **`InsufficientObservations` harmoniseren (CO3)**: converteer beide bronnen naar
   dezelfde representatie (bijvoorbeeld een boolean) bij het samenvoegen voor FR12.
6. **Telling KPI10/FR13 (CO5)**: tel het aantal gekoppelde behandelingen op basis van
   EPD-behandelingen, niet op basis van unieke NZa-wachttijden.
7. **Jaarbereik (CO6)**: bepaal expliciet of 2026 wel of niet in het jaarfilter van FR1
   moet verschijnen, en werk de documentatie bij als 2026 bewust wordt meegenomen.
8. **`kvk_nummers.csv` aanvullen (C3/C4)**: vul de ontbrekende vestigingen aan zodat
    filteren op vestigingsniveau (FR11) volledig werkt.
