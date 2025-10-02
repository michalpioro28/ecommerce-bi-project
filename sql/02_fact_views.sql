-- ============================================
-- Fakty pod Power BI: orders & items
-- ============================================

SET search_path TO clean, analytics, public;

-- FACT: Orders
CREATE OR REPLACE VIEW analytics.fact_orders AS
SELECT 
    o.order_id,
    o.user_id,
    o.order_date,
    COALESCE(o.total_amount,0)::numeric(18,2) AS total_amount
FROM analytics.v_orders o;

-- FACT: Items (sztuki + estymacja przychodu)
-- Uwaga: est_revenue to TYLKO estymacja (quantity * price)
CREATE OR REPLACE VIEW analytics.fact_items AS
SELECT 
    oi.order_id,
    oi.product_id,
    COALESCE(oi.quantity,0)::int AS quantity,
    COALESCE(p.price,0)::numeric(18,2) AS price,
    (COALESCE(oi.quantity,0) * COALESCE(p.price,0))::numeric(18,2) AS est_revenue
FROM analytics.v_order_items oi
JOIN analytics.v_products p USING (product_id);