{{
  config(
    materialized = 'table'
  )
}}

WITH daily_costs AS (
  SELECT
    usage_date,
    project_id,
    project_name,
    total_cost
  FROM
    {{ ref('daily_project_costs') }}
  WHERE
    usage_date >= DATE_SUB(CURRENT_DATE(), INTERVAL 30 DAY)
),
project_stats AS (
  SELECT
    project_id,
    AVG(total_cost) AS avg_daily_cost,
    STDDEV(total_cost) AS stddev_daily_cost
  FROM
    daily_costs
  WHERE
    -- 最新日を除外して統計を計算
    usage_date < DATE_SUB(CURRENT_DATE(), INTERVAL 1 DAY)
  GROUP BY
    project_id
),
latest_costs AS (
  SELECT
    usage_date,
    project_id,
    project_name,
    total_cost
  FROM
    daily_costs
  WHERE
    usage_date = DATE_SUB(CURRENT_DATE(), INTERVAL 1 DAY)
)
SELECT
  l.usage_date,
  l.project_id,
  l.project_name,
  l.total_cost AS daily_cost,
  s.avg_daily_cost,
  l.total_cost - s.avg_daily_cost AS cost_diff,
  (l.total_cost - s.avg_daily_cost) / NULLIF(s.avg_daily_cost, 0) * 100 AS pct_diff,
  (l.total_cost - s.avg_daily_cost) / NULLIF(s.stddev_daily_cost, 0) AS z_score,
  CASE
    WHEN l.total_cost > s.avg_daily_cost + 2 * s.stddev_daily_cost THEN 'High Anomaly'
    WHEN l.total_cost > s.avg_daily_cost + 1.5 * s.stddev_daily_cost THEN 'Medium Anomaly'
    WHEN l.total_cost < s.avg_daily_cost - 1.5 * s.stddev_daily_cost THEN 'Low Usage'
    ELSE 'Normal'
  END AS anomaly_status
FROM
  latest_costs l
JOIN
  project_stats s
ON
  l.project_id = s.project_id
WHERE
  -- 平均よりも50%以上高いか、標準偏差の1.5倍以上外れている場合
  ABS(l.total_cost - s.avg_daily_cost) / NULLIF(s.avg_daily_cost, 0) > 0.5
  OR ABS(l.total_cost - s.avg_daily_cost) / NULLIF(s.stddev_daily_cost, 0) > 1.5
