{{
  config(
    materialized = 'incremental',
    partition_by = {
      "field": "usage_date",
      "data_type": "date",
      "granularity": "day"
    },
    cluster_by = ["service_id", "sku_id"],
    unique_key = "daily_sku_id"
  )
}}

SELECT
  usage_date,
  service_id,
  service_description,
  sku_id,
  sku_description,
  usage_unit,
  SUM(usage_amount) AS total_usage,
  SUM(cost) AS total_cost,
  CONCAT(CAST(usage_date AS STRING), '-', service_id, '-', sku_id) AS daily_sku_id
FROM
  {{ ref('stg_google_cloud_billing_export') }}
{% if is_incremental() %}
  WHERE usage_date > (SELECT MAX(usage_date) FROM {{ this }})
{% endif %}
GROUP BY
  usage_date, service_id, service_description, sku_id, sku_description, usage_unit
