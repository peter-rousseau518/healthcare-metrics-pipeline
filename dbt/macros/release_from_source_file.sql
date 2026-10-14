{#
  Data release (YYYY-MM) parsed from a raw row's S3 path, e.g.
  cms_nursing_home/release=2024-10/NH_ProviderInfo_Oct2024.csv -> 2024-10
#}
{% macro release_from_source_file(column='_source_file') -%}
    regexp_substr({{ column }}, 'release=([0-9]{4}-[0-9]{2})', 1, 1, 'e', 1)
{%- endmacro %}
