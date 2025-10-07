# Raport z czyszczenia danych

## Opis
Czyszczenie danych zostało wykonane na tabelach w schemacie `public` bazy PostgreSQL.  
Celem było usunięcie braków danych i przygotowanie plików CSV do dalszej analizy.

## Tabele przetworzone
| Tabela        | Liczba wierszy | Zakres czyszczenia |
|---------------|---------------:|--------------------|
| orders        | 80 000         | Brak braków danych — zapis bez zmian |
| order_items   | 219 702        | Brak braków danych — zapis bez zmian |
| sessions      | 100 000        | Brak braków danych — zapis bez zmian |
| events        | 200 000        | Uzupełniono wartości NULL w kolumnach numerycznych wartością `-1` |
| users         | 10 000         | Uzupełniono brakujące lokalizacje (`location`) wartością `"unknown"` |
| sellers       | 75             | Brak braków danych — zapis bez zmian |
| products      | 2 000          | Uzupełniono brakujące wartości w `stock_quantity` wartością `0` |

## Wyniki
- Wszystkie przetworzone dane zapisano w folderze `data/clean` w formacie CSV.
- Pliki mają kodowanie `utf-8-sig` (zgodne z Excel i Power BI).
- Braki danych zostały uzupełnione wartościami zastępczymi zgodnie z powyższą tabelą.

## Uwagi
- Ostrzeżenia `FutureWarning` z biblioteki `pandas` nie wpływają na poprawność wyników.