-- ============================================
-- Indeksy i unikalne indeksy na MV,
-- żeby działał REFRESH CONCURRENTLY bez błędów
-- ============================================

SET search_path TO clean, analytics, public;

-- Indeksy na tabelach źródłowych (jeśli nie istnieją)
CREATE INDEX IF NOT EXISTS idx_orders_date  ON clean.orders (order_date);
CREATE INDEX IF NOT EXISTS idx_orders_user  ON clean.orders (user_id);
CREATE INDEX IF NOT EXISTS idx_items_order  ON clean.order_items (order_id);
CREATE INDEX IF NOT EXISTS idx_items_prod   ON clean.order_items (product_id);
CREATE INDEX IF NOT EXISTS idx_products_sell ON clean.products (seller_id);

-- Unikalne indeksy na materializowanych widokach (wymóg dla CONCURRENTLY)

-- jeden wiersz na miesiąc
CREATE UNIQUE INDEX IF NOT EXISTS ux_topline_monthly_month
  ON analytics.topline_monthly (month);

-- jeden wiersz na order_id
CREATE UNIQUE INDEX IF NOT EXISTS ux_order_facts_order
  ON analytics.order_facts (order_id);

-- jeden wiersz na produkt
CREATE UNIQUE INDEX IF NOT EXISTS ux_product_units_product
  ON analytics.product_units (product_id);

-- jeden wiersz na sprzedawcę
CREATE UNIQUE INDEX IF NOT EXISTS ux_seller_units_seller
  ON analytics.seller_units (seller_id);

-- jeden wiersz na klienta
CREATE UNIQUE INDEX IF NOT EXISTS ux_customer_summary_user
  ON analytics.customer_summary (user_id);

-- jeden wiersz na (cohort_month, order_month)
CREATE UNIQUE INDEX IF NOT EXISTS ux_cohorts_monthly_pair
  ON analytics.cohorts_monthly (cohort_month, order_month);

-- jeden wiersz na produkt (estymacja)
CREATE UNIQUE INDEX IF NOT EXISTS ux_product_est_revenue_product
  ON analytics.product_est_revenue (product_id);