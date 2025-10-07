# Import niezbędnych bibliotek

import os
import pandas as pd
from dotenv import load_dotenv
from sqlalchemy import create_engine, text

# Wczytanie zmiennych z pliku .env
load_dotenv()

DB_HOST = os.getenv("DB_HOST")
DB_NAME = os.getenv("DB_NAME")
DB_USER = os.getenv("DB_USER")
DB_PASS = os.getenv("DB_PASS")

# Połączenie z bazą
engine = create_engine(f"postgresql+psycopg2://{DB_USER}:{DB_PASS}@{DB_HOST}/{DB_NAME}")

with engine.connect() as conn:
    version = conn.execute(text("SELECT version()")).scalar()
    print(f"Połączono z bazą. Wersja PostgreSQL: {version}")

# Pobranie listy tabel w schemacie public
tables = pd.read_sql(
    "SELECT table_name FROM information_schema.tables WHERE table_schema='public'",
    engine
)["table_name"].tolist()

print(f"\n Znaleziono {len(tables)} tabel: {tables}")

# Folder na raporty
out_dir = os.path.join("data", "audit_reports")
os.makedirs(out_dir, exist_ok=True)

# Lista na podsumowanie
all_tables_report = []

# Audyt tabel
for table in tables:
    print(f"\n=== Audyt tabeli: {table} ===")

    preview = pd.read_sql(f'SELECT * FROM "{table}" LIMIT 5', engine)
    print(preview)

    # Liczba wierszy
    row_count = pd.read_sql(f'SELECT COUNT(*) FROM "{table}"', engine).iloc[0, 0]
    print(f"Liczba wierszy: {row_count}")

    # Braki danych
    null_counts = preview.isnull().sum()
    print("\nBraki danych (NULL):")
    print(null_counts)

    # Uwagi
    uwagi = []
    for col in preview.columns:
        if preview[col].nunique(dropna=True) == len(preview):
            uwagi.append(f"Kolumna '{col}' ma unikalne wartości w podglądzie")
        if any(";" in str(v) for v in preview[col].dropna()):
            uwagi.append(f"Kolumna '{col}' zawiera średnik w danych")

    all_tables_report.append({
        "tabela": table,
        "wiersze": row_count,
        "braki_NULL": null_counts.to_dict(),
        "uwagi": "; ".join(uwagi) if uwagi else ""
    })

# Zapis raportu
report_df = pd.DataFrame(all_tables_report)
report_path = os.path.join(out_dir, "audit_summary_raw.csv")
report_df.to_csv(report_path, index=False, encoding="utf-8-sig")

print(f"\n Audyt zakończony. Raport zapisany do: {report_path}")