{#
  mart_staffing_by_state_and_type: answers "What are the average staffing
  levels by state and by facility type?"
  Facility type is offered three ways (facility_type_dimension):
    Ownership type | Provider type | Facility setting
  Averages are across facilities (each facility counts once), valid
  facilities only. state = 'All states' gives the national figure.
#}

with base as (

    select * from {{ ref('mart_facility_staffing') }}
    where is_valid_for_analysis

),

long as (

    select calendar_quarter, state, 'Ownership type'   as facility_type_dimension, ownership_group  as facility_type,
           rn_hprd, lpn_hprd, licensed_nurse_hprd, total_nurse_hprd, occupancy_rate from base
    union all
    select calendar_quarter, state, 'Provider type',   provider_type,
           rn_hprd, lpn_hprd, licensed_nurse_hprd, total_nurse_hprd, occupancy_rate from base
    union all
    select calendar_quarter, state, 'Facility setting', facility_setting,
           rn_hprd, lpn_hprd, licensed_nurse_hprd, total_nurse_hprd, occupancy_rate from base

)

select
    calendar_quarter,
    coalesce(state, 'All states')                         as state,
    facility_type_dimension,
    facility_type,
    count(*)                                              as facility_count,
    avg(rn_hprd)                                          as avg_rn_hprd,
    avg(lpn_hprd)                                         as avg_lpn_hprd,
    avg(licensed_nurse_hprd)                              as avg_licensed_nurse_hprd,
    avg(total_nurse_hprd)                                 as avg_total_nurse_hprd,
    avg(occupancy_rate)                                   as avg_occupancy_rate,
    calendar_quarter || '|' || coalesce(state, 'All states') || '|'
        || facility_type_dimension || '|' || facility_type as state_type_key
from long
group by grouping sets (
    (calendar_quarter, state, facility_type_dimension, facility_type),
    (calendar_quarter, facility_type_dimension, facility_type)
)
