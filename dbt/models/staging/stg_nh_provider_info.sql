{#
  stg_nh_provider_info
  One row per certified nursing home, from the latest CMS release in raw.

  Conventions (see ADR-022):
  - Columns renamed from CMS headers to snake_case
  - Types cast with TRY_ functions: a value that cannot be converted becomes
    NULL instead of failing the build; data tests watch the key columns
  - Y/N flags become booleans
  - Placeholders found in profiling become NULL (phone 0000001111, county 000)
  - Footnote columns stay as text codes; they explain why a measure is
    missing or adjusted (see docs/profiling_findings.md)
#}

with source as (

    select * from {{ source('raw', 'nh_provider_info') }}

),

renamed as (

    select
        trim("CMS Certification Number (CCN)")                                                         as ccn,
        nullif(trim("Provider Name"), '')                                                              as provider_name,
        nullif(trim("Provider Address"), '')                                                           as address,
        nullif(trim("City/Town"), '')                                                                  as city,
        nullif(trim("State"), '')                                                                      as state,
        nullif(trim("ZIP Code"), '')                                                                   as zip_code,
        nullif(trim("Telephone Number"), '0000001111')                                                 as phone,
        nullif(trim("Provider SSA County Code"), '000')                                                as ssa_county_code,
        nullif(trim("County/Parish"), '')                                                              as county,
        nullif(trim("Ownership Type"), '')                                                             as ownership_type,
        try_to_number("Number of Certified Beds")                                                      as certified_beds,
        try_to_decimal("Average Number of Residents per Day", 10, 2)                                   as avg_residents_per_day,
        nullif(trim("Average Number of Residents per Day Footnote"), '')                               as avg_residents_per_day_footnote,
        nullif(trim("Provider Type"), '')                                                              as provider_type,
        try_to_boolean("Provider Resides in Hospital")                                                 as is_in_hospital,
        nullif(trim("Legal Business Name"), '')                                                        as legal_business_name,
        try_to_date("Date First Approved to Provide Medicare and Medicaid Services")                   as medicare_medicaid_approval_date,
        nullif(trim("Affiliated Entity Name"), '')                                                     as affiliated_entity_name,
        nullif(trim("Affiliated Entity ID"), '')                                                       as affiliated_entity_id,
        try_to_boolean("Continuing Care Retirement Community")                                         as is_ccrc,
        nullif(trim("Special Focus Status"), '')                                                       as special_focus_status,
        try_to_boolean("Abuse Icon")                                                                   as has_abuse_icon,
        try_to_boolean("Most Recent Health Inspection More Than 2 Years Ago")                          as is_last_inspection_over_2_years,
        try_to_boolean("Provider Changed Ownership in Last 12 Months")                                 as changed_ownership_last_12_months,
        nullif(trim("With a Resident and Family Council"), '')                                         as resident_family_council,
        nullif(trim("Automatic Sprinkler Systems in All Required Areas"), '')                          as sprinkler_systems_status,
        try_to_number("Overall Rating")                                                                as overall_rating,
        nullif(trim("Overall Rating Footnote"), '')                                                    as overall_rating_footnote,
        try_to_number("Health Inspection Rating")                                                      as health_inspection_rating,
        nullif(trim("Health Inspection Rating Footnote"), '')                                          as health_inspection_rating_footnote,
        try_to_number("QM Rating")                                                                     as qm_rating,
        nullif(trim("QM Rating Footnote"), '')                                                         as qm_rating_footnote,
        try_to_number("Long-Stay QM Rating")                                                           as long_stay_qm_rating,
        nullif(trim("Long-Stay QM Rating Footnote"), '')                                               as long_stay_qm_rating_footnote,
        try_to_number("Short-Stay QM Rating")                                                          as short_stay_qm_rating,
        nullif(trim("Short-Stay QM Rating Footnote"), '')                                              as short_stay_qm_rating_footnote,
        try_to_number("Staffing Rating")                                                               as staffing_rating,
        nullif(trim("Staffing Rating Footnote"), '')                                                   as staffing_rating_footnote,
        nullif(trim("Reported Staffing Footnote"), '')                                                 as reported_staffing_footnote,
        nullif(trim("Physical Therapist Staffing Footnote"), '')                                       as pt_staffing_footnote,
        try_to_decimal("Reported Nurse Aide Staffing Hours per Resident per Day", 10, 5)               as reported_nurse_aide_hprd,
        try_to_decimal("Reported LPN Staffing Hours per Resident per Day", 10, 5)                      as reported_lpn_hprd,
        try_to_decimal("Reported RN Staffing Hours per Resident per Day", 10, 5)                       as reported_rn_hprd,
        try_to_decimal("Reported Licensed Staffing Hours per Resident per Day", 10, 5)                 as reported_licensed_hprd,
        try_to_decimal("Reported Total Nurse Staffing Hours per Resident per Day", 10, 5)              as reported_total_nurse_hprd,
        try_to_decimal("Total number of nurse staff hours per resident per day on the weekend", 10, 5) as weekend_total_nurse_hprd,
        try_to_decimal("Registered Nurse hours per resident per day on the weekend", 10, 5)            as weekend_rn_hprd,
        try_to_decimal("Reported Physical Therapist Staffing Hours per Resident Per Day", 10, 5)       as reported_pt_hprd,
        try_to_decimal("Total nursing staff turnover", 9, 4)                                           as total_nursing_turnover_pct,
        nullif(trim("Total nursing staff turnover footnote"), '')                                      as total_nursing_turnover_footnote,
        try_to_decimal("Registered Nurse turnover", 9, 4)                                              as rn_turnover_pct,
        nullif(trim("Registered Nurse turnover footnote"), '')                                         as rn_turnover_footnote,
        try_to_number("Number of administrators who have left the nursing home")                       as administrators_departed,
        nullif(trim("Administrator turnover footnote"), '')                                            as administrator_turnover_footnote,
        try_to_decimal("Nursing Case-Mix Index", 10, 5)                                                as nursing_case_mix_index,
        try_to_decimal("Nursing Case-Mix Index Ratio", 10, 5)                                          as nursing_case_mix_index_ratio,
        try_to_decimal("Case-Mix Nurse Aide Staffing Hours per Resident per Day", 10, 5)               as case_mix_nurse_aide_hprd,
        try_to_decimal("Case-Mix LPN Staffing Hours per Resident per Day", 10, 5)                      as case_mix_lpn_hprd,
        try_to_decimal("Case-Mix RN Staffing Hours per Resident per Day", 10, 5)                       as case_mix_rn_hprd,
        try_to_decimal("Case-Mix Total Nurse Staffing Hours per Resident per Day", 10, 5)              as case_mix_total_nurse_hprd,
        try_to_decimal("Case-Mix Weekend Total Nurse Staffing Hours per Resident per Day", 10, 5)      as case_mix_weekend_total_nurse_hprd,
        try_to_decimal("Adjusted Nurse Aide Staffing Hours per Resident per Day", 10, 5)               as adjusted_nurse_aide_hprd,
        try_to_decimal("Adjusted LPN Staffing Hours per Resident per Day", 10, 5)                      as adjusted_lpn_hprd,
        try_to_decimal("Adjusted RN Staffing Hours per Resident per Day", 10, 5)                       as adjusted_rn_hprd,
        try_to_decimal("Adjusted Total Nurse Staffing Hours per Resident per Day", 10, 5)              as adjusted_total_nurse_hprd,
        try_to_decimal("Adjusted Weekend Total Nurse Staffing Hours per Resident per Day", 10, 5)      as adjusted_weekend_total_nurse_hprd,
        try_to_date("Rating Cycle 1 Standard Survey Health Date")                                      as cycle_1_survey_date,
        try_to_number("Rating Cycle 1 Total Number of Health Deficiencies")                            as cycle_1_total_health_deficiencies,
        try_to_number("Rating Cycle 1 Number of Standard Health Deficiencies")                         as cycle_1_standard_health_deficiencies,
        try_to_number("Rating Cycle 1 Number of Complaint Health Deficiencies")                        as cycle_1_complaint_health_deficiencies,
        try_to_decimal("Rating Cycle 1 Health Deficiency Score", 12, 4)                                as cycle_1_health_deficiency_score,
        try_to_number("Rating Cycle 1 Number of Health Revisits")                                      as cycle_1_health_revisits,
        try_to_decimal("Rating Cycle 1 Health Revisit Score", 12, 4)                                   as cycle_1_health_revisit_score,
        try_to_decimal("Rating Cycle 1 Total Health Score", 12, 4)                                     as cycle_1_total_health_score,
        try_to_date("Rating Cycle 2 Standard Health Survey Date")                                      as cycle_2_survey_date,
        try_to_number("Rating Cycle 2 Total Number of Health Deficiencies")                            as cycle_2_total_health_deficiencies,
        try_to_number("Rating Cycle 2 Number of Standard Health Deficiencies")                         as cycle_2_standard_health_deficiencies,
        try_to_number("Rating Cycle 2 Number of Complaint Health Deficiencies")                        as cycle_2_complaint_health_deficiencies,
        try_to_decimal("Rating Cycle 2 Health Deficiency Score", 12, 4)                                as cycle_2_health_deficiency_score,
        try_to_number("Rating Cycle 2 Number of Health Revisits")                                      as cycle_2_health_revisits,
        try_to_decimal("Rating Cycle 2 Health Revisit Score", 12, 4)                                   as cycle_2_health_revisit_score,
        try_to_decimal("Rating Cycle 2 Total Health Score", 12, 4)                                     as cycle_2_total_health_score,
        try_to_date("Rating Cycle 3 Standard Health Survey Date")                                      as cycle_3_survey_date,
        try_to_number("Rating Cycle 3 Total Number of Health Deficiencies")                            as cycle_3_total_health_deficiencies,
        try_to_number("Rating Cycle 3 Number of Standard Health Deficiencies")                         as cycle_3_standard_health_deficiencies,
        try_to_number("Rating Cycle 3 Number of Complaint Health Deficiencies")                        as cycle_3_complaint_health_deficiencies,
        try_to_decimal("Rating Cycle 3 Health Deficiency Score", 12, 4)                                as cycle_3_health_deficiency_score,
        try_to_number("Rating Cycle 3 Number of Health Revisits")                                      as cycle_3_health_revisits,
        try_to_decimal("Rating Cycle 3 Health Revisit Score", 12, 4)                                   as cycle_3_health_revisit_score,
        try_to_decimal("Rating Cycle 3 Total Health Score", 12, 4)                                     as cycle_3_total_health_score,
        try_to_decimal("Total Weighted Health Survey Score", 12, 4)                                    as total_weighted_health_survey_score,
        try_to_number("Number of Facility Reported Incidents")                                         as facility_reported_incidents,
        try_to_number("Number of Substantiated Complaints")                                            as substantiated_complaints,
        try_to_number("Number of Citations from Infection Control Inspections")                        as infection_control_citations,
        try_to_number("Number of Fines")                                                               as fines_count,
        try_to_decimal("Total Amount of Fines in Dollars", 14, 2)                                      as fines_total_usd,
        try_to_number("Number of Payment Denials")                                                     as payment_denials_count,
        try_to_number("Total Number of Penalties")                                                     as penalties_total_count,
        -- "Location" dropped: duplicates address and coordinates
        try_to_decimal("Latitude", 10, 6)                                                              as latitude,
        try_to_decimal("Longitude", 10, 6)                                                             as longitude,
        nullif(trim("Geocoding Footnote"), '')                                                         as geocoding_footnote,
        try_to_date("Processing Date")                                                                 as processing_date,

        -- lineage
        {{ release_from_source_file() }}                                                 as release,
        _source_file                                                              as source_file,
        _loaded_at                                                                as loaded_at

    from source

)

select * from renamed
-- raw is append-only across releases; keep only the most recent
qualify release = max(release) over ()
