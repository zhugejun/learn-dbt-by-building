# Learn dbt by Building: E-Commerce Analytics Pipeline

A hands-on project-based tutorial to master dbt (Data Build Tool) from scratch.

---

## What You'll Build

You'll build a complete analytics pipeline for a fictional e-commerce company called **"TechMart"**. By the end, you'll have:

- A layered data model (staging → intermediate → marts)
- Data quality tests
- Auto-generated documentation
- Slowly Changing Dimensions (SCD Type 2) with snapshots
- Custom macros and Jinja templating
- Integration with dbt packages

---

## Prerequisites

- Basic SQL knowledge (SELECT, JOIN, GROUP BY, CTEs)
- A code editor (VS Code recommended)
- Git basics (clone, commit, push)
- Python 3.8+ installed

---

## Part 1: Environment Setup

### Option A: DuckDB (Free, Local, No Cloud Account Needed)

DuckDB is perfect for learning — it's a free, embedded database that runs locally.

```bash
# Create project directory
mkdir techmart-analytics && cd techmart-analytics

# Create virtual environment
python -m venv .venv

# Install dbt with DuckDB adapter
uv init
uv add dbt-duckdb
uv sync
source .venv/bin/activate  # On Windows: .venv\Scripts\activate

# Initialize dbt project
dbt init techmart
cd techmart
```

Update your `profiles.yml` (usually at `~/.dbt/profiles.yml`):

```yaml
techmart:
  outputs:
    dev:
      type: duckdb
      path: 'techmart.duckdb'
      threads: 4
  target: dev
```

### Option B: BigQuery (Free Tier - 1TB queries/month)

```bash
pip install dbt-bigquery
dbt init techmart
```

Follow the prompts to connect to your GCP project.

### Option C: Snowflake (30-day free trial)

```bash
pip install dbt-snowflake
dbt init techmart
```

### Verify Setup

```bash
dbt debug
```

You should see "All checks passed!"

---

## Part 2: Understanding the Project Structure

After `dbt init`, your project looks like this:

```
techmart/
├── dbt_project.yml      # Project configuration
├── models/              # Your SQL transformations
├── seeds/               # CSV files to load as tables
├── snapshots/           # SCD Type 2 tracking
├── macros/              # Reusable SQL snippets
├── tests/               # Custom data tests
└── analyses/            # Ad-hoc analytical queries
```

Update `dbt_project.yml`:

```yaml
name: 'techmart'
version: '1.0.0'
config-version: 2

profile: 'techmart'

model-paths: ["models"]
analysis-paths: ["analyses"]
test-paths: ["tests"]
seed-paths: ["seeds"]
macro-paths: ["macros"]
snapshot-paths: ["snapshots"]

clean-targets:
  - "target"
  - "dbt_packages"

models:
  techmart:
    staging:
      +materialized: view
    intermediate:
      +materialized: view
    marts:
      +materialized: table
```

---

## Part 3: Loading Sample Data with Seeds

Seeds are CSV files that dbt loads into your warehouse. Perfect for reference data or sample datasets.

### Create the seed files:

**seeds/raw_customers.csv**
```csv
customer_id,first_name,last_name,email,created_at,country
1,John,Doe,john.doe@email.com,2023-01-15,USA
2,Jane,Smith,jane.smith@email.com,2023-02-20,Canada
3,Bob,Johnson,bob.j@email.com,2023-03-10,USA
4,Alice,Williams,alice.w@email.com,2023-04-05,UK
5,Charlie,Brown,charlie.b@email.com,2023-05-12,Germany
6,Diana,Miller,diana.m@email.com,2023-06-18,USA
7,Edward,Davis,edward.d@email.com,2023-07-22,Canada
8,Fiona,Garcia,fiona.g@email.com,2023-08-30,UK
9,George,Martinez,george.m@email.com,2023-09-14,USA
10,Helen,Anderson,helen.a@email.com,2023-10-25,France
```

