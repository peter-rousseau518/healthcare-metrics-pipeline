{#
  stg_snf_vbp_facility_performance
  SNF Value-Based Purchasing results: one row per scored facility.
  Readmission-rate headers name specific fiscal years (baseline FY 2019,
  performance FY 2022 in this release); columns use period-neutral names.
  Conventions: see ADR-022.
#}

with source as (

    select * from {{ source('raw', 'snf_vbp_facility_performance') }}

),

renamed as (

    select
        trim("CMS Certification Number (CCN)")                                                         as ccn,
        try_to_number("SNF VBP Program Ranking")                                                       as vbp_ranking,
        nullif(trim("Footnote -- SNF VBP Program Ranking"), '')                                        as vbp_ranking_footnote,
        try_to_decimal("Baseline Period: FY 2019 Risk-Standardized Readmission Rate", 14, 8)           as baseline_readmission_rate,
        nullif(trim("Footnote -- Baseline Period: FY 2019 Risk-Standardized Readmission Rate"), '')    as baseline_readmission_rate_footnote,
        try_to_decimal("Performance Period: FY 2022 Risk-Standardized Readmission Rate", 14, 8)        as performance_readmission_rate,
        nullif(trim("Footnote -- Performance Period: FY 2022 Risk-Standardized Readmission Rate"), '') as performance_readmission_rate_footnote,
        try_to_decimal("Achievement Score", 14, 6)                                                     as achievement_score,
        nullif(trim("Footnote -- Achievement Score"), '')                                              as achievement_score_footnote,
        try_to_decimal("Improvement Score", 14, 6)                                                     as improvement_score,
        nullif(trim("Footnote -- Improvement Score"), '')                                              as improvement_score_footnote,
        try_to_decimal("Performance Score", 14, 6)                                                     as performance_score,
        nullif(trim("Footnote -- Performance Score"), '')                                              as performance_score_footnote,
        try_to_decimal("Incentive Payment Multiplier", 16, 12)                                         as incentive_payment_multiplier,
        nullif(trim("Footnote -- Incentive Payment Multiplier"), '')                                   as incentive_payment_multiplier_footnote,

        -- Dropped (available in stg_nh_provider_info or via release):
        -- Provider Name, Provider Address, City/Town, State, ZIP Code

        -- lineage
        {{ release_from_source_file() }} as release,
        _source_file as source_file,
        _loaded_at   as loaded_at

    from source

)

select * from renamed
qualify release = max(release) over ()
