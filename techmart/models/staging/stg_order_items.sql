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