**seeds/raw_products.csv**
```csv
product_id,product_name,category,price,cost,supplier_id
101,Wireless Mouse,Electronics,29.99,12.00,1
102,Mechanical Keyboard,Electronics,89.99,45.00,1
103,USB-C Hub,Electronics,49.99,22.00,2
104,Monitor Stand,Accessories,39.99,18.00,3
105,Laptop Sleeve,Accessories,24.99,10.00,3
106,Webcam HD,Electronics,79.99,35.00,2
107,Desk Lamp,Office,34.99,15.00,4
108,Notebook Set,Office,12.99,5.00,4
109,Wireless Charger,Electronics,29.99,14.00,1
110,Phone Stand,Accessories,19.99,8.00,3
```

**seeds/raw_orders.csv**
```csv
order_id,customer_id,order_date,status,shipping_method
1001,1,2024-01-05,completed,standard
1002,2,2024-01-06,completed,express
1003,1,2024-01-10,completed,standard
1004,3,2024-01-12,completed,express
1005,4,2024-01-15,completed,standard
1006,5,2024-01-18,cancelled,standard
1007,2,2024-01-20,completed,express
1008,6,2024-01-22,completed,standard
1009,7,2024-01-25,completed,express
1010,3,2024-01-28,pending,standard
1011,8,2024-02-01,completed,express
1012,9,2024-02-05,completed,standard
1013,1,2024-02-08,completed,express
1014,10,2024-02-10,completed,standard
1015,4,2024-02-12,returned,express
```

**seeds/raw_order_items.csv**
```csv
order_item_id,order_id,product_id,quantity,unit_price,discount_percent
1,1001,101,2,29.99,0
2,1001,102,1,89.99,10
3,1002,103,1,49.99,0
4,1002,106,1,79.99,5
5,1003,104,2,39.99,0
6,1004,101,1,29.99,0
7,1004,105,3,24.99,15
8,1005,107,1,34.99,0
9,1005,108,5,12.99,20
10,1006,109,2,29.99,0
11,1007,102,1,89.99,0
12,1007,110,2,19.99,10
13,1008,101,1,29.99,5
14,1009,103,2,49.99,0
15,1009,106,1,79.99,0
16,1010,104,1,39.99,0
17,1011,105,2,24.99,0
18,1012,107,1,34.99,10
19,1013,108,3,12.99,0
20,1013,109,1,29.99,5
21,1014,110,4,19.99,0
22,1015,102,1,89.99,0
```

### Load the seeds:

```bash
dbt seed
```

---

## Part 4: Building Staging Models

Staging models are 1:1 with source tables. They handle:
- Renaming columns to consistent conventions
- Casting data types
- Basic cleaning

### Create the folder structure:

```
models/
├── staging/
│   ├── _stg_sources.yml
│   ├── stg_customers.sql
│   ├── stg_products.sql
│   ├── stg_orders.sql
│   └── stg_order_items.sql
```

**models/staging/_stg_sources.yml**
```yaml
version: 2

sources:
  - name: raw
    description: Raw TechMart data loaded from seeds
    schema: main  # For DuckDB; use your schema for other warehouses
    tables:
      - name: raw_customers
        description: Customer information
        columns:
          - name: customer_id
            description: Primary key
            tests:
              - unique
              - not_null
      - name: raw_products
        description: Product catalog
      - name: raw_orders
        description: Order headers
      - name: raw_order_items
        description: Order line items
```

**models/staging/stg_customers.sql**
```sql
with source as (
    select * from {{ source('raw', 'raw_customers') }}
),

renamed as (
    select
        customer_id,
        first_name,
        last_name,
        first_name || ' ' || last_name as full_name,
        lower(email) as email,
        country,
        cast(created_at as date) as customer_created_at
    from source
)

select * from renamed
```

**models/staging/stg_products.sql**
```sql
with source as (
    select * from {{ source('raw', 'raw_products') }}
),

renamed as (
    select
        product_id,
        product_name,
        category,
        cast(price as decimal(10, 2)) as price,
        cast(cost as decimal(10, 2)) as cost,
        cast(price - cost as decimal(10, 2)) as profit_margin,
        round((price - cost) / price * 100, 2) as profit_margin_percent,
        supplier_id
    from source
)

select * from renamed
```

