import os
import warnings
import pandas as pd
import seaborn as sns
import matplotlib.pyplot as plt
from matplotlib.ticker import FuncFormatter
from dotenv import load_dotenv
from sqlalchemy import create_engine

# --- Ustawienia globalne ---
warnings.filterwarnings("ignore")
sns.set_theme(style="whitegrid", palette="muted", font_scale=1.1)
os.makedirs("reports/fig", exist_ok=True)

# ---Formatery PLN ---

def zl_formatter_full(x, pos):
    try:
        return f"{int(x):,} zł".replace(",", " ")
    except Exception:
        return f"{x} zł"

def zl_formatter_small(x, pos):
    return f"{int(x):,}".replace(",", " ")

# --- Połączenie z bazą ---

load_dotenv()
engine = create_engine(
    f"postgresql+psycopg2://{os.getenv('DB_USER')}:{os.getenv('DB_PASS')}@{os.getenv('DB_HOST')}/{os.getenv('DB_NAME')}"
)

# --- Sanity check ---

tables = pd.read_sql(
    "SELECT table_name FROM information_schema.tables WHERE table_schema='clean'",
    engine
)["table_name"].tolist()

lines = []
for table in tables:
    df = pd.read_sql(f'SELECT * FROM clean.{table} LIMIT 5', engine)
    nulls = df.isnull().sum().to_dict()
    lines.append(f"Tabela: {table}\nWiersze: {len(df)}\nBraki NULL: {nulls}\n{'-'*50}\n")

# ---Spójność revenue ---

rev_orders = pd.read_sql("SELECT SUM(total_amount) AS revenue FROM clean.orders", engine).iloc[0,0]
rev_items = pd.read_sql("SELECT SUM(line_total * quantity) AS revenue FROM clean.order_items", engine).iloc[0,0]

lines.append("\nSpójność revenue:\n")
lines.append(f"SUM(orders.total_amount) = {rev_orders:,.0f} zł\n")
lines.append(f"SUM(order_items.line_total * quantity) = {rev_items:,.0f} zł\n")
if rev_orders and rev_items and abs(rev_orders - rev_items) > 0.05 * rev_orders:
    lines.append("Niespójność: revenue analizujemy wyłącznie z tabeli orders.\n")
else:
    lines.append("Revenue spójne między orders i order_items.\n")

with open("reports/audit_summary_clean.txt", "w", encoding="utf-8") as f:
    f.writelines(lines)

print("📝 Zapisano sanity check → reports/audit_summary_clean.txt")

# --- Zamówienia ---
orders = pd.read_sql('SELECT total_amount, order_date, user_id FROM clean.orders', engine)
if not orders.empty:
    # Histogram wartości zamówień
    plt.figure(figsize=(9,5.5))
    sns.histplot(orders["total_amount"], bins=40, kde=True, color="teal")
    plt.title("Rozkład wartości zamówień")
    plt.xlabel("Wartość zamówienia")
    plt.ylabel("Liczba zamówień")
    plt.savefig("reports/fig/hist_orders_total_amount.png", dpi=150, bbox_inches="tight")
    plt.close()

    # Miesięczny przychód i AOV
    orders['month'] = orders['order_date'].dt.to_period('M').dt.to_timestamp()
    rev_month = orders.groupby('month').agg(
        revenue=('total_amount','sum'),
        orders_cnt=('total_amount','count')
    ).reset_index()
    rev_month['aov'] = rev_month['revenue'] / rev_month['orders_cnt']
    rev_month = rev_month[rev_month['month'] <= pd.Timestamp('2025-07-01')]

    # Przychód miesięczny
    plt.figure(figsize=(10,5.5))
    sns.lineplot(data=rev_month, x='month', y='revenue', marker='o', color="royalblue")
    plt.title("Przychód miesięczny")
    plt.ylabel("Przychód")
    plt.gca().yaxis.set_major_formatter(FuncFormatter(zl_formatter_full))
    plt.savefig("reports/fig/line_revenue_by_month.png", dpi=150, bbox_inches="tight")
    plt.close()

    # Średnia wartość zamówienia (AOV)
    plt.figure(figsize=(10,5.5))
    sns.lineplot(data=rev_month, x='month', y='aov', marker='o', color="darkorange")
    plt.title("Średnia wartość zamówienia (AOV) miesięcznie")
    plt.ylabel("AOV")
    plt.gca().yaxis.set_major_formatter(FuncFormatter(zl_formatter_small))
    plt.savefig("reports/fig/line_aov_by_month.png", dpi=150, bbox_inches="tight")
    plt.close()

# --- Top 10 produktów ---
q_items = """
SELECT p.product_name, SUM(oi.quantity) AS total_quantity
FROM clean.order_items oi
JOIN clean.products p ON p.product_id = oi.product_id
GROUP BY p.product_name
ORDER BY total_quantity DESC
LIMIT 10
"""
top_products = pd.read_sql(q_items, engine)
if not top_products.empty:
    plt.figure(figsize=(10,5.5))
    sns.barplot(data=top_products, x="product_name", y="total_quantity", palette="viridis")
    plt.title("TOP 10 produktów względem liczby sprzedanych sztuk")
    plt.xlabel("Nazwa produktu")
    plt.ylabel("Sprzedane sztuki")
    plt.xticks(rotation=30, ha='right')
    plt.savefig("reports/fig/bar_top_products.png", dpi=150, bbox_inches="tight")
    plt.close()

# --- Top 10 sprzedawców ---
q_sellers = """
SELECT s.seller_name, SUM(oi.quantity) AS total_quantity
FROM clean.order_items oi
JOIN clean.products p ON p.product_id = oi.product_id
JOIN clean.sellers s ON s.seller_id = p.seller_id
GROUP BY s.seller_name
ORDER BY total_quantity DESC
LIMIT 10
"""
top_sellers = pd.read_sql(q_sellers, engine)
if not top_sellers.empty:
    plt.figure(figsize=(10,5.5))
    sns.barplot(data=top_sellers, x="seller_name", y="total_quantity", palette="coolwarm")
    plt.title("TOP 10 sprzedawców względem liczby sprzedanych sztuk")
    plt.xlabel("Sprzedawca")
    plt.ylabel("Sprzedane sztuki")
    plt.xticks(rotation=30, ha='right')
    plt.savefig("reports/fig/bar_top_sellers.png", dpi=150, bbox_inches="tight")
    plt.close()

# --- Liczba zamówień na użytkownika ---
orders_per_user = orders.groupby('user_id').size().reset_index(name='orders_cnt')
plt.figure(figsize=(9,5.5))
sns.histplot(orders_per_user['orders_cnt'], bins=30, kde=False, color="green")
plt.title("Liczba zamówień na użytkownika")
plt.xlabel("Liczba zamówień")
plt.ylabel("Liczba użytkowników")
plt.xticks(range(0, orders_per_user['orders_cnt'].max()+1, max(1, orders_per_user['orders_cnt'].max()//10)))
plt.savefig("reports/fig/hist_orders_per_user.png", dpi=150, bbox_inches="tight")
plt.close()

# --- Statystyki produktów ---
products = pd.read_sql('SELECT stock_quantity, price FROM clean.products', engine)
if not products.empty:
    stats = products.describe().T[['count','mean','50%','min','max']]
    with open("reports/product_stats.txt", "w", encoding="utf-8") as f:
        f.write(stats.to_string())
    print("Zapisano statystyki produktów → reports/product_stats.txt")

print("\nEDA zakończone. Wyniki w folderze reports/")

