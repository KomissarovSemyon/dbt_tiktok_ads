with base as (

    select *
    from {{ var('ad_history') }}

), filtered as (

    select *
    from base
    where is_most_recent_record
    
)

select *
from filtered