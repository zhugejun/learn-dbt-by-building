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