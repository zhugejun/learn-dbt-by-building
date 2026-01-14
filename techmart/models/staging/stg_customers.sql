with source as (
    select *
    from {{ source('raw', 'raw_customers') }}
),

renamed as (
    select
        customer_id,
        first_name,
        last_name,
        country,
        cast(created_at as date) as customer_created_at,
        first_name || ' ' || last_name as full_name,
        lower(email) as email
    from source
)

select * from renamed
