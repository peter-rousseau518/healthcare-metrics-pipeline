{#
  stg_pbj_daily_nurse_staffing
  CMS Payroll-Based Journal: nurse staffing hours and resident census,
  one row per facility per day.

  - Hours by role: RN director of nursing, RN admin, RN, LPN admin, LPN,
    CNA, nurse aide in training, medication aide. Each role has a total,
    an employee (_emp) and a contract/agency (_ctr) figure.
  - ccn is left-padded to 6 characters so it joins to stg_nh_provider_info.
  - Unlike Care Compare models, ALL quarters are kept: PBJ is a time series.
  - Facility name, city, state, and county are dropped; they live in
    stg_nh_provider_info.
  Conventions: see ADR-022, ADR-023.
#}

with source as (

    select * from {{ source('raw', 'pbj_daily_nurse_staffing') }}

),

renamed as (

    select
        lpad(trim("PROVNUM"), 6, '0')                            as ccn,
        try_to_date("WorkDate", 'YYYYMMDD')                      as work_date,
        nullif(trim("CY_Qtr"), '')                               as calendar_quarter,
        try_to_number("MDScensus")                               as resident_census,
        try_to_decimal("Hrs_RNDON", 12, 2)                       as rn_don_hours,
        try_to_decimal("Hrs_RNDON_emp", 12, 2)                   as rn_don_emp_hours,
        try_to_decimal("Hrs_RNDON_ctr", 12, 2)                   as rn_don_ctr_hours,
        try_to_decimal("Hrs_RNadmin", 12, 2)                     as rn_admin_hours,
        try_to_decimal("Hrs_RNadmin_emp", 12, 2)                 as rn_admin_emp_hours,
        try_to_decimal("Hrs_RNadmin_ctr", 12, 2)                 as rn_admin_ctr_hours,
        try_to_decimal("Hrs_RN", 12, 2)                          as rn_hours,
        try_to_decimal("Hrs_RN_emp", 12, 2)                      as rn_emp_hours,
        try_to_decimal("Hrs_RN_ctr", 12, 2)                      as rn_ctr_hours,
        try_to_decimal("Hrs_LPNadmin", 12, 2)                    as lpn_admin_hours,
        try_to_decimal("Hrs_LPNadmin_emp", 12, 2)                as lpn_admin_emp_hours,
        try_to_decimal("Hrs_LPNadmin_ctr", 12, 2)                as lpn_admin_ctr_hours,
        try_to_decimal("Hrs_LPN", 12, 2)                         as lpn_hours,
        try_to_decimal("Hrs_LPN_emp", 12, 2)                     as lpn_emp_hours,
        try_to_decimal("Hrs_LPN_ctr", 12, 2)                     as lpn_ctr_hours,
        try_to_decimal("Hrs_CNA", 12, 2)                         as cna_hours,
        try_to_decimal("Hrs_CNA_emp", 12, 2)                     as cna_emp_hours,
        try_to_decimal("Hrs_CNA_ctr", 12, 2)                     as cna_ctr_hours,
        try_to_decimal("Hrs_NAtrn", 12, 2)                       as na_trainee_hours,
        try_to_decimal("Hrs_NAtrn_emp", 12, 2)                   as na_trainee_emp_hours,
        try_to_decimal("Hrs_NAtrn_ctr", 12, 2)                   as na_trainee_ctr_hours,
        try_to_decimal("Hrs_MedAide", 12, 2)                     as med_aide_hours,
        try_to_decimal("Hrs_MedAide_emp", 12, 2)                 as med_aide_emp_hours,
        try_to_decimal("Hrs_MedAide_ctr", 12, 2)                 as med_aide_ctr_hours,
        lpad(trim("PROVNUM"), 6, '0') || '-' || trim("WorkDate") as facility_day_key,

        -- lineage
        _source_file as source_file,
        _loaded_at   as loaded_at

    from source

)

select * from renamed
