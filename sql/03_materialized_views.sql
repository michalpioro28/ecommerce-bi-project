-- ============================================
-- Stabilne, zmaterializowane agregaty pod BI
-- (zachowują rozdział: revenue z orders, units z items)
-- ============================================

SET search_path TO clean, analytics, public;

-- Topline miesięczna: revenue & AOV z fact_orders, units z items
CREATE MATERIALIZED VIEW IF NOT EXISTS analytics.topline_monthly AS
WITH revenue_part AS (
    SELECT
        date_trunc('month', fo.order_date)::date AS month,
        SUM(fo.total_amount)::numeric(18,2)      AS revenue,
        COUNT(*)                                 AS orders,
        COUNT(DISTINCT fo.user_id)               AS customers,
        CASE 
            WHEN COUNT(*) > 0 
            THEN (SUM(fo.total_amount)::numeric(18,2) / COUNT(*)) 
            ELSE NULL 
        END AS aov
    FROM analytics.fact_orders fo
    GROUP BY date_trunc('month', fo.order_date)::date
),
units_part AS (
    SELECT
        date_trunc('month', fo.order_date)::date AS month,
        SUM(fi.quantity)::bigint                 AS units_sold
    FROM analytics.fact_items fi
    JOIN analytics.fact_orders fo USING (order_id)
    GROUP BY date_trunc('month', fo.order_date)::date
)
SELECT 
    r.month,
    r.revenue,
    r.orders,
    r.customers,
    COALESCE(u.units_sold, 0) AS units_sold,
    r.aov
FROM revenue_part r
LEFT JOIN units_part u USING (month)
ORDER BY r.month;

-- Fakty per zamówienie: bez joinów duplikujących revenue
CREATE MATERIALIZED VIEW IF NOT EXISTS analytics.order_facts AS
SELECT 
    fo.order_id,
    fo.user_id,
    fo.order_date::date AS order_date,
    fo.total_amount,
    -- liczba sztuk z fact_items policzona per order_id
    COALESCE((
        SELECT SUM(fi.quantity) 
        FROM analytics.fact_items fi 
        WHERE fi.order_id = fo.order_id
    ),0)::int AS items_count,
    EXTRACT(DOW  FROM fo.order_date) AS dow,
    EXTRACT(HOUR FROM fo.order_date) AS hour
FROM analytics.fact_orders fo;

-- Produkty – sztuki (i zakres dat sprzedaży)
CREATE MATERIALIZED VIEW IF NOT EXISTS analytics.product_units AS
SELECT 
    p.product_id, 
    p.product_name, 
    p.category, 
    p.seller_id,
    SUM(fi.quantity)::bigint          AS units_sold,
    MIN(fo.order_date)::date          AS first_sale_date,
    MAX(fo.order_date)::date          AS last_sale_date
FROM analytics.fact_items fi
JOIN analytics.fact_orders fo USING (order_id)
JOIN analytics.v_products p USING (product_id)
GROUP BY p.product_id, p.product_name, p.category, p.seller_id;

-- Sprzedawcy – sztuki, liczba zamówień, liczba klientów
CREATE MATERIALIZED VIEW IF NOT EXISTS analytics.seller_units AS
SELECT
    s.seller_id, 
    s.seller_name, 
    s.location,
    SUM(fi.quantity)::bigint          AS units_sold,
    COUNT(DISTINCT fo.order_id)       AS orders,
    COUNT(DISTINCT fo.user_id)        AS customers
FROM analytics.fact_items fi
JOIN analytics.fact_orders fo USING (order_id)
JOIN analytics.v_products p USING (product_id)
JOIN analytics.v_sellers s USING (seller_id)
GROUP BY s.seller_id, s.seller_name, s.location;

-- Klienci - podsumowanie
CREATE MATERIALIZED VIEW IF NOT EXISTS analytics.customer_summary AS
SELECT
    fo.user_id,
    COUNT(*)                             AS orders_count,
    SUM(fo.total_amount)::numeric(18,2)  AS total_spend,
    AVG(fo.total_amount)::numeric(18,2)  AS avg_order_value,
    MIN(fo.order_date)::date             AS first_order_date,
    MAX(fo.order_date)::date             AS last_order_date,
    (CURRENT_DATE - MAX(fo.order_date)::date) AS recency_days
FROM analytics.fact_orders fo
GROUP BY fo.user_id;

-- Cohorty miesięczne (wg pierwszego zakupu)
CREATE MATERIALIZED VIEW IF NOT EXISTS analytics.cohorts_monthly AS
WITH first_orders AS (
    SELECT 
        user_id, 
        date_trunc('month', MIN(order_date))::date AS cohort_month
    FROM analytics.fact_orders
    GROUP BY user_id
),
orders_m AS (
    SELECT 
        user_id, 
        date_trunc('month', order_date)::date AS order_month
    FROM analytics.fact_orders
)
SELECT 
    f.cohort_month,
    o.order_month,
    COUNT(DISTINCT o.user_id) AS users
FROM first_orders f
JOIN orders_m o USING (user_id)
GROUP BY f.cohort_month, o.order_month
ORDER BY f.cohort_month, o.order_month;

-- Estymacja przychodu per produkt (oznaczona jako estymacja)
CREATE MATERIALIZED VIEW IF NOT EXISTS analytics.product_est_revenue AS
SELECT 
    p.product_id, 
    p.product_name, 
    p.category,
    SUM(fi.est_revenue)::numeric(18,2) AS est_revenue
FROM analytics.fact_items fi
JOIN analytics.v_products p USING (product_id)
GROUP BY p.product_id, p.product_name, p.category;