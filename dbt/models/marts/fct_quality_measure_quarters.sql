{#
  fct_quality_measure_quarters: MDS quality measure scores unpivoted to one
  row per facility, measure, and quarter (Q1-Q4 of the measure period).
  quarter_start is derived from measure_period when it is in YYYYMMDD-YYYYMMDD
  form; quarter_number is always present.
#}

with mds as (

    select * from {{ ref('stg_nh_quality_measures_mds') }}

),

unpivoted as (

    select ccn, measure_code, resident_type, measure_period, facility_measure_key, 1 as quarter_number, q1_score as score, q1_score_footnote as score_footnote from mds
    union all
    select ccn, measure_code, resident_type, measure_period, facility_measure_key, 2, q2_score, q2_score_footnote from mds
    union all
    select ccn, measure_code, resident_type, measure_period, facility_measure_key, 3, q3_score, q3_score_footnote from mds
    union all
    select ccn, measure_code, resident_type, measure_period, facility_measure_key, 4, q4_score, q4_score_footnote from mds

)

select
    facility_measure_key || '-Q' || quarter_number                                   as facility_measure_quarter_key,
    ccn,
    measure_code,
    resident_type,
    measure_period,
    quarter_number,
    dateadd(quarter, quarter_number - 1,
            try_to_date(split_part(measure_period, '-', 1), 'YYYYMMDD'))             as quarter_start,
    score,
    score_footnote
from unpivoted
