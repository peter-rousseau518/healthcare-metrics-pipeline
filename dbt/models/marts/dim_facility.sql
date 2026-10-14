{#
  dim_facility: one row per nursing home in the latest Care Compare release.
  Adds the three "facility type" groupings used across the dashboard
  (ADR-024): ownership_group, provider_type, facility_setting.
#}

select
    ccn,
    provider_name,
    city,
    state,
    county,
    zip_code,
    latitude,
    longitude,

    -- facility type, three ways
    ownership_type,
    case
        when ownership_type ilike 'For profit%' then 'For profit'
        when ownership_type ilike 'Non profit%' then 'Nonprofit'
        when ownership_type ilike 'Government%' then 'Government'
        else 'Other'
    end                                                        as ownership_group,
    coalesce(provider_type, 'Unknown')                         as provider_type,
    case
        when is_in_hospital then 'Hospital-based'
        when not is_in_hospital then 'Freestanding'
        else 'Unknown'
    end                                                        as facility_setting,

    -- size and affiliation
    certified_beds,
    case
        when certified_beds < 50  then '1-49'
        when certified_beds < 100 then '50-99'
        when certified_beds < 150 then '100-149'
        when certified_beds < 200 then '150-199'
        else '200+'
    end                                                        as bed_size_band,
    affiliated_entity_name,
    affiliated_entity_id,
    affiliated_entity_name is not null                         as is_chain_affiliated,

    -- ratings
    overall_rating,
    health_inspection_rating,
    qm_rating,
    staffing_rating,

    -- Care Compare staffing and occupancy (quarterly averages, for reference)
    avg_residents_per_day,
    avg_residents_per_day / nullif(certified_beds, 0)          as care_compare_occupancy_rate,
    reported_rn_hprd,
    reported_lpn_hprd,
    reported_total_nurse_hprd,
    adjusted_total_nurse_hprd,
    weekend_total_nurse_hprd,
    total_nursing_turnover_pct,
    rn_turnover_pct,

    -- enforcement
    fines_total_usd,
    penalties_total_count,

    release

from {{ ref('stg_nh_provider_info') }}
