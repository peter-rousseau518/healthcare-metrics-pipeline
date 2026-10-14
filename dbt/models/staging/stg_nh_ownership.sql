{#
  stg_nh_ownership
  Owners and managing parties: many rows per facility.
  ownership_percentage is numeric when CMS reports a number;
  ownership_percentage_text keeps the original wording.
  Conventions: see ADR-022.
#}

with source as (

    select * from {{ source('raw', 'nh_ownership') }}

),

renamed as (

    select
        trim("CMS Certification Number (CCN)")                                 as ccn,
        nullif(trim("Role played by Owner or Manager in Facility"), '')        as owner_role,
        nullif(trim("Owner Type"), '')                                         as owner_type,
        nullif(trim("Owner Name"), '')                                         as owner_name,
        try_to_decimal(replace("Ownership Percentage", '%', ''), 9, 4)         as ownership_percentage,
        nullif(trim("Ownership Percentage"), '')                               as ownership_percentage_text,
        try_to_date(trim(regexp_replace("Association Date", '^[Ss]ince', ''))) as association_date,
        nullif(trim("Association Date"), '')                                   as association_date_text,

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