**models/staging/stg_orders.sql**
```sql
with source as (
    select * from {{ source('raw', 'raw_orders') }}
),

renamed as (
    select
        order_id,
        customer_id,
        cast(order_date as date) as order_date,
        status as order_status,
        shipping_method,
        case 
            when status = 'completed' then true
            else false
        end as is_completed
    from source
)

select * from renamed
```

**models/staging/stg_order_items.sql**
```sql
with source as (
    select * from {{ source('raw', 'raw_order_items') }}
),

calculated as (
    select
        order_item_id,
        order_id,
        product_id,
        quantity,
        cast(unit_price as decimal(10, 2)) as unit_price,
        cast(discount_percent as decimal(5, 2)) as discount_percent,
        -- Calculate line totals
        cast(quantity * unit_price as decimal(10, 2)) as gross_amount,
        cast(quantity * unit_price * (1 - discount_percent / 100) as decimal(10, 2)) as net_amount,
        cast(quantity * unit_price * (discount_percent / 100) as decimal(10, 2)) as discount_amount
    from source
)

select * from calculated
```

### Run staging models:

```bash
dbt run --select staging
```

---

## Part 5: Building Intermediate Models

Intermediate models join and transform staging models. They're the "building blocks" for final marts.

### Create intermediate folder:

```
models/
├── intermediate/
│   ├── _int_models.yml
│   ├── int_orders_enriched.sql
│   └── int_customer_orders.sql
```

**models/intermediate/int_orders_enriched.sql**
```sql
-- Enriches orders with calculated totals and item counts

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
    case
        when ot.net_total >= 100 then 'high'
        when ot.net_total >= 50 then 'medium'
        else 'low'
    end as order_value_tier
from orders o
left join order_totals ot on o.order_id = ot.order_id
```

**models/intermediate/int_customer_orders.sql**
```sql
-- Aggregates order history per customer

with customers as (
    select * from {{ ref('stg_customers') }}
),

orders as (
    select * from {{ ref('int_orders_enriched') }}
),

customer_order_stats as (
    select
        customer_id,
        count(*) as total_orders,
        count(case when is_completed then 1 end) as completed_orders,
        count(case when order_status = 'cancelled' then 1 end) as cancelled_orders,
        count(case when order_status = 'returned' then 1 end) as returned_orders,
        sum(case when is_completed then net_total else 0 end) as lifetime_value,
        avg(case when is_completed then net_total end) as avg_order_value,
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
    -- Calculate days since last order (using current_date)
    current_date - cos.last_order_date as days_since_last_order
from customers c
left join customer_order_stats cos on c.customer_id = cos.customer_id
```

**models/intermediate/_int_models.yml**
```yaml
version: 2

models:
  - name: int_orders_enriched
    description: Orders enriched with line item totals and value tiers
    columns:
      - name: order_id
        description: Primary key
        tests:
          - unique
          - not_null

  - name: int_customer_orders
    description: Customer-level order aggregations
    columns:
      - name: customer_id
        description: Primary key
        tests:
          - unique
          - not_null
```

### Run intermediate models:

```bash
dbt run --select intermediate
```

---

## Part 6: Building Mart Models (Final Business Tables)

Marts are the final, business-ready tables that analysts and BI tools query directly.

### Create marts structure:

```
models/
├── marts/
│   ├── core/
│   │   ├── _core_models.yml
│   │   ├── dim_customers.sql
│   │   ├── dim_products.sql
│   │   └── fct_orders.sql
│   └── marketing/
│       ├── _marketing_models.yml
│       └── rpt_customer_segments.sql
```

