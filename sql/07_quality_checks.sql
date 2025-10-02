-- ============================================
-- Testy: zwracają wiersze tylko jeśli COŚ SIĘ NIE ZGADZA
-- (idealnie: puste wyniki / zera)
-- ============================================

SET search_path TO clean, analytics, public;

-- 1) NULL-e w krytycznych polach
SELECT 'orders.order_date nulls' AS check, COUNT(*) AS cnt
FROM clean.orders WHERE order_date IS NULL
HAVING COUNT(*) > 0;

SELECT 'orders.total_amount nulls' AS check, COUNT(*) AS cnt
FROM clean.orders WHERE total_amount IS NULL
HAVING COUNT(*) > 0;

-- 2) Duplikaty w kluczach MVs (nie powinno być żadnych)
SELECT 'order_facts dup order_id' AS check, order_id, COUNT(*) cnt
FROM analytics.order_facts GROUP BY 2 HAVING COUNT(*)>1;

SELECT 'product_units dup product_id' AS check, product_id, COUNT(*) cnt
FROM analytics.product_units GROUP BY 2 HAVING COUNT(*)>1;

SELECT 'seller_units dup seller_id' AS check, seller_id, COUNT(*) cnt
FROM analytics.seller_units GROUP BY 2 HAVING COUNT(*)>1;

SELECT 'customer_summary dup user_id' AS check, user_id, COUNT(*) cnt
FROM analytics.customer_summary GROUP BY 2 HAVING COUNT(*)>1;

-- 3) Spójność przychodu miesięcznego:
-- topline_monthly.revenue musi się równać SUM(orders.total_amount)
SELECT
    tm.month,
    tm.revenue AS revenue_view,
    SUM(fo.total_amount)::numeric(18,2) AS revenue_orders,
    tm.revenue - SUM(fo.total_amount)::numeric(18,2) AS diff
FROM analytics.topline_monthly tm
JOIN analytics.fact_orders fo 
  ON date_trunc('month', fo.order_date)::date = tm.month
GROUP BY tm.month, tm.revenue
HAVING tm.revenue <> SUM(fo.total_amount)::numeric(18,2)
ORDER BY tm.month;

-- 4) Spójność units: product_units.units_sold vs order_items
SELECT 
    pu.product_id,
    pu.units_sold AS units_in_view,
    SUM(oi.quantity)::bigint AS units_in_items,
    (pu.units_sold - SUM(oi.quantity)::bigint) AS diff
FROM analytics.product_units pu
JOIN clean.order_items oi USING (product_id)
GROUP BY pu.product_id, pu.units_sold
HAVING pu.units_sold <> SUM(oi.quantity)::bigint
ORDER BY diff DESC;

-- 5) Kontrola faktów: liczba months, orders w topline vs fact_orders
SELECT 
  'topline_monthly vs fact_orders count mismatch' AS check,
  (SELECT COUNT(*) FROM analytics.topline_monthly) AS months_in_view,
  (SELECT COUNT(DISTINCT date_trunc('month', order_date)) FROM analytics.fact_orders) AS months_in_orders
WHERE (SELECT COUNT(*) FROM analytics.topline_monthly) 
   <> (SELECT COUNT(DISTINCT date_trunc('month', order_date)) FROM analytics.fact_orders);