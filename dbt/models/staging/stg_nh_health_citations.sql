{#
  stg_nh_health_citations
  Health inspection deficiencies: one row per citation.
  deficiency_tag_key joins to stg_nh_citation_descriptions.
  Conventions: see ADR-022.
#}

with source as (

    select * from {{ source('raw', 'nh_health_citations') }}

),

renamed as (

    select
        trim("CMS Certification Number (CCN)")                                               as ccn,
        try_to_date("Survey Date")                                                           as survey_date,
        nullif(trim("Survey Type"), '')                                                      as survey_type,
        nullif(trim("Deficiency Prefix"), '')                                                as deficiency_prefix,
        nullif(trim("Deficiency Category"), '')                                              as deficiency_category,
        nullif(trim("Deficiency Tag Number"), '')                                            as deficiency_tag_number,
        nullif(trim("Deficiency Description"), '')                                           as deficiency_description,
        nullif(trim("Scope Severity Code"), '')                                              as scope_severity_code,
        nullif(trim("Deficiency Corrected"), '')                                             as correction_status,
        try_to_date("Correction Date")                                                       as correction_date,
        try_to_number("Inspection Cycle")                                                    as inspection_cycle,
        try_to_boolean("Standard Deficiency")                                                as is_standard_deficiency,
        try_to_boolean("Complaint Deficiency")                                               as is_complaint_deficiency,
        try_to_boolean("Infection Control Inspection Deficiency")                            as is_infection_control_deficiency,
        try_to_boolean("Citation under IDR")                                                 as is_under_idr,
        try_to_boolean("Citation under IIDR")                                                as is_under_iidr,
        "Deficiency Prefix" || lpad(try_to_number("Deficiency Tag Number")::varchar, 4, '0') as deficiency_tag_key,

        -- Dropped (available in stg_nh_provider_info or via release):
        -- Provider Name, Provider Address, City/Town, State, ZIP Code, Location, Processing Date

        -- lineage
        {{ release_from_source_file() }} as release,
        _source_file as source_file,
        _loaded_at   as loaded_at

    from source

)

select * from renamed
qualify release = max(release) over ()
