{{
  config(
    materialized = 'incremental',
    partition_by = {
      "field": "usage_date",
      "data_type": "date",
      "granularity": "day"
    },
    cluster_by = ["service_id"],
    unique_key = "daily_service_id"
  )
}}

SELECT
  usage_date,
  service_id,
  service_description,
  SUM(cost) AS total_cost,
  SUM(CASE WHEN credits IS NOT NULL THEN 
      (SELECT SUM(c.amount) FROM UNNEST(credits) AS c) 
      ELSE 0 END) AS total_credits,
  SUM(cost) + SUM(CASE WHEN credits IS NOT NULL THEN 
      (SELECT SUM(c.amount) FROM UNNEST(credits) AS c) 
      ELSE 0 END) AS net_cost,
  CONCAT(CAST(usage_date AS STRING), '-', service_id) AS daily_service_id
FROM
  {{ ref('stg_google_cloud_billing_export') }}
{% if is_incremental() %}
  WHERE usage_date > (SELECT MAX(usage_date) FROM {{ this }})
{% endif %}
GROUP BY
  usage_date, service_id, service_description
