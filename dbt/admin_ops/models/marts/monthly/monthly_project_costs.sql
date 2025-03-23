{{
  config(
    materialized = 'table',
    partition_by = {
      "field": "month",
      "data_type": "int64",
      "range": {
        "start": 1,
        "end": 13,
        "interval": 1
      }
    },
    cluster_by = ["year", "project_id"]
  )
}}

SELECT
  year,
  month,
  invoice_month,
  project_id,
  project_name,
  SUM(cost) AS total_cost,
  SUM(CASE WHEN credits IS NOT NULL THEN 
      (SELECT SUM(c.amount) FROM UNNEST(credits) AS c) 
      ELSE 0 END) AS total_credits,
  SUM(cost) + SUM(CASE WHEN credits IS NOT NULL THEN 
      (SELECT SUM(c.amount) FROM UNNEST(credits) AS c) 
      ELSE 0 END) AS net_cost
FROM
  {{ ref('stg_google_cloud_billing_export') }}
GROUP BY
  year, month, invoice_month, project_id, project_name
