{#
  dim_measure: one row per CMS quality measure, MDS and claims-based.
  resident_type separates short-stay from long-stay measures.
#}

with mds as (

    select measure_code, measure_description, resident_type,
           is_used_in_five_star, 'MDS' as measure_source
    from {{ ref('stg_nh_quality_measures_mds') }}

),

claims as (

    select measure_code, measure_description, resident_type,
           is_used_in_five_star, 'Claims' as measure_source
    from {{ ref('stg_nh_quality_measures_claims') }}

),

all_measures as (

    select * from mds
    union all
    select * from claims

)

select
    measure_code,
    any_value(measure_description)        as measure_description,
    any_value(resident_type)              as resident_type,
    any_value(measure_source)             as measure_source,
    boolor_agg(coalesce(is_used_in_five_star, false)) as is_used_in_five_star
from all_measures
group by measure_code
