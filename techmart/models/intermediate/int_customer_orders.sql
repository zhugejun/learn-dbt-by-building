with customers as (
  select * from {{ ref('stg_customers') }}
),

orders as (
  select * from {{ ref('int_orders_enriched') }}
),

customer_order_stats as (
  select customer_id,
    count(*) as total_orders,
    count(case when is_completed then 1 end) as completed_orders,
    count(case when order_status = 'cancelled' then 1 end) as cancelled_orders,
    count(case when order_status = 'returned' then 1 end) as returned_orders,
    sum(case when is_completed then net_total else 0 end) as lifetime_value,
    avg(case when is_completed then net_total else 0 end) as avg_order_value,
    min(order_date) as first_order_date,
    max(order_date) as last_order_date
  from orders
  group by customer_id
)

select 
  c.customer_id,
  c.full_name,
  c.email,
  c.country,
  c.customer_created_at,
  coalesce(cos.total_orders, 0) as total_orders,
  coalesce(cos.completed_orders, 0) as completed_orders,
  coalesce(cos.cancelled_orders, 0) as cancelled_orders,
  coalesce(cos.returned_orders, 0) as returned_orders,
  coalesce(cos.lifetime_value, 0) as lifetime_value,
  coalesce(cos.avg_order_value, 0) as avg_order_value,
  cos.first_order_date,
  cos.last_order_date,
  current_date - cos.last_order_date as days_since_last_order
from customers c
left join customer_order_stats cos
  on c.customer_id = cos.customer_id