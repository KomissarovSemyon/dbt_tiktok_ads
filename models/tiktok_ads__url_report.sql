{{ config(enabled=var('ad_reporting__tiktok_ads_enabled', true)) }}

with hourly as (
    
    select *
    from {{ var('ad_report_hourly') }}
), 

ads as (

    select *
    from {{ var('ad_history') }}
    where is_most_recent_record
), 

ad_groups as (

    select *
    from {{ var('ad_group_history') }}
    where is_most_recent_record
), 

advertiser as (

    select *
    from {{ var('advertiser') }}
), 

campaigns as (

    select *
    from {{ var('campaign_history') }}
    where is_most_recent_record
), 

aggregated as (

    select
        cast(hourly.stat_time_hour as date) as date_day,
        ad_groups.advertiser_id,
        advertiser.advertiser_name,
        campaigns.campaign_id,
        campaigns.campaign_name,
        ad_groups.ad_group_id,
        ad_groups.ad_group_name,
        hourly.ad_id,
        ads.ad_name,
        ads.base_url,
        ads.url_host,
        ads.url_path,
        ads.utm_source,
        ads.utm_medium,
        ads.utm_campaign,
        ads.utm_content,
        ads.utm_term,
        advertiser.currency,
        to_json_string(ad_groups.action_categories) as action_categories,
        ad_groups.category,
        ad_groups.gender,
        ad_groups.audience_type,
        ad_groups.budget,
        to_json_string(ad_groups.age) as age,
        to_json_string(ad_groups.languages) as languages,
        to_json_string(ad_groups.interest_category) as interest_category,
        sum(hourly.impressions) as impressions,
        sum(hourly.clicks) as clicks,
        sum(hourly.spend) as spend,
        sum(hourly.reach) as reach,
        sum(hourly.conversion) as conversion,
        sum(hourly.likes) as likes,
        sum(hourly.comments) as comments,
        sum(hourly.shares) as shares,
        sum(hourly.profile_visits) as profile_visits,
        sum(hourly.follows) as follows,
        sum(hourly.video_watched_2_s) as video_watched_2_s,
        sum(hourly.video_watched_6_s) as video_watched_6_s,
        sum(hourly.video_views_p_25) as video_views_p_25,
        sum(hourly.video_views_p_50) as video_views_p_50, 
        sum(hourly.video_views_p_75) as video_views_p_75,
        sum(hourly.spend)/nullif(sum(hourly.clicks),0) as daily_cpc,
        (sum(hourly.spend)/nullif(sum(hourly.impressions),0))*1000 as daily_cpm,
        (sum(hourly.clicks)/nullif(sum(hourly.impressions),0))*100 as daily_ctr

        {{ fivetran_utils.persist_pass_through_columns(pass_through_variable='tiktok_ads__ad_hourly_passthrough_metrics', transform = 'sum') }}
    
    from hourly
    left join ads
        on hourly.ad_id = ads.ad_id
    left join ad_groups 
        on ads.ad_group_id = ad_groups.ad_group_id
    left join advertiser
        on ads.advertiser_id = advertiser.advertiser_id
    left join campaigns
        on ads.campaign_id = campaigns.campaign_id

    {% if var('ad_reporting__url_report__using_null_filter', True) %}
        -- We are filtering for only ads where url fields are populated.
        where ads.landing_page_url is not null
    {% endif %}

    {{ dbt_utils.group_by(26) }}

)

select *
from aggregated
