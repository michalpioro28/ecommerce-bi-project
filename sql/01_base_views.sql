-- ============================================
-- Widoki bazowe na clean.
-- ============================================

SET search_path TO clean, analytics, public;

-- Zamówienia
CREATE OR REPLACE VIEW analytics.v_orders AS
SELECT 
    o.order_id,
    o.user_id,
    o.order_date::timestamp AS order_date,
    o.total_amount::numeric(18,2) AS total_amount
FROM clean.orders o;

-- Pozycje zamówień
CREATE OR REPLACE VIEW analytics.v_order_items AS
SELECT 
    oi.order_id,
    oi.product_id,
    oi.quantity::int AS quantity
FROM clean.order_items oi;

-- Produkty
CREATE OR REPLACE VIEW analytics.v_products AS
SELECT 
    p.product_id, 
    p.product_name, 
    p.category, 
    p.price::numeric(18,2) AS price,
    p.seller_id
FROM clean.products p;

-- Sprzedawcy
CREATE OR REPLACE VIEW analytics.v_sellers AS
SELECT 
    s.seller_id, 
    s.seller_name, 
    s.location
FROM clean.sellers s;