-- marketing report

with customers as (
  select * from {{ ref('dim_customers') }}
)

select 
  customer_segment,
  activity_status,
  country,
  count(*) as customer_count,
  sum(lifetime_value) as total_ltv,
  avg(lifetime_value) as avg_ltv,
  avg(total_orders) as avg_orders_per_customer,
  avg(avg_order_value) as avg_order_value

from customers
group by 
  customer_segment,
  activity_status,
  country
order BY
  customer_segment,
  activity_status,
  country