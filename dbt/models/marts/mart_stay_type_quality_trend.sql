{#
  mart_stay_type_quality_trend: answers the length-of-stay question with
  the closest available data (ADR-024). The dataset has no length-of-stay
  field; this trends quality measure scores for short-stay vs long-stay
  residents across the four quarters of the measure period, nationally.
#}

with q as (

    select * from {{ ref('fct_quality_measure_quarters') }}
    where score is not null

),

m as (

    select * from {{ ref('dim_measure') }}

)

select
    m.resident_type,
    q.measure_code,
    m.measure_description,
    q.quarter_number,
    min(q.quarter_start)                    as quarter_start,
    count(*)                                as facility_count,
    avg(q.score)                            as avg_score,
    median(q.score)                         as median_score,
    q.measure_code || '-Q' || q.quarter_number as measure_quarter_key
from q
inner join m using (measure_code)
group by m.resident_type, q.measure_code, m.measure_description, q.quarter_number
