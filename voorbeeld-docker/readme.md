# Docker Compose voorbeeld: MSSQL + Python

Deze map bevat een voorbeeld van het gebruik van Docker om een MSSQL-database uit te voeren en een container met Python-code die deze database aanroept. Dit voorbeeld start twee containers:

- `mssql`: SQL Server 2022 (Microsoft image), luistert op poort 1433.
- `python-app`: een Python-container die wacht tot de database beschikbaar is,
  een voorbeeldtabel `dbo.example_numbers` aanmaakt en vult met vijf getallen,
  en de inhoud daarvan terugleest via `pyodbc`.

## Gebruik

```bash
cd voorbeeld-docker
docker compose up --build
```

Verwachte output van `python-app`: de SQL Server versie-informatie, gevolgd door
de inhoud van `dbo.example_numbers`.

Stop en verwijder de containers (en het databasevolume) met:

```bash
docker compose down -v
```

## Tabel uitlezen met pandas (notebook)

`notebook_example.ipynb` maakt vanaf je host verbinding met dezelfde database
(via poort 1433 op `localhost`) en laadt `dbo.example_numbers` in een
pandas-DataFrame. Dit vereist, naast een draaiende `docker compose up`, een
lokale Python-omgeving met de juiste dependencies en ODBC-driver:

```bash
pip install -r requirements-notebook.txt
```

Op macOS installeer je de Microsoft ODBC-driver via Homebrew:

```bash
brew install unixodbc msodbcsql18
```

Open daarna `notebook_example.ipynb` in VS Code of Jupyter en voer de cellen uit.

## Apple Silicon (M1/M2/M3/M4) Macs

Het officiële `mssql/server`-image bestaat alleen voor `linux/amd64`; er is geen
native `arm64`-build. De `docker-compose.yml` bevat daarom `platform: linux/amd64`
op de `mssql`-service, zodat de container via emulatie draait op Apple Silicon.

Zorg dat Docker Desktop hiervoor Rosetta-emulatie gebruikt: **Settings → General →
"Use Rosetta for x86/amd64 emulation on Apple Silicon"** moet aan staan (in recente
versies is dit standaard ingeschakeld). Zonder Rosetta valt Docker terug op QEMU,
wat de opstarttijd van SQL Server sterk kan vertragen of zelfs kan laten vastlopen.

Op Intel-Macs en Linux/Windows-amd64-machines draait alles native en is er geen
prestatieverlies.

## Wachtwoord aanpassen

Het SA-wachtwoord staat standaard op `YourStrong!Passw0rd` en moet voldoen aan de
complexiteitseisen van SQL Server (minimaal 8 tekens, hoofdletters, kleine letters,
cijfers en/of symbolen). Overschrijf het via een `.env`-bestand of environment
variabele:

```bash
MSSQL_SA_PASSWORD='Iets_Sterkers123!' docker compose up --build
```

## Structuur

```
docker-mssql-python/
  docker-compose.yml       # definieert de mssql- en python-app-service
  Dockerfile                # image voor de python-app-service (incl. ODBC-driver)
  requirements.txt           # python-dependencies voor de container (pyodbc)
  requirements-notebook.txt  # python-dependencies voor de notebook op de host (pandas, pyodbc, jupyter)
  notebook_example.ipynb    # notebook die de tabel uitleest in een pandas-DataFrame
  app/
    connect_example.py      # voorbeeldscript dat verbinding maakt, een tabel vult en uitleest
```

Vervang `app/connect_example.py` door je eigen ETL-/pipeline-code om dit voorbeeld
als basis te gebruiken voor een van de beroepsproducten.
