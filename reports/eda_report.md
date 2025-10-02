# Raport z eksploracyjnej analizy danych (EDA)

> **Streszczenie:** Źródło prawdy dla przychodów to `orders.total_amount`.  
> Pole `order_items.line_total` jest błędne nie używamy w analizach finansowych.  
> Analizy poprawne: topline, AOV, sezonowość, wolumen produktów/sprzedawców.

## Opis
Analiza wykonana na tabelach w schemacie `clean` bazy PostgreSQL.  
Cele:
- weryfikacja podstawowej jakości danych,
- test spójności przychodów między tabelami,
- przygotowanie do dalszych analiz SQL/BI.

---

## Sanity check / Jakość danych

| Sprawdzenie                                                     | Wynik |
|-----------------------------------------------------------------|-------|
| Podgląd danych (po 5 wierszy na tabelę)                         | brak oczywistych `NULL` w badanych kolumnach |
| Kontrola wartości (`total_amount`, `price`)                     | brak wartości ujemnych |
| Porównanie przychodu                                            |       |
| • `SUM(orders.total_amount)`                                    | ≈ **24 mln zł** |
| • `SUM(order_items.line_total * quantity)`                      | ≈ **1,8 mld zł** |
| **Wniosek krytyczny**                                           | **`order_items.line_total` jest niespójne nie nadaje się do analiz finansowych** |

> **Nota:** wnioski zgodne z `eda.py`; sanity check wykonywany na schemacie `clean`.

---

## Analiza przychodów
- Źródłem prawidłowych danych o przychodach jest **wyłącznie** `orders.total_amount`.  
- Trendy miesięczne pokazują sezonowość (jesień–zima).  
- Możliwe do raportowania: **miesięczny przychód** i **AOV**.

---

## Analiza produktów i sprzedawców
- Popularność produktów: liczba sprzedanych sztuk (`quantity`).  
- Ranking sprzedawców: wolumen (sztuki).  
- **Brak** rzetelnego revenue per produkt/sprzedawca (ze względu na błędne `line_total`).

---

## Wnioski biznesowe
- Dane wspierają analizy: **trendy sprzedaży**, **AOV**, **struktura wolumenowa**.  
- Brak wiarygodnego revenue per produkt/seller ogranicza raportowanie **marżowości/rentowności**.

---

## Ograniczenia i dalsze kroki
- `order_items.line_total` powiela sumę zamówienia w każdej pozycji.  
- Wszystkie metryki finansowe oparte wyłącznie na `orders.total_amount`.  
- Nie raportujemy revenue per produkt/sprzedawca.