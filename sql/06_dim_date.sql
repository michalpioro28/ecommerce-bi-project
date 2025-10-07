-- ============================================
-- Rozszerzone dim_date jako materialized view
-- ============================================

SET search_path TO clean, analytics, public;

CREATE MATERIALIZED VIEW IF NOT EXISTS analytics.dim_date AS
SELECT 
    d::date                         AS dt,
    EXTRACT(YEAR FROM d)::int       AS year,
    EXTRACT(MONTH FROM d)::int      AS month,
    EXTRACT(DAY FROM d)::int        AS day,
    TO_CHAR(d, 'YYYY-MM')           AS yyyymm,
    TO_CHAR(d, 'YYYY-"Q"Q')         AS year_quarter,
    EXTRACT(QUARTER FROM d)::int    AS quarter,
    EXTRACT(DOW FROM d)::int        AS dow_num,
    TO_CHAR(d, 'Dy')                AS dow_name_short,
    TO_CHAR(d, 'Day')               AS dow_name_full,
    CASE 
      WHEN EXTRACT(DOW FROM d) IN (0,6) THEN true 
      ELSE false 
    END                             AS is_weekend,
    DATE_TRUNC('month', d)::date    AS month_start,
    (DATE_TRUNC('month', d) 
       + INTERVAL '1 month - 1 day')::date AS month_end,
    DATE_TRUNC('quarter', d)::date  AS quarter_start,
    (DATE_TRUNC('quarter', d) 
       + INTERVAL '3 month - 1 day')::date AS quarter_end
FROM generate_series(
  (SELECT MIN(order_date)::date FROM analytics.fact_orders),
  (SELECT MAX(order_date)::date FROM analytics.fact_orders),
  interval '1 day'
) AS g(d);

-- Unikalny indeks umożliwiający REFRESH CONCURRENTLY
CREATE UNIQUE INDEX IF NOT EXISTS ux_dim_date_dt
  ON analytics.dim_date(dt);
