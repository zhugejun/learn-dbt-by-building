-- product dimension with sales metrics
with products as (
  select * from {{ ref('stg_products') }}
),

order_items as (
  select * from {{ ref('stg_order_items') }}
),

product_sales as (
  select
    product_id,
    count(distinct order_id) as total_ordered,
    sum(quantity) as total_units_sold,
    sum(net_amount) as total_revenue
  from order_items
  group by product_id
)

select
  p.product_id,
  p.product_name,
  p.category,
  p.price,
  p.cost,
  p.profit_margin,
  p.profit_margin_percent,
  p.supplier_id,
  coalesce(ps.total_ordered, 0) as times_ordered,
  coalesce(ps.total_units_sold, 0) as total_units_sold,
  coalesce(ps.total_revenue, 0) as total_revenue,

  case
    when ps.total_revenue >= 200 then 'Top Performer'
    when ps.total_revenue >= 100 then 'Good Performer'
    when ps.total_revenue > 0 then 'Low Performer'
    else 'No Sales'
  end as performance,

  current_timestamp as updated_at

from products p
left join product_sales ps
  on p.product_id = ps.product_id