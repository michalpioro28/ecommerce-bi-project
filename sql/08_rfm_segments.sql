-- ============================================
-- RFM do segmentacji w Power BI
-- ============================================

SET search_path TO clean, analytics, public;

CREATE OR REPLACE VIEW analytics.v_rfm_segments AS
WITH base AS (
  SELECT
    cs.user_id,
    cs.recency_days::int                 AS recency,
    cs.orders_count::int                 AS frequency,
    cs.total_spend::numeric(18,2)        AS monetary
  FROM analytics.customer_summary cs
),
scored AS (
  SELECT
    b.*,
    NTILE(5) OVER (ORDER BY b.recency ASC)         AS r_score,
    NTILE(5) OVER (ORDER BY b.frequency DESC)      AS f_score,
    NTILE(5) OVER (ORDER BY b.monetary  DESC)      AS m_score
  FROM base b
)
SELECT
  user_id,
  recency, frequency, monetary,
  r_score, f_score, m_score,
  (r_score + f_score + m_score) AS rfm_total,
  CASE 
    WHEN r_score >=4 AND f_score >=4 AND m_score >=4 THEN 'Champions'
    WHEN r_score >=4 AND f_score >=3 THEN 'Loyal'
    WHEN r_score >=3 AND m_score  >=4 THEN 'Big Spenders'
    WHEN r_score >=3 AND f_score >=3 THEN 'Potential Loyalist'
    WHEN r_score <=2 AND f_score <=2 AND m_score <=2 THEN 'At Risk'
    ELSE 'Regular'
  END AS rfm_segment
FROM scored;
