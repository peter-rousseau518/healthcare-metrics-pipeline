{#
  fct_daily_staffing: one row per facility per day, from PBJ.
  Rolls PBJ's eight role columns into three nursing groups (ADR-024):
    RN            = RN director of nursing + RN admin + RN
    LPN           = LPN admin + LPN
    nurse aide    = CNA + nurse aide in training + medication aide
  Licensed nurse = RN + LPN. Contract hours are agency/contract staff.
  Inner join to dim_facility drops the 17 PBJ facilities absent from the
  current provider list (1,547 facility-days, about 0.1%).
#}

with pbj as (

    select * from {{ ref('stg_pbj_daily_nurse_staffing') }}

),

facility as (

    select ccn, certified_beds from {{ ref('dim_facility') }}

),

hours as (

    select
        facility_day_key,
        ccn,
        work_date,
        calendar_quarter,
        resident_census,

        coalesce(rn_don_hours, 0) + coalesce(rn_admin_hours, 0) + coalesce(rn_hours, 0)             as rn_hours,
        coalesce(rn_don_ctr_hours, 0) + coalesce(rn_admin_ctr_hours, 0) + coalesce(rn_ctr_hours, 0) as rn_contract_hours,
        coalesce(lpn_admin_hours, 0) + coalesce(lpn_hours, 0)                                      as lpn_hours,
        coalesce(lpn_admin_ctr_hours, 0) + coalesce(lpn_ctr_hours, 0)                              as lpn_contract_hours,
        coalesce(cna_hours, 0) + coalesce(na_trainee_hours, 0) + coalesce(med_aide_hours, 0)       as nurse_aide_hours,
        coalesce(cna_ctr_hours, 0) + coalesce(na_trainee_ctr_hours, 0) + coalesce(med_aide_ctr_hours, 0) as nurse_aide_contract_hours

    from pbj

)

select
    h.facility_day_key,
    h.ccn,
    h.work_date,
    h.calendar_quarter,
    dayofweekiso(h.work_date) in (6, 7)                               as is_weekend,
    h.resident_census,
    f.certified_beds,
    h.resident_census / nullif(f.certified_beds, 0)                   as occupancy_rate,

    h.rn_hours,
    h.rn_contract_hours,
    h.lpn_hours,
    h.lpn_contract_hours,
    h.rn_hours + h.lpn_hours                                          as licensed_nurse_hours,
    h.rn_contract_hours + h.lpn_contract_hours                        as licensed_nurse_contract_hours,
    h.nurse_aide_hours,
    h.nurse_aide_contract_hours,
    h.rn_hours + h.lpn_hours + h.nurse_aide_hours                     as total_nurse_hours

from hours h
inner join facility f using (ccn)
