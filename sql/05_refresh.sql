-- ============================================
-- Odświeżanie
-- Wymaga unikalnych indeksów
-- ============================================

SET search_path TO clean, analytics, public;

REFRESH MATERIALIZED VIEW CONCURRENTLY analytics.topline_monthly;
REFRESH MATERIALIZED VIEW CONCURRENTLY analytics.order_facts;
REFRESH MATERIALIZED VIEW CONCURRENTLY analytics.product_units;
REFRESH MATERIALIZED VIEW CONCURRENTLY analytics.seller_units;
REFRESH MATERIALIZED VIEW CONCURRENTLY analytics.customer_summary;
REFRESH MATERIALIZED VIEW CONCURRENTLY analytics.cohorts_monthly;
REFRESH MATERIALIZED VIEW CONCURRENTLY analytics.product_est_revenue;