{#
  mart_daily_staffing_trend: daily occupancy and staffing across the
  quarter, nationally ('All states') and per state. Ratios are computed
  from totals (hours / resident-days, census / beds).
#}

with d as (

    select
        daily.*,
        f.state
    from {{ ref('fct_daily_staffing') }} daily
    inner join {{ ref('dim_facility') }} f using (ccn)
    where daily.resident_census > 0

)

select
    work_date,
    coalesce(state, 'All states')                                         as state,
    max(is_weekend::int)::boolean                                         as is_weekend,
    count(*)                                                              as facilities_reporting,
    sum(resident_census)                                                  as total_residents,
    sum(resident_census) / nullif(sum(certified_beds), 0)                 as occupancy_rate,
    sum(licensed_nurse_hours) / nullif(sum(resident_census), 0)           as licensed_nurse_hprd,
    sum(total_nurse_hours) / nullif(sum(resident_census), 0)              as total_nurse_hprd,
    sum(licensed_nurse_contract_hours) / nullif(sum(licensed_nurse_hours), 0) as contract_licensed_share,
    to_varchar(work_date) || '|' || coalesce(state, 'All states')         as date_state_key
from d
group by grouping sets ((work_date, state), (work_date))
