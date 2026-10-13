{#
  Write models to the schema named in dbt_project.yml (staging, marts)
  instead of dbt's default <target_schema>_<custom_schema>, so objects
  land in healthcare.staging and healthcare.marts exactly.
#}
{% macro generate_schema_name(custom_schema_name, node) -%}
    {%- if custom_schema_name is none -%}
        {{ target.schema }}
    {%- else -%}
        {{ custom_schema_name | trim }}
    {%- endif -%}
{%- endmacro %}
