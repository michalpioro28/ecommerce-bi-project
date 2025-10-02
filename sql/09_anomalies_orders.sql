-- ============================================

-- Lista zamówień, gdzie total_amount mocno odbiega
-- od (est_revenue)
-- ============================================

SET search_path TO clean, analytics, public;

CREATE OR REPLACE VIEW analytics.v_order_anomalies AS
WITH items_sum AS (
  SELECT order_id, SUM(est_revenue)::numeric(18,2) AS items_est_sum
  FROM analytics.fact_items
  GROUP BY 1
)
SELECT
  fo.order_id,
  fo.order_date,
  fo.total_amount,
  COALESCE(isum.items_est_sum,0) AS items_est_sum,
  (fo.total_amount - COALESCE(isum.items_est_sum,0))::numeric(18,2) AS diff,
  CASE 
    WHEN fo.total_amount = 0 THEN NULL
    ELSE ROUND(100.0 * (fo.total_amount - COALESCE(isum.items_est_sum,0)) / fo.total_amount, 2)
  END AS diff_pct
FROM analytics.fact_orders fo
LEFT JOIN items_sum isum USING (order_id)
WHERE ABS(fo.total_amount - COALESCE(isum.items_est_sum,0)) >= 50.0
ORDER BY ABS(fo.total_amount - COALESCE(isum.items_est_sum,0)) DESC;