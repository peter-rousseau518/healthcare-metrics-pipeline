{#
  mart_facility_staffing: one row per facility per quarter, from PBJ.

  Hours per resident day (HPRD) = total hours / total resident-days, the
  CMS method (not an average of daily ratios).

  "Overtime" question (ADR-024): PBJ reports hours per facility, not per
  nurse, so overtime over 40 hours per person cannot be computed. The
  ranking uses contract (agency) licensed-nurse hours per week, the closest
  public signal of hours staff could not cover, alongside weekend drop
  and turnover.

  is_valid_for_analysis excludes facilities with partial reporting or
  implausible values: fewer than 60 reported days, occupancy outside
  0-125%, or total nurse HPRD outside 0.5-12.
#}

with daily as (

    select * from {{ ref('fct_daily_staffing') }}

),

facility as (

    select * from {{ ref('dim_facility') }}

),

agg as (

    select
        ccn,
        calendar_quarter,
        count(*)                                                    as days_reported,
        min(work_date)                                              as period_start,
        max(work_date)                                              as period_end,
        avg(resident_census)                                        as avg_daily_census,
        sum(resident_census)                                        as resident_days,
        sum(rn_hours)                                               as rn_hours,
        sum(lpn_hours)                                              as lpn_hours,
        sum(licensed_nurse_hours)                                   as licensed_nurse_hours,
        sum(licensed_nurse_contract_hours)                          as licensed_nurse_contract_hours,
        sum(nurse_aide_hours)                                       as nurse_aide_hours,
        sum(total_nurse_hours)                                      as total_nurse_hours,
        sum(iff(is_weekend, licensed_nurse_hours, 0))               as weekend_licensed_hours,
        sum(iff(is_weekend, resident_census, 0))                    as weekend_resident_days,
        sum(iff(not is_weekend, licensed_nurse_hours, 0))           as weekday_licensed_hours,
        sum(iff(not is_weekend, resident_census, 0))                as weekday_resident_days
    from daily
    group by ccn, calendar_quarter

),

metrics as (

    select
        a.ccn,
        a.calendar_quarter,
        a.days_reported,
        a.period_start,
        a.period_end,

        -- occupancy
        a.avg_daily_census,
        f.certified_beds,
        a.avg_daily_census / nullif(f.certified_beds, 0)                        as occupancy_rate,

        -- staffing levels (hours per resident day)
        a.rn_hours / nullif(a.resident_days, 0)                                 as rn_hprd,
        a.lpn_hours / nullif(a.resident_days, 0)                                as lpn_hprd,
        a.licensed_nurse_hours / nullif(a.resident_days, 0)                     as licensed_nurse_hprd,
        a.nurse_aide_hours / nullif(a.resident_days, 0)                         as nurse_aide_hprd,
        a.total_nurse_hours / nullif(a.resident_days, 0)                        as total_nurse_hprd,

        -- workload and strain
        a.licensed_nurse_hours / a.days_reported * 7                            as licensed_nurse_hours_per_week,
        a.licensed_nurse_hours / a.days_reported * 7 / 40                       as licensed_nurse_fte_equivalent,
        a.licensed_nurse_contract_hours / a.days_reported * 7                   as contract_licensed_hours_per_week,
        a.licensed_nurse_contract_hours / nullif(a.licensed_nurse_hours, 0)     as contract_licensed_share,
        a.weekday_licensed_hours / nullif(a.weekday_resident_days, 0)           as weekday_licensed_hprd,
        a.weekend_licensed_hours / nullif(a.weekend_resident_days, 0)           as weekend_licensed_hprd,
        1 - (a.weekend_licensed_hours / nullif(a.weekend_resident_days, 0))
          / nullif(a.weekday_licensed_hours / nullif(a.weekday_resident_days, 0), 0) as weekend_licensed_drop_pct,
        f.total_nursing_turnover_pct,
        f.rn_turnover_pct,

        -- facility attributes for filtering
        f.provider_name,
        f.state,
        f.ownership_group,
        f.provider_type,
        f.facility_setting,
        f.is_chain_affiliated,
        f.overall_rating,
        f.staffing_rating

    from agg a
    inner join facility f using (ccn)

),

flagged as (

    select
        *,
        days_reported >= 60
            and occupancy_rate > 0 and occupancy_rate <= 1.25
            and total_nurse_hprd between 0.5 and 12                             as is_valid_for_analysis
    from metrics

)

select
    *,
    ccn || '-' || calendar_quarter                                              as facility_quarter_key,
    iff(is_valid_for_analysis,
        rank() over (partition by calendar_quarter, is_valid_for_analysis
                     order by contract_licensed_hours_per_week desc nulls last),
        null)                                                                   as contract_licensed_hours_rank
from flagged
