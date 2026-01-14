with customer_orders as (
  select * from {{ ref('int_customer_orders') }}
)


select 
  customer_id,
  full_name,
  email,
  country,
  customer_created_at,
  total_orders,
  completed_orders,
  cancelled_orders,
  returned_orders,
  lifetime_value,
  avg_order_value,
  first_order_date,
  last_order_date,
  days_since_last_order,

  -- customer segments based on RFM-lite
  case
    when lifetime_value >= 200 and total_orders >= 3 then 'VIP'
    when lifetime_value >= 100 and total_orders >= 2 then 'Regular'
    when total_orders = 1 then 'New'
    else 'Prospect'
  end as customer_segment,

  --activity status
  case
    when days_since_last_order <= 30 then 'Active'
    when days_since_last_order <= 90 then 'At Risk'
    when days_since_last_order <= 180 then 'Dormant'
    when days_since_last_order > 180 then 'Churned'
    else 'Never Ordered'
  end as activity_status,

  current_timestamp as updated_at

from customer_orders