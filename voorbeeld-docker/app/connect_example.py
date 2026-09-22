"""Example script: connect from Python to the MSSQL container and run a query.

Waits for SQL Server to accept connections, then creates an example table,
loads a handful of numbers into it (if not already present), and reads them
back. This gives the `notebook_example.ipynb` notebook something to query.
"""
import os
import time

import pyodbc

HOST = os.environ["MSSQL_HOST"]
PORT = os.environ["MSSQL_PORT"]
USER = os.environ["MSSQL_USER"]
PASSWORD = os.environ["MSSQL_SA_PASSWORD"]
DATABASE = os.environ["MSSQL_DATABASE"]

EXAMPLE_NUMBERS = [1, 2, 3, 5, 8]

CONN_STR = (
    "DRIVER={ODBC Driver 18 for SQL Server};"
    f"SERVER={HOST},{PORT};"
    f"DATABASE={DATABASE};"
    f"UID={USER};PWD={PASSWORD};"
    "TrustServerCertificate=yes;"
)


def wait_for_db(retries: int = 10, delay: int = 3) -> pyodbc.Connection:
    """Retry connecting until SQL Server is ready, or raise after `retries` attempts."""
    last_error = None
    for attempt in range(1, retries + 1):
        try:
            return pyodbc.connect(CONN_STR, timeout=5)
        except pyodbc.Error as exc:
            last_error = exc
            print(f"Attempt {attempt}/{retries}: database not ready yet ({exc})")
            time.sleep(delay)
    raise RuntimeError("Could not connect to MSSQL") from last_error


def load_example_data(conn: pyodbc.Connection) -> None:
    """Create the example table and populate it with a few numbers if empty."""
    cursor = conn.cursor()
    cursor.execute(
        """
        IF OBJECT_ID('dbo.example_numbers', 'U') IS NULL
        CREATE TABLE dbo.example_numbers (
            id INT IDENTITY(1,1) PRIMARY KEY,
            value INT NOT NULL
        );
        """
    )
    conn.commit()

    cursor.execute("SELECT COUNT(*) FROM dbo.example_numbers;")
    (row_count,) = cursor.fetchone()
    if row_count == 0:
        cursor.executemany(
            "INSERT INTO dbo.example_numbers (value) VALUES (?);",
            [(n,) for n in EXAMPLE_NUMBERS],
        )
        conn.commit()
    cursor.close()


def main() -> None:
    conn = wait_for_db()
    cursor = conn.cursor()
    cursor.execute("SELECT @@VERSION;")
    row = cursor.fetchone()
    print("Connected to SQL Server. Version info:")
    print(row[0])
    cursor.close()

    load_example_data(conn)

    cursor = conn.cursor()
    cursor.execute("SELECT id, value FROM dbo.example_numbers ORDER BY id;")
    print("Contents of dbo.example_numbers:")
    for row in cursor.fetchall():
        print(row)
    cursor.close()

    conn.close()


if __name__ == "__main__":
    main()
