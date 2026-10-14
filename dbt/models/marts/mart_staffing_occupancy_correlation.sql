{#
  mart_staffing_occupancy_correlation: answers "What is the relationship
  between nurse staffing levels and occupancy rates?"
  Pearson correlation across valid facilities, nationally ('All states')
  and per state. Values near 0 = no linear relationship; negative = higher
  occupancy goes with fewer nurse hours per resident.
#}

with f as (

    select * from {{ ref('mart_facility_staffing') }}
    where is_valid_for_analysis

)

select
    calendar_quarter,
    coalesce(state, 'All states')                         as state,
    count(*)                                              as facility_count,
    avg(occupancy_rate)                                   as avg_occupancy_rate,
    avg(licensed_nurse_hprd)                              as avg_licensed_nurse_hprd,
    avg(total_nurse_hprd)                                 as avg_total_nurse_hprd,
    corr(occupancy_rate, licensed_nurse_hprd)             as corr_occupancy_licensed_hprd,
    corr(occupancy_rate, rn_hprd)                         as corr_occupancy_rn_hprd,
    corr(occupancy_rate, total_nurse_hprd)                as corr_occupancy_total_hprd,
    calendar_quarter || '|' || coalesce(state, 'All states') as correlation_key
from f
group by grouping sets ((calendar_quarter, state), (calendar_quarter))
