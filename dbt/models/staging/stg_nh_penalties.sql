{#
  stg_nh_penalties
  Civil money penalties (fines) and payment denials: many rows per facility.
  Conventions: see ADR-022.
#}

with source as (

    select * from {{ source('raw', 'nh_penalties') }}

),

renamed as (

    select
        trim("CMS Certification Number (CCN)")                                   as ccn,
        try_to_date("Penalty Date")                                              as penalty_date,
        nullif(trim("Penalty Type"), '')                                         as penalty_type,
        try_to_decimal(replace(replace("Fine Amount", '$', ''), ',', ''), 14, 2) as fine_amount_usd,
        try_to_date("Payment Denial Start Date")                                 as payment_denial_start_date,
        try_to_number("Payment Denial Length in Days")                           as payment_denial_days,

        -- Dropped (available in stg_nh_provider_info or via release):
        -- Provider Name, Provider Address, City/Town, State, ZIP Code, Location, Processing Date

        -- lineage
        {{ release_from_source_file() }} as release,
        _source_file as source_file,
        _loaded_at   as loaded_at

    from source

)

select * from renamed
qualify release = max(release) over ()
