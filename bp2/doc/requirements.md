# Requirements beroepsproduct beroepsproduct 2: Dashboard Heupoperaties

Dit document bevat de requirements voor het beroepsproduct voor beroepsproduct 2, het dashboard met informatie over heupoperaties.

## Doelgroep

- Orthopedisch chirurgen en artsen van de afdeling Orthopedie.
- Anesthesiologen.
- Kwaliteitsmedewerkers en managers van de afdeling Orthopedie.

## KPI's / Gebruiksdoel

Het dashboard moet inzicht geven in de volgende KPI's:

- **KPI1**: Percentage primaire heupoperaties dat heeft geleid tot een reïnterventie. Dit geeft inzicht in het aantal en het percentage operaties met een reïnterventie.
- **KPI2**: Verdeling van reïnterventies naar type: het aandeel van elk heroperatietype (arthrotomie, revisie partieel, revisie totaal, repositie). Dit laat zien welke typen reïnterventies het meest voorkomen.
- **KPI3**: Verdeling van reïnterventies per type anesthesie: algehele narcose of spinale anesthesie (ruggenprik). Dit laat de relatie zien tussen het type anesthesie en het optreden van reïnterventies.
- **KPI4**: Verdeling van reïnterventies per ASA-klasse. Dit laat de relatie zien tussen het risicoprofiel van de patiënt vóór de operatie (de ASA-score) en het optreden van reïnterventies.
- **KPI5**: Verdeling van reïnterventies per BMI-klasse. Dit laat de relatie zien tussen de verhouding van lengte en gewicht van de patiënt en het optreden van reïnterventies.
- **KPI6**: Aantal en verdeling verpleegdagen, per jaar, per ASA-klasse en per BMI-klasse. De verpleegdagen worden ingedeeld in twee groepen: een ligduur van 5 dagen of korter, en een ligduur van meer dan 5 dagen. Dit laat zien welke factoren kunnen leiden tot een langere opname.
- **KPI7**: Ontwikkeling van het patiëntwelbevinden na de operatie, per jaar. Dit wordt gemeten met vier meetwaarden: dagelijks functioneren, tevredenheid over het resultaat, verandering in pijn en gezondheidsindex. Deze waarden worden gemeten op 3 maanden en op 12 maanden na de operatie. Dit laat zien hoe effectief de behandeling wordt ervaren.

## User Stories

### Orthopedisch chirurgen en artsen

**US01** — *Als orthopedisch chirurg wil ik het percentage primaire heupoperaties dat heeft geleid tot een reïnterventie kunnen inzien, zodat ik de kwaliteit van mijn ingrepen kan bewaken en vergelijken.*
→ [KPI1]

**US02** — *Als orthopedisch chirurg wil ik de verdeling van reïnterventies per type kunnen bekijken (arthrotomie, revisie partieel, revisie totaal, repositie). Zo kan ik beoordelen welke heroperatietypen het meest voorkomen en hierop bijsturen.*
→ [KPI2]

**US03** — *Als orthopedisch chirurg wil ik de relatie zien tussen de ASA-klasse van een patiënt en het optreden van reïnterventies. Zo kan ik bij de beslissing over een operatie beter rekening houden met het risicoprofiel van de patiënt vóór de ingreep.*
→ [KPI4]

**US04** — *Als orthopedisch chirurg wil ik inzicht hebben in de verdeling van reïnterventies per BMI-klasse. Zo kan ik bij patiënten met een verhoogd BMI een goede afweging maken van de risico's.*
→ [KPI5]

**US05** — *Als orthopedisch chirurg wil ik de patiëntwelbevinden-scores kunnen inzien: dagelijks functioneren, tevredenheid over het resultaat, verandering in pijn en gezondheidsindex. Ik wil deze scores zien op 3 en op 12 maanden na de operatie, per jaar. Zo kan ik de uitkomsten van operaties evalueren en mijn behandelbeleid hierop aanpassen.*
→ [KPI7]

**US06** — *Als orthopedisch chirurg wil ik het aantal verpleegdagen kunnen inzien, uitgesplitst per ASA-klasse en BMI-klasse. De verpleegdagen worden ingedeeld in twee groepen: 5 dagen of korter, en meer dan 5 dagen. Zo kan ik het herstel van mijn patiënten na de operatie beoordelen en risicofactoren voor een langere opname herkennen.*
→ [KPI6]

