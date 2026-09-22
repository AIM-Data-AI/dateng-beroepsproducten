# Opdracht beroepsproduct 2: Dashboard Heupoperaties

## Inleiding

Voor het vak Data Engineering werk je in een groep van 4 studenten aan een
opdracht over data engineering. Deze opdracht is de tweede van drie
casusopdrachten. De opdrachten worden steeds complexer. Deze opdracht volgt
de CRISP-DM-cyclus. Je hebt deze cyclus al eerder geleerd. Je hebt ook al
de eerste casusopdracht uitgevoerd (zie `beroepsproduct 1/doc/opdracht.md`).

Je bouwt een deel van een data pipeline. Deze pipeline levert data aan een
dashboard. Het dashboard toont informatie over heupoperaties die zijn
uitgevoerd in een ziekenhuis. Orthopedisch chirurgen, anesthesiologen en
kwaliteitsmedewerkers gebruiken dit dashboard om de kwaliteit en de
uitkomsten van heupoperaties te volgen.

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
| Modeling | Data Warehouse (in de vorm van een data vault) | Nee |
| Modeling | Koppeling data warehouse - dashboard | Ja |
| Evaluation | BI-rapportage | Ja |

De fase Deployment komt in dit vak niet aan bod.

## Wat is voorgegeven?

Alle voorgegeven beroepsproducten, documentatie en voorbeelduitwerkingen
staan in de map `beroepsproduct 2`. Gebruik deze materialen als basis en als
voorbeeld voor je eigen werk.

## Wat lever je zelf op?

Jouw groep levert de volgende beroepsproducten op:

1. **Data Cleaning Report**: een rapport waarin je beschrijft welke
   datakwaliteitsproblemen je hebt gevonden in de brondata, en hoe je deze
   hebt opgelost.
2. **Data Lineage Report**: een rapport waarin je de herkomst van de data
   beschrijft. Dit rapport laat zien waar data vandaan komt, welke stappen
   de data doorloopt in de pipeline, en waar de data terechtkomt.
3. **Pipelines inc. tests**: de data pipeline die de brondata inleest,
   opschoont en wegschrijft naar de staging area en het data warehouse.
   Inclusief tests die aantonen dat de pipeline correct werkt.
4. **Staging area**: een staging area waarin de brondata wordt opgeslagen
   voordat deze wordt verwerkt tot het data warehouse.
5. **Data Warehouse**: een data warehouse in de vorm van een **data
   vault**. Dit data vault vormt de basis voor het dashboard.

Voor deze opdracht is de pipeline, in tegenstelling tot beroepsproduct 1, volledig
zelf te bouwen: er is geen voorgegeven basis voor de koppeling naar het
data warehouse.

## Requirements

De requirements voor het dashboard staan in
`beroepsproduct 2/doc/requirements.md`. Lees dit document goed door voordat je
begint. Hierin vind je onder andere:

- De doelgroep van het dashboard.
- De KPI's, user stories en functionele requirements.
- De databronnen die je gebruikt: het EPD (patiëntgegevens) en de
  vragenlijsten met patiëntwelbevinden-scores.

## Werkwijze

- Je werkt in een groep van 4 studenten.
- Gebruik de voorgegeven beroepsproducten en voorbeeldbestanden in de map
  `beroepsproduct 2` als voorbeeld en uitgangspunt voor je eigen werk.
- Zorg dat je eigen beroepsproducten passen bij de requirements in
  `beroepsproduct 2/doc/requirements.md`.
