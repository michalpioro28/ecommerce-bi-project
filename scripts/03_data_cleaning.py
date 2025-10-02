import os
import pandas as pd
from dotenv import load_dotenv
from sqlalchemy import create_engine, text

# Ładowanie zmiennych z .env
load_dotenv()
DB_HOST = os.getenv("DB_HOST")
DB_NAME = os.getenv("DB_NAME")
DB_USER = os.getenv("DB_USER")
DB_PASS = os.getenv("DB_PASS")

# Połączenie z bazą
engine = create_engine(f"postgresql+psycopg2://{DB_USER}:{DB_PASS}@{DB_HOST}/{DB_NAME}")

# Utworzenie schematu clean z automatycznym commitem
with engine.begin() as conn:
    conn.execute(text("CREATE SCHEMA IF NOT EXISTS clean;"))

# Lista tabel do czyszczenia
tables = ["orders", "order_items", "sessions", "events", "users", "sellers", "products"]

# Czyszczenie z dodatkowymi kontrolami
for table in tables:
    print(f"\nCzyszczenie tabeli: {table}")
    try:
        df = pd.read_sql(f'SELECT * FROM "{table}"', engine)
    except Exception as e:
        print(f"Nie udało się wczytać {table}: {e}")
        continue

    print(f" - Wczytano {len(df)} wierszy, {len(df.columns)} kolumn.")

    # SPECYFICZNE POPRAWKI
    if table == "sellers":
        bad_cols = [col for col in df.columns if ";" in col]
        if bad_cols:
            print(f" - Usuwam kolumny z błędnymi nagłówkami: {bad_cols}")
            df.drop(columns=bad_cols, inplace=True, errors="ignore")
        if "location" in df.columns:
            missing = df["location"].isna().sum()
            if missing > 0:
                print(f" - Uzupełniam brakujące location ({missing} wierszy) 'unknown'")
                df["location"].fillna("unknown", inplace=True)

    if table == "products":
        if "stock_quantity" in df.columns:
            missing = df["stock_quantity"].isna().sum()
            if missing > 0:
                print(f" - Uzupełniam brakujący stock ({missing} wierszy) 0")
                df["stock_quantity"].fillna(0, inplace=True)

    if table == "events":
        for col in ["product_id", "seller_id"]:
            if col in df.columns:
                missing = df[col].isna().sum()
                if missing > 0:
                    print(f" - Uzupełniam brakujące {col} ({missing} wierszy) -1")
                    df[col] = df[col].fillna(-1).astype("Int64")

    # KONWERSJA TYPÓW DAT
    for col in df.columns:
        if any(kw in col for kw in ["date", "time"]):
            try:
                df[col] = pd.to_datetime(df[col], errors="coerce")
                print(f" - Skonwertowano kolumnę {col} na datetime")
            except Exception as e:
                print(f" ⚠ Błąd konwersji kolumny {col}: {e}")

    # Zapis do schematu clean
    try:
        df.to_sql(table, engine, schema="clean", if_exists="replace", index=False)
        print(f"Zapisano {table} → clean.{table} ({len(df)} wierszy)")
    except Exception as e:
        print(f"Błąd zapisu {table}: {e}")

print("\nCzyszczenie zakończone.")