### Anesthesiologen

**US07** — *Als anesthesioloog wil ik de verdeling van reïnterventies per type anesthesie kunnen inzien: algehele narcose of spinale anesthesie. Zo kan ik beoordelen wat de invloed is van de gekozen anesthesie op de kans op een reïnterventie.*
→ [KPI3]

**US08** — *Als anesthesioloog wil ik de verdeling van reïnterventies per ASA-klasse kunnen bekijken. Zo kan ik de risico's van patiënten met een hoog risicoprofiel beter inschatten en meenemen in mijn planning van de anesthesie.*
→ [KPI4]

### Kwaliteitsmedewerkers en managers

**US09** — *Als kwaliteitsmedewerker wil ik het totale percentage reïnterventies en de verdeling naar type reïnterventie kunnen volgen. Zo kan ik verbetertrajecten voor de kwaliteit starten en de voortgang hiervan regelmatig rapporteren.*
→ [KPI1], [KPI2]

**US10** — *Als manager van de afdeling Orthopedie wil ik het aantal en de verdeling van verpleegdagen kunnen inzien, uitgesplitst per jaar, ASA-klasse en BMI-klasse. Zo kan ik de bezetting van de afdeling plannen en op tijd zien of de kosten stijgen.*
→ [KPI6]

**US11** — *Als kwaliteitsmedewerker wil ik de ontwikkeling van het patiëntwelbevinden kunnen bekijken, op 3 en 12 maanden na de operatie en uitgesplitst per jaar. Zo kan ik beoordelen hoe effectief de behandelingen over tijd worden ervaren, en hierover rapporteren aan de afdeling en het management.*
→ [KPI7]

## Functionele Requirements

### Algemeen

**FR1** [US01–US11 | KPI1–KPI7]:
Het dashboard heeft een jaarfilter dat voor alle grafieken tegelijk geldt. Met dit filter kun je één jaar of meerdere jaren tegelijk selecteren. Zonder filter tonen alle grafieken de gegevens van alle beschikbare jaren.

---

### Sectie 1: Reïnterventies — overzicht en type-verdeling

**FR2** [US01, US09 | KPI1]:
Het dashboard toont een staafdiagram met, per jaar, het totale aantal primaire heupoperaties en het aantal reïnterventies. Het diagram toont ook het percentage reïnterventies: het aantal reïnterventies gedeeld door het aantal primaire operaties, keer 100%.
- De X-as toont de jaren. De Y-as toont het aantal operaties.
- Het percentage wordt als label boven elke reïnterventiebalk weergegeven.
- Het diagram is filterbaar op jaar via het globale jaarfilter.

**FR3** [US01, US02, US09 | KPI1, KPI2]:
Het dashboard toont voor elk reïnterventietype (arthrotomie, revisie partieel, revisie totaal, repositie) een eigen staafdiagram. De vier diagrammen staan verticaal onder elkaar, zodat de ontwikkeling per type makkelijk te vergelijken is.
- Per diagram toont de X-as de jaren. De Y-as toont het aantal reïnterventies van dat type.
- Elke balk toont als label het percentage ten opzichte van het totale aantal primaire operaties in dat jaar.
- De diagrammen zijn filterbaar op jaar (via het globale jaarfilter) en op reïnterventietype (via een lokaal filter).

---

### Sectie 2: Reïnterventies naar risicofactoren

**FR4** [US07 | KPI3]:
Het dashboard toont een gestapeld staafdiagram met de verdeling van reïnterventies over de twee anesthesietypen: algehele narcose en spinale anesthesie.
- De X-as toont de jaren. Elke balk bestaat uit twee delen: één per anesthesietype.
- Elk deel toont het aantal reïnterventies en het percentage ten opzichte van het totaal aantal reïnterventies in dat jaar.
- Het diagram is filterbaar op jaar via het globale jaarfilter.

**FR5** [US03, US08 | KPI4]:
Het dashboard toont een gegroepeerd staafdiagram met het aantal reïnterventies per ASA-klasse (klasse I tot en met IV). De balken staan per klasse naast elkaar.
- De X-as toont de ASA-klassen. Per klasse staat voor elk jaar een aparte balk, zodat de ontwikkeling per klasse over de jaren makkelijk te vergelijken is.
- Elke balk toont het aantal reïnterventies en het percentage ten opzichte van het totaal aantal reïnterventies in dat jaar.
- Het diagram is filterbaar op jaar (via het globale jaarfilter), op anesthesietype (lokaal filter) en op reïnterventietype (lokaal filter): arthrotomie, revisie partieel, revisie totaal of repositie.

