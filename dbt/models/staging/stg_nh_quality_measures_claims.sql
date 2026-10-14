{#
  stg_nh_quality_measures_claims
  Claims-based quality measures: one row per facility per measure.
  Conventions: see ADR-022.
#}

with source as (

    select * from {{ source('raw', 'nh_quality_measures_claims') }}

),

renamed as (

    select
        trim("CMS Certification Number (CCN)")                                as ccn,
        nullif(trim("Measure Code"), '')                                      as measure_code,
        nullif(trim("Measure Description"), '')                               as measure_description,
        nullif(trim("Resident type"), '')                                     as resident_type,
        try_to_decimal("Adjusted Score", 14, 6)                               as adjusted_score,
        try_to_decimal("Observed Score", 14, 6)                               as observed_score,
        try_to_decimal("Expected Score", 14, 6)                               as expected_score,
        nullif(trim("Footnote for Score"), '')                                as score_footnote,
        try_to_boolean("Used in Quality Measure Five Star Rating")            as is_used_in_five_star,
        nullif(trim("Measure Period"), '')                                    as measure_period,
        trim("CMS Certification Number (CCN)") || '-' || trim("Measure Code") as facility_measure_key,

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
