# Opdracht beroepsproduct 3: Gecombineerd Dashboard + Wachttijden vergelijken

## Inleiding

Voor het vak Data Engineering werk je in een groep van 4 studenten aan een
opdracht over data engineering. Deze opdracht is de laatste van drie
casusopdrachten. Deze opdracht volgt de CRISP-DM-cyclus. Je hebt deze cyclus
al eerder geleerd. Je hebt ook al de eerste twee casusopdrachten uitgevoerd
(zie `beroepsproduct 1/doc/opdracht.md` en `beroepsproduct 2/doc/opdracht.md`).

Je bouwt een deel van een data pipeline. Deze pipeline levert data aan een
dashboard. Het dashboard toont informatie over alle behandelingen die zijn
uitgevoerd in een ziekenhuis, niet alleen heupoperaties zoals in beroepsproduct 2.
Daarnaast vergelijkt het dashboard de wachttijd van het eigen ziekenhuis met
de wachttijd van andere ziekenhuizen in de regio. Verpleegkundigen,
orthopedisch chirurgen, anesthesiologen en kwaliteitsmedewerkers gebruiken
het dashboard zoals in beroepsproduct 1 en beroepsproduct 2. Managers en bestuurders van het
ziekenhuis gebruiken het dashboard om de prestaties van hun ziekenhuis te
vergelijken met andere ziekenhuizen in de regio.

Deze opdracht bouwt voort op beroepsproduct 1 (dashboard IC-data) en beroepsproduct 2
(dashboard heupoperaties). De EPD-data van beide beroepsproducten is nu samengevoegd en aangevuld met nieuwe patiënten en behandelingen uit de
periode 2016-2025, en aangevuld met wachttijddata van de Nederlandse
Zorgautoriteit (NZa).

## Doel van de opdracht

Je maakt een aantal beroepsproducten. Een beroepsproduct is een concreet
document of stuk software dat je oplevert. Sommige beroepsproducten krijg
je van ons (voorgegeven). Andere beroepsproducten maak je zelf. Alle
beroepsproducten samen vormen een compleet beeld van de CRISP-DM-cyclus voor
deze casus.

## CRISP-DM en beroepsproducten

De fasen van CRISP-DM horen bij de volgende beroepsproducten:

| Fase CRISP-DM | Beroepsproduct | Voorgegeven? |
|---|---|---|
| Business Understanding | Requirements BI-rapportage | Ja |
| Data Understanding | Data Quality Report | Ja |
| Data Understanding | Data Exploration Report | Ja |
| Data Preparation | Data Cleaning Report | Nee |
| Data Preparation | Data Lineage Report | Nee |
| Data Preparation | Pipelines inc. tests | Nee |
| Data Preparation | Staging area | Nee |
| Modeling | Data Warehouse (uitbreiding van de data vault uit beroepsproduct 2) | Nee |
| Modeling | Koppeling data warehouse - dashboard | Ja |
| Evaluation | BI-rapportage | Ja |

De fase Deployment komt in dit vak niet aan bod.

## Wat is voorgegeven?

Alle voorgegeven beroepsproducten, documentatie en voorbeelduitwerkingen
staan in de map `beroepsproduct 3`. Gebruik deze materialen als basis en als
voorbeeld voor je eigen werk.

## Wat lever je zelf op?

Jouw groep levert de volgende beroepsproducten op:

1. **Data Cleaning Report**: een rapport waarin je beschrijft welke
   datakwaliteitsproblemen je hebt gevonden in de brondata, en hoe je deze
   hebt opgelost. Let hierbij ook op de kwaliteit van de NZa-wachttijddata,
   bijvoorbeeld behandelingen waarvoor onvoldoende waarnemingen zijn.
2. **Data Lineage Report**: een rapport waarin je de herkomst van de data
   beschrijft. Dit rapport laat zien waar data vandaan komt, welke stappen
   de data doorloopt in de pipeline, en waar de data terechtkomt. Let er hierbij op dat een deel van de NZa-data afkomstig is uit een JSON-API (een
   momentopname zonder historie) en een deel uit een historisch bulkbestand.
3. **Pipelines inc. tests**: de data pipeline die de brondata inleest,
   opschoont en wegschrijft naar de staging area en het data warehouse.
   Inclusief tests die aantonen dat de pipeline correct werkt, ook wanneer
   de NZa-API tijdelijk niet bereikbaar is.
4. **Staging area**: een staging area waarin de brondata wordt opgeslagen
   voordat deze wordt verwerkt tot het data warehouse.
5. **Data Warehouse**: een uitbreiding van de **data vault** uit beroepsproduct 2
   met nieuwe hubs, links en satellites voor de IC-data uit beroepsproduct 1 en de
   NZa-wachttijddata. Dit data vault vormt de basis voor het dashboard.

## Requirements

De requirements voor het dashboard staan in
`beroepsproduct 3/doc/requirements.md`. Lees dit document goed door voordat je
begint. Deze requirements vullen de requirements van beroepsproduct 1 en beroepsproduct 2
aan en vervangen ze niet: alle KPI's, user stories en functionele
requirements uit beroepsproduct 1 en beroepsproduct 2 blijven gelden. In
`beroepsproduct 3/doc/requirements.md` vind je onder andere:

- De nieuwe doelgroep van het dashboard: managers en bestuurders van het
  ziekenhuis.
- De nieuwe KPI's, user stories en functionele requirements voor de
  wachttijd-vergelijking.
- De databronnen die je gebruikt: het gecombineerde EPD (patiëntgegevens
  uit beroepsproduct 1, beroepsproduct 2 en nieuwe patiënten), de IC-machinedata, de
  vragenlijsten, en de NZa-wachttijddata (live JSON-API, historisch bestand en
  de bestanden `kvk_nummers.csv` en `treatments.csv`).

## Werkwijze

- Je werkt in een groep van 4 studenten.
- Gebruik de voorgegeven beroepsproducten en voorbeeldbestanden in de map
  `beroepsproduct 3` als voorbeeld en uitgangspunt voor je eigen werk.
- Zorg dat je eigen beroepsproducten passen bij de requirements in
  `beroepsproduct 3/doc/requirements.md`.
- Koppel de wachttijddata aan het EPD via `treatments.csv`. Niet elke
  behandeling uit het EPD heeft een koppeling naar de NZa-data; dit is
  onderdeel van de opdracht (zie KPI10/FR13).