**FR6** [US04 | KPI5]:
Het dashboard toont een gegroepeerd staafdiagram met het aantal reïnterventies per BMI-klasse. Er zijn vier klassen: ondergewicht (BMI lager dan 18,5), normaal gewicht (18,5–24,9), overgewicht (25–29,9) en obesitas (BMI 30 of hoger).
- De X-as toont de BMI-klassen. Per klasse staat voor elk jaar een aparte balk, zodat de ontwikkeling per klasse over de jaren makkelijk te vergelijken is.
- Elke balk toont het aantal reïnterventies en het percentage ten opzichte van het totaal aantal reïnterventies in dat jaar.
- Het diagram is filterbaar op jaar (via het globale jaarfilter) en op reïnterventietype (lokaal filter): arthrotomie, revisie partieel, revisie totaal of repositie.

---

### Sectie 3: Verpleegdagen

**FR7** [US06, US10 | KPI6]:
Het dashboard toont een gestapeld staafdiagram met de verdeling van verpleegdagen per jaar. Er zijn twee groepen: een ligduur van 5 dagen of korter, en een ligduur van meer dan 5 dagen.
- De X-as toont de jaren. Elke balk is opgesplitst in de twee ligduurgroepen.
- Elk deel van de balk toont het aantal patiënten en het percentage ten opzichte van het totaal in dat jaar.
- Het diagram is filterbaar op jaar (via het globale jaarfilter) en op ASA-klasse en BMI-klasse (lokale filters).

**FR8** [US06, US10 | KPI6]:
Het dashboard toont een gestapeld staafdiagram met de verdeling van verpleegdagen per ASA-klasse (klasse I tot en met IV), verdeeld in dezelfde twee ligduurgroepen als in FR7.
- De X-as toont de ASA-klassen. Elke balk is opgesplitst in de twee ligduurgroepen.
- Elk deel van de balk toont het aantal patiënten en het percentage ten opzichte van het totaal binnen die ASA-klasse.
- Het diagram is filterbaar op jaar (via het globale jaarfilter) en op BMI-klasse (lokaal filter).

**FR9** [US06, US10 | KPI6]:
Het dashboard toont een gestapeld staafdiagram met de verdeling van verpleegdagen per BMI-klasse (ondergewicht, normaal gewicht, overgewicht, obesitas — zie FR6 voor de grenzen), verdeeld in dezelfde twee ligduurgroepen als in FR7.
- De X-as toont de BMI-klassen. Elke balk is opgesplitst in de twee ligduurgroepen.
- Elk deel van de balk toont het aantal patiënten en het percentage ten opzichte van het totaal binnen die BMI-klasse.
- Het diagram is filterbaar op jaar (via het globale jaarfilter) en op ASA-klasse (lokaal filter).

---

### Sectie 4: Patiëntwelbevinden

**FR10** [US05, US11 | KPI7]:
Het dashboard toont voor elke meetwaarde van het patiëntwelbevinden een lijndiagram met de gemiddelde score per jaar. De meetwaarden zijn: dagelijks functioneren, tevredenheid over het resultaat, verandering in pijn en gezondheidsindex. De vier lijndiagrammen staan verticaal onder elkaar, zodat de ontwikkeling per meetwaarde makkelijk te vergelijken is.
- Elke grafiek bevat twee lijnen: één voor het meetmoment op 3 maanden na de operatie en één voor het meetmoment op 12 maanden na de operatie.
- De X-as toont de jaren. De Y-as toont de gemiddelde score op die meetwaarde.
- De grafieken zijn filterbaar op:
  - Jaar via het globale jaarfilter.
  - Meetmoment (3 maanden, 12 maanden, of beide) via een lokaal filter.
  - Reïnterventietype (arthrotomie, revisie partieel, revisie totaal, repositie) via een lokaal filter.
  - ASA-klasse (I tot en met IV) via een lokaal filter.
  - BMI-klasse (ondergewicht, normaal gewicht, overgewicht, obesitas) via een lokaal filter.
  - Ligduur (5 dagen of korter, of meer dan 5 dagen) via een lokaal filter.