**models/marts/core/dim_customers.sql**
```sql
-- Customer dimension table with segmentation

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
    
    -- Customer segments based on RFM-lite
    case
        when lifetime_value >= 200 and total_orders >= 3 then 'VIP'
        when lifetime_value >= 100 or total_orders >= 2 then 'Regular'
        when total_orders = 1 then 'New'
        else 'Prospect'
    end as customer_segment,
    
    -- Activity status
    case
        when days_since_last_order <= 30 then 'Active'
        when days_since_last_order <= 90 then 'At Risk'
        when days_since_last_order <= 180 then 'Dormant'
        when days_since_last_order > 180 then 'Churned'
        else 'Never Purchased'
    end as activity_status,
    
    current_timestamp as updated_at

from customer_orders
```

**models/marts/core/dim_products.sql**
```sql
-- Product dimension with sales metrics

with products as (
    select * from {{ ref('stg_products') }}
),

order_items as (
    select * from {{ ref('stg_order_items') }}
),

product_sales as (
    select
        product_id,
        count(distinct order_id) as times_ordered,
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
    coalesce(ps.times_ordered, 0) as times_ordered,
    coalesce(ps.total_units_sold, 0) as total_units_sold,
    coalesce(ps.total_revenue, 0) as total_revenue,
    
    -- Product performance tier
    case
        when ps.total_revenue >= 200 then 'Top Performer'
        when ps.total_revenue >= 100 then 'Good Performer'
        when ps.total_revenue > 0 then 'Low Performer'
        else 'No Sales'
    end as performance_tier,
    
    current_timestamp as updated_at

from products p
left join product_sales ps on p.product_id = ps.product_id
```

**models/marts/core/fct_orders.sql**
```sql
-- Fact table for orders (the grain is one row per order)

with orders as (
    select * from {{ ref('int_orders_enriched') }}
),

customers as (
    select 
        customer_id,
        customer_segment,
        country
    from {{ ref('dim_customers') }}
)

select
    -- Keys
    o.order_id,
    o.customer_id,
    
    -- Dates (for joining to date dimension if you have one)
    o.order_date,
    
    -- Order attributes
    o.order_status,
    o.shipping_method,
    o.is_completed,
    o.order_value_tier,
    
    -- Measures
    o.total_line_items,
    o.total_units,
    o.gross_total,
    o.total_discount,
    o.net_total,
    
    -- Denormalized customer attributes (for easier analysis)
    c.customer_segment,
    c.country as customer_country,
    
    current_timestamp as updated_at

from orders o
left join customers c on o.customer_id = c.customer_id
```

**models/marts/marketing/rpt_customer_segments.sql**
```sql
-- Marketing report: Customer segment analysis

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
order by 
    customer_segment,
    activity_status,
    country
```

### YAML documentation:

**models/marts/core/_core_models.yml**
```yaml
version: 2

models:
  - name: dim_customers
    description: Customer dimension with segmentation and lifetime metrics
    columns:
      - name: customer_id
        description: Primary key
        tests:
          - unique
          - not_null
      - name: customer_segment
        description: "Customer value segment: VIP, Regular, New, or Prospect"
        tests:
          - accepted_values:
              values: ['VIP', 'Regular', 'New', 'Prospect']
      - name: activity_status
        tests:
          - accepted_values:
              values: ['Active', 'At Risk', 'Dormant', 'Churned', 'Never Purchased']

  - name: dim_products
    description: Product dimension with sales performance metrics
    columns:
      - name: product_id
        tests:
          - unique
          - not_null
      - name: price
        tests:
          - not_null
      - name: profit_margin
        description: Price minus cost

  - name: fct_orders
    description: Order fact table at order grain
    columns:
      - name: order_id
        tests:
          - unique
          - not_null
      - name: net_total
        description: Order total after discounts
        tests:
          - not_null
```

### Run everything:

```bash
dbt run
```

---

## Part 7: Testing Your Data

dbt has built-in tests and supports custom tests.

### Built-in tests (already in YAML files above):
- `unique` - No duplicate values
- `not_null` - No NULL values
- `accepted_values` - Values must be in a list
- `relationships` - Foreign key integrity

### Create a custom singular test:

**tests/assert_no_negative_order_totals.sql**
```sql
-- This test fails if any rows are returned

select
    order_id,
    net_total
from {{ ref('fct_orders') }}
where net_total < 0
```

### Create a custom generic test:

