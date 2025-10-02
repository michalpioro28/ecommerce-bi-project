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

# Pobranie listy tabel w schemacie clean
tables = pd.read_sql(
    """
    SELECT table_name 
    FROM information_schema.tables 
    WHERE table_schema = 'clean'
    """,
    engine
)["table_name"].tolist()

print("Znaleziono tabele CLEAN:", tables)

# Eksport każdej tabeli do CSV (analogicznie jak w raw)
output_dir = "data/clean"
os.makedirs(output_dir, exist_ok=True)

for table in tables:
    df = pd.read_sql(f'SELECT * FROM clean."{table}"', engine)
    df.to_csv(f"{output_dir}/{table}.csv", index=False)
    print(f"Wyeksportowano: {table}.csv")

print("Eksport CLEAN zakończony!")