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