# Requirements beroepsproduct beroepsproduct 1: Dashboard IC-data

Dit document bevat de requirements voor het beroepsproduct voor beroepsproduct 1, het dashboard met IC-data.

## Doelgroep

- Verpleegkundigen van de afdeling Intensive Care.

## KPI's / Gebruiksdoel

- Inzicht verkrijgen in de toestand van de patiënten op de intensive care.
## User Stories

- **US1**: Als verpleegkundige wil ik een overzicht hebben van de patiënten die op dit moment op de intensive care liggen. Dit overzicht moet de ontwikkeling tonen van de vitale statistieken van elke patient.
- **US2**: Als verpleegkundige wil informatie kunnen opvragen over een individuele patiënt.

## Functionele Requirements

- **FR1** [US1]: Het dashboard moet grafieken tonen voor elke patiënt. Deze grafiek moet de volgende informatie bevatten:
  - Het bednummer
  - De naam van de patiënt
  - De hoofdbehandeling van elke patiënt
  - De ontwikkelingen van de afgelopen 30 minuten van de volgende meetwaarden:
    - Hartslag
    - Bloeddruk (bovendruk en onderdruk)
    - Vloeistoffen toegediend (ml)
    - Hoeveelheid bloed toegediend (ml)
    - Hoeveelheid bloed verloren (ml)
- **FR2** [US2]: Het dashboard moet de mogelijkheid bieden voor elke patiënt extra informatie weer te geven:
  - Geboortedatum
  - Bednummer
  - Machinenummer
  - Observaties
  - Pijnscores
- **FR3**: Het dashboard moet informatie tonen van de afgelopen 30 minuten.

## Databronnen

### EPD

- Tabel "patient"
  - pid (patientid)
  - firstname
  - lastname
  - dob (geboortedaum)
  - treatment (hoofdbehandeling)
- Tabel "patient_observation"
  - pid (patientid)
  - note_ts (timestamp observatie)
  - note_text (tekst observatie)
  - pain_score (pijnscore)

### Data machines IC

- Bestand patient_machine_mapping.csv
  - PID (patientid)
  - MID (machine-id)
  - BID (bed-id)
- Bestanden machine_data/machine_[MID].csv
  - TS (timestamp)
  - SBP (systolic blood pressure oftewel bovendruk)
  - DBP (dystolic blood pressure oftewel onderdruk)
  - HR (hartslag)
  - Fluids (ml vocht toegediend)
  - BloodLost (ml bloed verloren)
  - BloodGiven (ml bloed toegediend)