## Databronnen

### EPD

- Tabel **patient**
  - `pid` — uniek patiënt-ID
  - `firstname` — voornaam
  - `lastname` — achternaam
  - `dob` — geboortedatum

- Tabel **eoc** (episode of care — opname-episode)
  - `eocid` — uniek opname-ID
  - `pid` — patiënt-ID (verwijzing naar patient)
  - `intake_date` — opnamedatum
  - `discharge_date` — ontslagdatum

- Tabel **eoc_treatment** (behandelingen binnen een opname)
  - `eocid` — opname-ID (verwijzing naar eoc)
  - `tid` — behandeltype-ID (verwijzing naar treatment_type)
  - `is_primary` — geeft aan of dit de primaire behandeling is (1 = ja, 0 = nee)
  - `eoc_time` — tijdstip van de behandeling

- Tabel **treatment_type** (opzoektabel behandeltypen)
  - `tid` — uniek behandeltype-ID
  - `tname` — naam van het behandeltype (hip replacement surgery, arthrotomy, revision (partial), revision (complete), reposition)

- Tabel **eoc_treatment_anesthesia** (anesthesie bij een behandeling)
  - `eocid` — opname-ID (verwijzing naar eoc)
  - `anesthesia_type` — type anesthesie (general anesthesia / spinal anesthesia)
  - `anesthesia_time` — tijdstip van toediening anesthesie

- Tabel **hip_treatment_position** (operatiepositie bij een heupoperatie)
  - `eocid` — opname-ID (verwijzing naar eoc)
  - `position_type` — gebruikte operatiepositie (bijv. anterolateral, direct lateral)
  - `position_time` — tijdstip waarop de positie is vastgelegd

- Tabel **patient_statistic** (patiëntkenmerken / statistieken)
  - `pid` — patiënt-ID (verwijzing naar patient)
  - `stid` — statistiektype-ID (verwijzing naar patient_statistic_type)
  - `stvalue_int` — waarde als geheel getal (bijv. BMI afgerond)
  - `stvalue_float` — waarde als kommagetal
  - `stvalue_bool` — waarde als booleaan (0/1)
  - `stvalue_string` — waarde als tekst (bijv. ASA-klasse)
  - `stat_ts` — tijdstip waarop de waarde is vastgelegd
  - `stat_note` — optionele toelichting

- Tabel **patient_statistic_type** (opzoektabel statistiektypen)
  - `stid` — uniek statistiektype-ID
  - `stname` — naam van het statistiektype (bmi, smoking, asa)
  - `sttype` — datatype van de waarde (int, float, bool, string)

### Vragenlijsten

De vragenlijsten bevatten de patiëntwelbevinden-scores na een interventie. Elk antwoordbestand (`<pid>.resp`) correspondeert met één patiënt (bestandsnaam = patiënt-ID). Elk bestand bevat de volgende velden:

- `Dagelijks functioneren na 3 maanden` — score voor dagelijks functioneren, gemeten 3 maanden na de interventie (geheel getal)
- `Dagelijks functioneren na 12 maanden` — score voor dagelijks functioneren, gemeten 12 maanden na de interventie (geheel getal)
- `Tevredenheid resultaat na 3 maanden` — tevredenheidsscore over het operatieresultaat na 3 maanden (geheel getal)
- `Tevredenheid resultaat na 12 maanden` — tevredenheidsscore over het operatieresultaat na 12 maanden (geheel getal)
- `Verandering in pijn na 3 maanden` — score voor verandering in pijn t.o.v. vóór de ingreep, gemeten na 3 maanden (geheel getal)
- `Verandering in pijn na 12 maanden` — score voor verandering in pijn t.o.v. vóór de ingreep, gemeten na 12 maanden (geheel getal)
- `Gezondheidsindex (baseline)` — EQ-5D gezondheidsindex vóór de interventie (kommagetal tussen 0 en 1)
- `Gezondheidsindex (na 3 maanden)` — EQ-5D gezondheidsindex 3 maanden na de interventie (kommagetal tussen 0 en 1)
- `Gezondheidsindex (na 12 maanden)` — EQ-5D gezondheidsindex 12 maanden na de interventie (kommagetal tussen 0 en 1)
