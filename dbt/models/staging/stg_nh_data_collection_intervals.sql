with source as (

    select * from {{ source('raw', 'nh_data_collection_intervals') }}

),

renamed as (

    select
         nullif(trim("Measure Code"), '')                                   as measure_code
        ,nullif(trim("Measure Description"), '')                            as measure_description
        ,try_to_date("Data Collection Period From Date", 'MM/DD/YYYY')      as data_collection_period_from_date
        ,try_to_date("Data Collection Period Through Date", 'MM/DD/YYYY')   as data_collection_period_through_date
        ,nullif(trim("Measure Date Range"), '')                             as measure_date_range
        ,try_to_date("Processing Date", 'YYYYMMDD')                         as processing_date

        -- lineage
        ,{{ release_from_source_file() }} as release
        ,_source_file as source_file
        ,_loaded_at   as loaded_at

    from source

)

select * from renamed
qualify release = max(release) over ()
