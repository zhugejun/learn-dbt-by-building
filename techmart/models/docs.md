{% docs customer_segment %}

Customer segments are calculated based on purchase behavior:

| Segment | Criteria |
|---------|----------|
| VIP | LTV >= $200 AND 3+ orders |
| Regular | LTV >= $100 OR 2+ orders |
| New | Exactly 1 order |
| Prospect | No orders |

{% enddocs %}