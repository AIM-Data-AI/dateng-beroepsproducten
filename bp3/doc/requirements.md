# Requirements beroepsproduct beroepsproduct 3: Gecombineerd Dashboard + Wachttijden vergelijken

Dit document beschrijft de requirements voor het beroepsproduct van beroepsproduct 3,
de laatste van drie opdrachten. beroepsproduct 3 bouwt voort op beroepsproduct 1 (dashboard
IC-data) en beroepsproduct 2 (dashboard heupoperaties).

We voegen de EPD-data (patiëntgegevens) van beroepsproduct 1 en beroepsproduct 2 samen en
vullen deze aan met nieuwe data: ongeveer 1000 patiënten per jaar, voor de
jaren 2016 tot en met 2025. Deze patiënten krijgen veel verschillende
behandelingen, niet alleen heupoperaties. Al deze data vormt samen één data
warehouse voor het ziekenhuis.

Daarnaast voegen we wachttijddata toe van de Nederlandse Zorgautoriteit
(NZa), zodat managers de wachttijd van hun eigen ziekenhuis kunnen
vergelijken met de wachttijd van ziekenhuizen in de regio.

De requirements in dit document vervangen de requirements van beroepsproduct 1 en
beroepsproduct 2 niet, maar vullen ze aan. Alle KPI's, user stories en functionele
requirements uit beroepsproduct 1 en beroepsproduct 2 blijven gelden en werken nu op het
gecombineerde data warehouse.

## Doelgroep

Bestaande doelgroepen (ongewijzigd, zie beroepsproduct 1 en beroepsproduct 2):

- Verpleegkundigen van de afdeling Intensive Care (beroepsproduct 1).
- Orthopedisch chirurgen en artsen van de afdeling Orthopedie (beroepsproduct 2).
- Anesthesiologen (beroepsproduct 2).
- Kwaliteitsmedewerkers en managers van de afdeling Orthopedie (beroepsproduct 2).

Nieuwe doelgroep in beroepsproduct 3:

- **Managers en bestuurders van het ziekenhuis**, breder dan alleen de
  afdeling Orthopedie. Zij gebruiken de wachttijd-vergelijking om te
  beoordelen hoe hun afdelingen presteren ten opzichte van ziekenhuizen in
  de regio.

## KPI's / Gebruiksdoel

De KPI's uit beroepsproduct 1 (overzicht van IC-patiënten) en beroepsproduct 2 (KPI1 t/m
KPI7: reïnterventies, risicofactoren, verpleegdagen en patiëntwelbevinden
bij heupoperaties) blijven ongewijzigd gelden, maar werken nu op een
grotere dataset met data van 2016 tot en met 2025. Hierdoor krijgt het
jaarfilter uit beroepsproduct 2 (FR1) meer waarde: er zijn nu genoeg jaren om
trends te onderscheiden van toevallige schommelingen.

Nieuwe KPI's voor beroepsproduct 3:

- **KPI8**: De wachttijd (in dagen) van het eigen ziekenhuis per
  behandeling, vergeleken met de wachttijd van ziekenhuizen in de regio —
  inzicht in hoe het eigen ziekenhuis presteert per behandeling en per
  specialisme.
- **KPI9**: De ontwikkeling van de wachttijd van het eigen ziekenhuis per
  behandeling over tijd — inzicht in trends die je met één meting niet
  ziet.
- **KPI10**: Het aantal en percentage behandelingen uit het EPD dat
  gekoppeld kan worden aan een NZa-wachttijd — inzicht in hoe compleet en
  betrouwbaar de vergelijking is, en voor welke behandelingen geen
  vergelijking mogelijk is.

## User Stories

### Verpleegkundigen IC en orthopedisch chirurgen/anesthesiologen/kwaliteitsmedewerkers

De user stories US1–US2 (beroepsproduct 1) en US01–US11 (beroepsproduct 2) blijven
ongewijzigd gelden. Zie de requirements van beroepsproduct 1 en beroepsproduct 2.

### Managers en bestuurders van het ziekenhuis

**US12** — *Als manager van het ziekenhuis wil ik de wachttijd van mijn
ziekenhuis per behandeling kunnen vergelijken met de wachttijd van
ziekenhuizen in de regio, zodat ik kan beoordelen of mijn ziekenhuis goed
presteert en waar bijsturing nodig is.*
→ [KPI8]

**US13** — *Als manager wil ik de wachttijd van mijn ziekenhuis per
behandeling kunnen volgen over tijd, zodat ik trends tijdig signaleer en
kan ingrijpen voordat de wachttijd te veel afwijkt van die in de regio.*
→ [KPI9]

**US14** — *Als manager wil ik weten welk deel van de behandelingen uit het
EPD ik kan koppelen aan een wachttijd uit de NZa-data, zodat ik weet hoe
compleet en betrouwbaar de vergelijking is en geen verkeerde conclusie trek
over een behandeling die niet gekoppeld is.*
→ [KPI10]

