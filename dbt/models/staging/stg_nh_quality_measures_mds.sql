{#
  stg_nh_quality_measures_mds
  MDS-based quality measures: one row per facility per measure,
  with quarterly scores and a four-quarter average.
  Conventions: see ADR-022.
#}

with source as (

    select * from {{ source('raw', 'nh_quality_measures_mds') }}

),

renamed as (

    select
        trim("CMS Certification Number (CCN)")                                as ccn,
        nullif(trim("Measure Code"), '')                                      as measure_code,
        nullif(trim("Measure Description"), '')                               as measure_description,
        nullif(trim("Resident type"), '')                                     as resident_type,
        try_to_decimal("Q1 Measure Score", 14, 6)                             as q1_score,
        nullif(trim("Footnote for Q1 Measure Score"), '')                     as q1_score_footnote,
        try_to_decimal("Q2 Measure Score", 14, 6)                             as q2_score,
        nullif(trim("Footnote for Q2 Measure Score"), '')                     as q2_score_footnote,
        try_to_decimal("Q3 Measure Score", 14, 6)                             as q3_score,
        nullif(trim("Footnote for Q3 Measure Score"), '')                     as q3_score_footnote,
        try_to_decimal("Q4 Measure Score", 14, 6)                             as q4_score,
        nullif(trim("Footnote for Q4 Measure Score"), '')                     as q4_score_footnote,
        try_to_decimal("Four Quarter Average Score", 14, 6)                   as four_quarter_avg_score,
        nullif(trim("Footnote for Four Quarter Average Score"), '')           as four_quarter_avg_footnote,
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
