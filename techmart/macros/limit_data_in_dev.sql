{% macro limit_data_in_dev(column_name, days=3) %}

  {% if target.name == 'dev' %}
    {{ column_name }} >= current_date - interval '{{ days }} days'
  {% else %}
    1=1
  {% endif %}

{% endmacro %}