## Functionele Requirements

De functionele requirements FR1 t/m FR3 (beroepsproduct 1) en FR1 t/m FR10
(beroepsproduct 2) blijven ongewijzigd gelden en werken nu op het gecombineerde
data warehouse. Let daarbij op de volgende grenzen:

- De IC-grafieken (beroepsproduct 1, FR1–FR3) hebben alleen betekenis voor
  patiënten met machinedata, dus de patiënten uit beroepsproduct 1 (hun
  patiënt-id's zijn verhoogd met 10.000, zodat ze niet botsen met de id's
  uit beroepsproduct 2). De nieuwe patiënten (2016–2025) en de patiënten uit
  beroepsproduct 2 hebben geen machinedata.
- De heupoperatie-grafieken (beroepsproduct 2, FR2–FR10) hebben alleen betekenis
  voor episodes of care met een behandeling uit de heupvervanging-groep
  (heupvervanging, arthrotomie, revisie partieel, revisie totaal,
  repositie). De nieuwe data introduceert veel andere behandelingen; deze
  vallen buiten de heupoperatie-KPI's, maar tellen wel mee bij de
  wachttijd-vergelijking hieronder.
- De vragenlijstgegevens (patiëntwelbevinden, beroepsproduct 2 FR10) zijn alleen
  beschikbaar voor patiënten uit beroepsproduct 2.

---

### Sectie 5: Wachttijden vergelijken met andere ziekenhuizen

**FR11** [US12 | KPI8]:
Voor elke behandeling die zowel in het EPD als in de NZa-data voorkomt (via
de mapping in het bestand `treatments.csv`), toont het dashboard een staafdiagram met
de actuele wachttijd (in dagen) van het eigen ziekenhuis, naast de
wachttijden van de vergelijkingsziekenhuizen in de regio.

- De X-as toont de behandelingen (of het specialisme); de Y-as toont de
  wachttijd in dagen.
- Voor behandelingen waarvoor de NZa aangeeft dat er onvoldoende data is
  (`insufficient_observations = 'Ja'`), is geen wachttijd bekend. Dit wordt
  duidelijk gemarkeerd en niet als 0 dagen weergegeven.
- Het diagram is filterbaar op specialisme, op type zorg (behandeling,
  polikliniekbezoek of diagnostiek) en op vergelijkingsziekenhuis.

**FR12** [US13 | KPI9]:
Per behandeling toont het dashboard een lijndiagram met de ontwikkeling van
de wachttijd van het eigen ziekenhuis over tijd, gebaseerd op eerdere
metingen: periodiek opgehaalde momentopnames van de wachttijd-API,
aangevuld met het historische bestand van de NZa voor de periode vóór de
eerste momentopname.

- De X-as toont de tijd (per meting of per maand); de Y-as toont de
  wachttijd in dagen.
- Het diagram is filterbaar op behandeling of specialisme.
- Gaten in de brondata (bijvoorbeeld ontbrekende metingen) worden zichtbaar
  gemaakt in plaats van automatisch opgevuld.

**FR13** [US14 | KPI10]:
Het dashboard toont hoeveel behandelingen uit het EPD een koppeling hebben
naar een NZa-behandeling en dus meetellen bij de wachttijd-vergelijking,
zowel als getal en percentage als in de vorm van een lijst met
niet-gekoppelde behandelingen.

- De lijst van niet-gekoppelde behandelingen is filterbaar op periode, zodat
  zichtbaar wordt welk deel van de behandelingen buiten de vergelijking
  valt.

## Non-functionele Requirements

**NFR1 — Uitbreidbaarheid**: Het samenvoegen van EPD-data uit meerdere
bronnen (beroepsproduct 1, beroepsproduct 2, nieuwe jaren) mag de bestaande dashboards van
beroepsproduct 1 en beroepsproduct 2 niet veranderen. Een nieuwe bron — bijvoorbeeld een
volgend jaar met extra data, of een extra ziekenhuis om in de vergelijking mee te nemen — moet toegevoegd kunnen worden zonder het hele data
warehouse opnieuw te ontwerpen.

**NFR2 — Determinisme en reproduceerbaarheid**: Het opnieuw verwerken van
dezelfde brondata (EPD, vragenlijsten, NZa) levert dezelfde inhoud in het
data warehouse op. Dit geldt niet voor de live NZa-API zelf, die geen
historie kent en bij elke aanroep alleen het huidige moment teruggeeft, maar
wel voor de verwerking van een momentopname die al is opgehaald.

**NFR3 — Transparantie en herkomst (lineage)**: Van elke rij in het data
warehouse — ook de nieuwe wachttijdgegevens — moet herleidbaar zijn waar hij
vandaan komt, met een brondatum (`load_date`) en een bronvermelding
(`record_source`/snapshot-datum). Zo is later altijd na te gaan op welk
moment en uit welke bron een cijfer komt, inclusief het onderscheid tussen
de live momentopname en het historische bulkbestand.

