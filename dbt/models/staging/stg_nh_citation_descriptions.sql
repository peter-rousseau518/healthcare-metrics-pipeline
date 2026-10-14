{#
  stg_nh_citation_descriptions
  Lookup of CMS deficiency tags: one row per tag.
  Conventions: see ADR-022.
#}

with source as (

    select * from {{ source('raw', 'nh_citation_descriptions') }}

),

renamed as (

    select
        nullif(trim("Deficiency Prefix"), '')                                                as deficiency_prefix,
        nullif(trim("Deficiency Tag Number"), '')                                            as deficiency_tag_number,
        nullif(trim("Deficiency Prefix and Number"), '')                                     as deficiency_prefix_and_number,
        nullif(trim("Deficiency Description"), '')                                           as deficiency_description,
        nullif(trim("Deficiency Category"), '')                                              as deficiency_category,
        "Deficiency Prefix" || lpad(try_to_number("Deficiency Tag Number")::varchar, 4, '0') as deficiency_tag_key,

        -- lineage
        {{ release_from_source_file() }} as release,
        _source_file as source_file,
        _loaded_at   as loaded_at

    from source

)

select * from renamed
qualify release = max(release) over ()
