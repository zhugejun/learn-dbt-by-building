-- fact table for orders with sales metrics
with orders as (
  select * from {{ ref('int_orders_enriched')}}
),

customers as (
  select 
    customer_id,
    customer_segment,
    country
  from {{ ref('dim_customers')}}
)

select
  o.order_id,
  o.customer_id,

  --date
  o.order_date,

  -- order attributes
  o.order_status,
  o.shipping_method,
  o.is_completed,
  o.order_value_tier,

  -- measures
  o.total_line_items,
  o.total_units,
  o.gross_total,
  o.total_discount,
  o.net_total,

  -- denormalized customer attributes 
  c.customer_segment,
  c.country as customer_country,

  current_timestamp as updated_at
from orders o
left join customers c
  on o.customer_id = c.customer_id