**macros/test_positive_value.sql**
```sql
{% test positive_value(model, column_name) %}

select
    {{ column_name }}
from {{ model }}
where {{ column_name }} < 0

{% endtest %}
```

Use it in YAML:
```yaml
columns:
  - name: price
    tests:
      - positive_value
```

### Run tests:

```bash
# Run all tests
dbt test

# Run tests for specific model
dbt test --select fct_orders

# Run tests and build together
dbt build  # This runs seeds, models, snapshots, AND tests
```

---

## Part 8: Snapshots (SCD Type 2)

Snapshots track historical changes. Perfect for slowly changing dimensions.

**snapshots/customers_snapshot.sql**
```sql
{% snapshot customers_snapshot %}

{{
    config(
        target_schema='snapshots',
        unique_key='customer_id',
        strategy='check',
        check_cols=['email', 'country'],
    )
}}

select * from {{ ref('stg_customers') }}

{% endsnapshot %}
```

This creates a table that tracks every change to email or country, with `dbt_valid_from` and `dbt_valid_to` columns.

### Run snapshots:

```bash
dbt snapshot
```

---

## Part 9: Macros and Jinja

Macros are reusable SQL snippets using Jinja templating.

### Example 1: Generate surrogate keys

**macros/generate_surrogate_key.sql**
```sql
{% macro generate_surrogate_key(columns) %}
    {{ dbt_utils.generate_surrogate_key(columns) }}
{% endmacro %}
```

### Example 2: Cents to dollars conversion

**macros/cents_to_dollars.sql**
```sql
{% macro cents_to_dollars(column_name, decimal_places=2) %}
    round(cast({{ column_name }} as decimal(18, 4)) / 100, {{ decimal_places }})
{% endmacro %}
```

Usage:
```sql
select
    order_id,
    {{ cents_to_dollars('amount_cents') }} as amount_dollars
from orders
```

### Example 3: Dynamic date spine

**macros/date_spine.sql**
```sql
{% macro get_date_range(start_date, end_date) %}

    {% set date_query %}
        select 
            generate_series(
                '{{ start_date }}'::date,
                '{{ end_date }}'::date,
                '1 day'::interval
            )::date as date_day
    {% endset %}
    
    {{ return(date_query) }}

{% endmacro %}
```

### Example 4: Environment-aware configuration

**macros/limit_data_in_dev.sql**
```sql
{% macro limit_data_in_dev(column_name, days=3) %}

{% if target.name == 'dev' %}
    where {{ column_name }} >= current_date - interval '{{ days }} days'
{% endif %}

{% endmacro %}
```

Usage:
```sql
select * from orders
{{ limit_data_in_dev('order_date', 7) }}
```

---

## Part 10: Using dbt Packages

Packages extend dbt with pre-built macros and models.

### Install packages

Create `packages.yml` in project root:

```yaml
packages:
  - package: dbt-labs/dbt_utils
    version: 1.1.1
  - package: calogica/dbt_expectations
    version: 0.10.1
  - package: dbt-labs/codegen
    version: 0.12.1
```

Install:
```bash
dbt deps
```

### Using dbt_utils

```sql
-- Generate surrogate keys
select
    {{ dbt_utils.generate_surrogate_key(['customer_id', 'order_id']) }} as order_customer_key,
    *
from {{ ref('fct_orders') }}

-- Pivot data
{{ dbt_utils.pivot(
    'category',
    dbt_utils.get_column_values(ref('dim_products'), 'category')
) }}

-- Date spine
{{ dbt_utils.date_spine(
    datepart="day",
    start_date="cast('2024-01-01' as date)",
    end_date="cast('2024-12-31' as date)"
) }}
```

### Using dbt_expectations (Great Expectations-style tests)

```yaml
models:
  - name: fct_orders
    tests:
      - dbt_expectations.expect_table_row_count_to_be_between:
          min_value: 1
          max_value: 1000000
    columns:
      - name: net_total
        tests:
          - dbt_expectations.expect_column_values_to_be_between:
              min_value: 0
              max_value: 10000
      - name: order_date
        tests:
          - dbt_expectations.expect_column_values_to_be_of_type:
              column_type: date
```

