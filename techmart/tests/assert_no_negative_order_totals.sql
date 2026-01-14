select
  *
from {{ ref('fct_orders') }}
where net_total < 0