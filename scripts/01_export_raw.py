"""
Eksport danych RAW z bazy PostgreSQL do plików CSV.
Folder docelowy: data/raw/
"""

import os
import pandas as pd
from dotenv import load_dotenv
from sqlalchemy import create_engine

# Wczytanie zmiennych środowiskowych (.env)
load_dotenv()

DB_HOST = os.getenv("DB_HOST")
DB_NAME = os.getenv("DB_NAME")
DB_USER = os.getenv("DB_USER")
DB_PASS = os.getenv("DB_PASS")

# Połączenie z bazą
engine = create_engine(f"postgresql+psycopg2://{DB_USER}:{DB_PASS}@{DB_HOST}/{DB_NAME}")

# Lista tabel do eksportu
tables = pd.read_sql(
    "SELECT table_name FROM information_schema.tables WHERE table_schema='public'",
    engine
)["table_name"].tolist()

print(f"Znaleziono {len(tables)} tabel: {tables}")

# Folder docelowy
out_dir = "data/raw"
os.makedirs(out_dir, exist_ok=True)

# Eksport każdej tabeli
for table in tables:
    print(f"=== Eksport tabeli: {table} ===")
    df = pd.read_sql(f'SELECT * FROM "{table}"', engine)
    file_path = os.path.join(out_dir, f"{table}.csv")
    df.to_csv(file_path, index=False, encoding="utf-8-sig")
    print(f"✔ Zapisano: {file_path} ({len(df)} wierszy)")

print("\nEksport RAW zakończony!")