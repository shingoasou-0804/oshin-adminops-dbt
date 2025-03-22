{{
  config(
    materialized = 'view'
  )
}}

SELECT
  invoice.month as invoice_month,
  project.id as project_id,
  project.name as project_name,
  service.id as service_id,
  service.description as service_description,
  sku.id as sku_id,
  sku.description as sku_description,
  usage_start_time,
  usage_end_time,
  cost,
  currency,
  usage.amount as usage_amount,
  usage.unit as usage_unit,
  usage.pricing_unit as pricing_unit,
  credits,
  DATE(usage_start_time) AS usage_date,
  EXTRACT(MONTH FROM usage_start_time) AS month,
  EXTRACT(YEAR FROM usage_start_time) AS year
FROM 
  {{ source('google_cloud_billing', 'gcp_billing_export_v1_015A0B_9E88E8_960BB7') }}
