with orders as (
  select * from {{ ref('stg_orders') }}
),

order_items as (
  select * from {{ ref('stg_order_items') }}
),

order_totals as (
  select
    order_id,
    count(*) as total_items,
    sum(quantity) as total_units,
    sum(gross_amount) as gross_total,
    sum(discount_amount) as total_discount,
    sum(net_amount) as net_total
  from order_items
  group by order_id
)

select
  o.order_id,
  o.customer_id,
  o.order_date,
  o.order_status,
  o.shipping_method,
  o.is_completed,
  coalesce(ot.total_items, 0) as total_line_items,
  coalesce(ot.total_units, 0) as total_units,
  coalesce(ot.gross_total, 0) as gross_total,
  coalesce(ot.total_discount, 0) as total_discount,
  coalesce(ot.net_total, 0) as net_total,
  case when ot.net_total >= 100 then 'high'
       when ot.net_total >= 50 then 'medium'
       else 'low'
  end as order_value_tier
from orders o
left join order_totals ot
  on o.order_id = ot.order_id