### Using codegen (auto-generate YAML)

```sql
-- Run this in dbt to generate YAML for a model
{{ codegen.generate_model_yaml(
    model_names=['dim_customers', 'fct_orders']
) }}
```

---

## Part 11: Documentation

### Add descriptions in YAML (already done above)

### Create a docs block for longer descriptions

**models/docs.md**
```markdown
{% docs customer_segment %}

Customer segments are calculated based on purchase behavior:

| Segment | Criteria |
|---------|----------|
| VIP | LTV >= $200 AND 3+ orders |
| Regular | LTV >= $100 OR 2+ orders |
| New | Exactly 1 order |
| Prospect | No orders |

{% enddocs %}
```

Reference it:
```yaml
columns:
  - name: customer_segment
    description: "{{ doc('customer_segment') }}"
```

### Generate and serve docs

```bash
dbt docs generate
dbt docs serve
```

Visit http://localhost:8080 to see your documentation site with data lineage!

---

## Part 12: Running dbt in Production

### Useful commands

```bash
# Full refresh (rebuild all tables)
dbt run --full-refresh

# Run specific models
dbt run --select dim_customers
dbt run --select +fct_orders  # fct_orders and all upstream
dbt run --select fct_orders+  # fct_orders and all downstream

# Run by folder
dbt run --select staging.*

# Run by tag
dbt run --select tag:daily

# Compile SQL without running (good for debugging)
dbt compile --select fct_orders

# Show the compiled SQL
cat target/compiled/techmart/models/marts/core/fct_orders.sql
```

### Add tags to models

In model file:
```sql
{{ config(tags=['daily', 'critical']) }}

select ...
```

Or in `dbt_project.yml`:
```yaml
models:
  techmart:
    marts:
      +tags: ['daily']
```

---

## Part 13: Project Checklist

Before deploying to production, ensure:

- [ ] All models have descriptions in YAML
- [ ] All primary keys have `unique` and `not_null` tests
- [ ] Foreign keys have `relationships` tests
- [ ] Critical columns have appropriate tests
- [ ] Staging models are views, marts are tables
- [ ] Documentation is generated and reviewed
- [ ] CI/CD pipeline runs `dbt build` on PRs

---

## Challenge Exercises

### Exercise 1: Add a Date Dimension
Create `dim_dates.sql` with columns for day, week, month, quarter, year, is_weekend, etc.

### Exercise 2: Add Product Category Analysis
Create `rpt_category_performance.sql` showing revenue, units sold, and profit by category.

### Exercise 3: Implement Incremental Models
Convert `fct_orders` to an incremental model that only processes new records:

```sql
{{
    config(
        materialized='incremental',
        unique_key='order_id'
    )
}}

select ...

{% if is_incremental() %}
where order_date > (select max(order_date) from {{ this }})
{% endif %}
```

### Exercise 4: Add a Cohort Analysis
Create a model showing customer retention by signup month cohort.

### Exercise 5: Build a Funnel
Track conversion from: Browse → Add to Cart → Purchase → Complete

---

## Resources for Further Learning

1. **Official dbt Documentation**: docs.getdbt.com
2. **dbt Discourse Community**: discourse.getdbt.com
3. **dbt Slack**: getdbt.com/community
4. **Analytics Engineering Roundup Newsletter**: Weekly dbt tips
5. **dbt YouTube Channel**: Tutorials and Coalesce conference talks

---

## Quick Reference

| Command | Purpose |
|---------|---------|
| `dbt debug` | Test connection |
| `dbt seed` | Load CSV files |
| `dbt run` | Execute models |
| `dbt test` | Run tests |
| `dbt build` | seed + run + test + snapshot |
| `dbt docs generate` | Create documentation |
| `dbt docs serve` | View documentation |
| `dbt compile` | Compile without running |
| `dbt deps` | Install packages |
| `dbt snapshot` | Run snapshots |
| `dbt clean` | Clear target folder |

---

**Happy modeling! 🎯**