**NFR4 — Robuustheid tegen externe diensten**: De pipeline moet robuust zijn
tegen externe diensten die tijdelijk niet bereikbaar zijn of onverwachte
data teruggeven. Als de NZa-API tijdelijk niet bereikbaar is, mag dit de
rest van het data warehouse niet blokkeren.

**NFR5 — Privacy en toegang**: Patiëntgegevens (naam, geboortedatum,
klinische gegevens) blijven, net als in beroepsproduct 1 en beroepsproduct 2, alleen
toegankelijk voor gebruikers met de juiste rol.

## Databronnen

### EPD (beroepsproduct 3, gecombineerd)

Dezelfde tabellen als beroepsproduct 2, aangevuld met `patient_observation` uit
beroepsproduct 1 (zie `beroepsproduct 3/scripts/ddl_epd_bp3.sql` voor de volledige
structuur): `patient`, `eoc`, `eoc_treatment`, `treatment_type`,
`eoc_treatment_anesthesia`, `hip_treatment_position`, `patient_statistic`,
`patient_statistic_type`, `patient_observation`.

Nieuw is de herkomst van de data: deze tabellen worden gevuld vanuit drie
bronnen, samengevoegd tot één EPD-bron:

- patiëntdata uit beroepsproduct 2 (patiënt-id's blijven ongewijzigd),
- patiëntdata uit beroepsproduct 1 (patiënt-id's zijn verhoogd met 10.000, zodat ze
  niet botsen met de id's uit beroepsproduct 2),
- ongeveer 1000 extra patiënten per jaar, voor de periode 2016–2025 (met
  duidelijk minder patiënten in 2020–2021 en duidelijk meer in 2022), met
  patiënt-id's vanaf 20.000. Deze patiënten krijgen veel verschillende
  behandelingen, niet alleen heupoperaties.

### IC-machinedata

Ongewijzigd ten opzichte van beroepsproduct 1 (zie `beroepsproduct 1/doc/requirements.md`
voor de kolommen van `patient_machine_mapping.csv` en
`machine_data/machine_[MID].csv`). Alleen beschikbaar voor de patiënten uit
beroepsproduct 1 (patiënt-id's verhoogd met 10.000).

### Vragenlijsten

Ongewijzigd ten opzichte van beroepsproduct 2 (zie `beroepsproduct 2/doc/requirements.md`
voor de velden per antwoordbestand `<pid>.resp`). Alleen beschikbaar voor
patiënten uit beroepsproduct 2.

### NZa Wachttijden

- **API**: de NZa biedt een open API aan met de actuele wachttijden per
  ziekenhuis. Voor een opgegeven KvK-nummer geeft de API een lijst van
  wachttijden terug, met onder andere de volgende velden:
  - `Date` — moment waarop de wachttijd is opgevraagd,
  - `KVKNumber`, `CareProvider`, `CareProvider_AGBCode` — de zorgaanbieder,
  - `LocationKey`, `KVKLocationNumber`, `Location_AGBCode`, `Location`,
    `Street`, `StreetNumber`, `PostalCode`, `City` — de vestiging,
  - `TreatmentKey`, `TreatmentNumber`, `Treatment`, `TreatmentType`,
    `Specialism`, `Description` — de behandeling, het polikliniekbezoek of
    de diagnostiek,
  - `WaitingTime`, `InsufficientObservations` — de wachttijd in dagen, en of
    er voldoende waarnemingen zijn om deze te berekenen,
  - `AllCareproviders` — niet toegelicht in de officiële documentatie, maar
    wel aanwezig in de respons.

  De API zelf kent geen historie: elke aanroep geeft alleen de actuele
  situatie op dat moment terug.
- **`wachttijden_history.csv`**: bevat historische wachttijdcijfers voor
  dezelfde ziekenhuizen, opgehaald uit een landelijke NZa-export. De
  kolommen komen niet één-op-één overeen met de velden van de API.
- **`kvk_nummers.csv`**: de ziekenhuizen waarvan wachttijden worden
  opgehaald, met KvK-nummer, vestigingsnummer en naam. Het eigen ziekenhuis
  is het Radboudumc. De overige
  ziekenhuizen in het bestand (Sint Maartenskliniek, Canisius Wilhelmina-ziekenhuis, Rijnstate,
  Bernhoven, Maasziekenhuis Pantein, Slingeland Ziekenhuis, Streekziekenhuis
  Koningin Beatrix, Ziekenhuis Gelderse Vallei, Ziekenhuis Rivierenland)
  vormen de vergelijkingsgroep in de regio.

- **`treatments.csv`**: een bestand dat namen van behandelingen die in het EPD
  worden gebruikt, koppelt aan de namen die NZa hanteert voor diezelfde
  behandelingen. (`nza`). Zie ook KPI10/FR13.