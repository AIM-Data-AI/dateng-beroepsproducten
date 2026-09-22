# Opdracht beroepsproduct 1: Dashboard Intensive Care

## Inleiding

Voor het vak Data Engineering werk je in een groep van 4 studenten aan een
opdracht over data engineering. Deze opdracht is de eerste van drie
casusopdrachten. De opdrachten worden steeds complexer. Deze opdracht volgt
de CRISP-DM-cyclus. Je hebt deze cyclus al eerder geleerd.

Je bouwt een deel van een data pipeline. Deze pipeline levert data aan een
dashboard. Het dashboard toont de bezetting van de intensive care (IC) van
een ziekenhuis. Verpleegkundigen gebruiken dit dashboard om de toestand van
patiënten te volgen.

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
| Data Preparation | Pipelines inc. tests | Deels (gedeeltelijk voorgegeven, zonder koppeling naar het data warehouse) |
| Data Preparation | Staging area | Ja |
| Modeling | Data Warehouse (in de vorm van een sterschema) | Nee |
| Modeling | Koppeling data warehouse - dashboard | Ja |
| Evaluation | BI-rapportage | Ja |

De fase Deployment komt in dit vak niet aan bod.

## Wat is voorgegeven?

Alle voorgegeven beroepsproducten, documentatie en voorbeelduitwerkingen
staan in de map `beroepsproduct 1`. Gebruik deze materialen als basis en als
voorbeeld voor je eigen werk.

## Wat lever je zelf op?

Jouw groep levert de volgende beroepsproducten op:

1. **Data Cleaning Report**: een rapport waarin je beschrijft welke
   datakwaliteitsproblemen je hebt gevonden in de brondata, en hoe je deze
   hebt opgelost.
2. **Data Lineage Report**: een rapport waarin je de herkomst van de data
   beschrijft. Dit rapport laat zien waar data vandaan komt, welke stappen
   de data doorloopt in de pipeline, en waar de data terechtkomt.
3. **Data Warehouse**: een data warehouse in de vorm van een sterschema.
   Dit sterschema vormt de basis voor het dashboard.

Voor de Pipelines geldt: een deel van de pipeline is al gebouwd, maar zonder
koppeling naar het data warehouse. Jouw groep maakt deze koppeling af.

## Requirements

De requirements voor het dashboard staan in
`beroepsproduct 1/doc/requirements.md`. Lees dit document goed door voordat je
begint. Hierin vind je onder andere:

- De doelgroep van het dashboard.
- De user stories en functionele requirements.
- De databronnen die je gebruikt: het EPD (patiëntgegevens) en de data van
  de IC-machines.

## Werkwijze

- Je werkt in een groep van 4 studenten.
- Gebruik de voorgegeven beroepsproducten en voorbeeldbestanden in de map
  `beroepsproduct 1` als voorbeeld en uitgangspunt voor je eigen werk.
- Zorg dat je eigen beroepsproducten passen bij de requirements in
  `beroepsproduct 1/doc/requirements.md`.
