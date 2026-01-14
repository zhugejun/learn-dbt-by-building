-- date dimension table
with date_spine as (
  {{ dbt_utils.date_spine(
      datepart="day",
      start_date="cast('2020-01-01' as date)",
      end_date="cast('2030-12-31' as date)"
  ) }}
),

dates as (
  select
    cast(date_day as date) as date_day
  from date_spine
)

select
  -- primary key
  cast(strftime(date_day, '%Y%m%d') as integer) as date_key,
  date_day,

  -- day attributes
  dayofweek(date_day) as day_of_week,
  dayname(date_day) as day_name,
  day(date_day) as day_of_month,
  dayofyear(date_day) as day_of_year,

  -- week attributes
  week(date_day) as week_of_year,
  yearweek(date_day) as year_week,

  -- month attributes
  month(date_day) as month_number,
  monthname(date_day) as month_name,
  date_trunc('month', date_day) as first_day_of_month,
  last_day(date_day) as last_day_of_month,

  -- quarter attributes
  quarter(date_day) as quarter_number,
  'Q' || quarter(date_day) as quarter_name,
  date_trunc('quarter', date_day) as first_day_of_quarter,

  -- year attributes
  year(date_day) as year_number,
  date_trunc('year', date_day) as first_day_of_year,

  -- flags
  case when dayofweek(date_day) in (0, 6) then true else false end as is_weekend,
  case when dayofweek(date_day) not in (0, 6) then true else false end as is_weekday,
  case when day(date_day) = 1 then true else false end as is_month_start,
  case when date_day = last_day(date_day) then true else false end as is_month_end,

  -- relative date flags (useful for filtering)
  case when date_day = current_date then true else false end as is_today,
  case when date_day = current_date - interval '1 day' then true else false end as is_yesterday,
  current_date - date_day as days_ago

from dates
