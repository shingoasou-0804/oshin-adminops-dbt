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
    cluster_by = ["year", "credit_type"]
  )
}}

SELECT
  year,
  month,
  invoice_month,
  project_id,
  project_name,
  service_id,
  service_description,
  c.type AS credit_type,
  c.name AS credit_name,
  SUM(c.amount) AS credit_amount
FROM
  {{ ref('stg_google_cloud_billing_export') }},
  UNNEST(credits) AS c
WHERE
  credits IS NOT NULL
GROUP BY
  year, month, invoice_month, project_id, project_name, service_id, service_description, credit_type, credit_name
