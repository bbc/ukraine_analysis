set search_path TO 'central_insights_sandbox';
SELECT distinct app_type, click_placement, click_container, count(*) as clicks
FROM  dataforce_insights.df_journey_to_playback
WHERE click_container  ILIKE '%ukraine%'
GROUP BY 1,2,3
HAVING clicks >100
ORDER BY 4 desc;

SELECT click_placement, click_container, min(dt)
FROM dataforce_insights.df_journey_to_playback
WHERE dt > '20220101' AND click_container  ILIKE '%ukraine%'
GROUP BY 1,2
ORDER BY min;

SELECT *
FROM dataforce_insights.df_homepage_journey_to_playback_summary
WHERE dt > '2022022' AND click_container  ILIKE '%ukraine%'
LIMIT 100
;

SELECT DISTINCT dt, frequency_band, count(*) FROM vb_ukraine_module_impr
WHERE dt > '20220301'
GROUP BY 1,2
ORDER BY 1,2;

----- impresions table
DROP TABLE IF EXISTS vb_ukraine_module_impr;
CREATE TABLE vb_ukraine_module_impr AS
SELECT dt,
       app_type,
       age_range,
       gender,
       frequency_band,
       CASE
           WHEN container ILIKE '%ukraine%' THEN 'ukraine'
           WHEN container ILIKE '%film%' THEN 'film'
           WHEN container ILIKE '%recommendations%' THEN 'recommended'
           WHEN container ILIKE '%added%' THEN 'your-added'
           WHEN container ILIKE '%comedy%' THEN 'comedy'
           WHEN container ILIKE '%continue%' THEN 'continue-watching'
           WHEN container ILIKE '%trending%' THEN 'new-trending'
           ELSE container END as container,
       num_hids,
       num_visits
FROM dataforce_insights.df_journey_homepage_module_impr
WHERE dt > '20220201'
  AND dt != '20220301'
  AND (container ILIKE '%ukraine%' OR container ILIKE '%film%' OR
       container in ('watching-continue-watching',
                     'editorial-new-trending',
                     'recommendations-recommended-for-you',
                     'added-your-added-programmes',
                     'comedy-category-comedy'
           ))
;
SELECT count(*) FROM vb_ukraine_module_impr;--55940
SELECT DISTINCT container,count(*) FROM vb_ukraine_module_impr GROUP BY 1;

---clicks table
DROP TABLE IF EXISTS vb_ukraine_journeys;
CREATE TABLE vb_ukraine_journeys AS
SELECT dt,
       app_type,
       age_range,
       frequency_band,
       click_user_experience,
       CASE
           WHEN click_container ILIKE '%ukraine%' THEN 'ukraine'
           WHEN click_container ILIKE '%film%' THEN 'film'
           WHEN click_container ILIKE '%recommendations%' THEN 'recommended'
           WHEN click_container ILIKE '%added%' THEN 'your-added'
           WHEN click_container ILIKE '%comedy%' THEN 'comedy'
           WHEN click_container ILIKE '%continue%' THEN 'continue-watching'
           WHEN click_container ILIKE '%trending%' THEN 'new-trending'
           ELSE click_container END as container,
       via_tleo,
       playback_type,
       start_type,
       num_visits,
       num_clicks,
       num_starts,
       num_completes
FROM dataforce_insights.df_homepage_journey_to_playback_summary
WHERE (click_container ILIKE '%ukraine%' OR click_container  ILIKE '%film%' OR
       click_container  in ('watching-continue-watching',
                     'editorial-new-trending',
                     'recommendations-recommended-for-you',
                     'added-your-added-programmes',
                     'comedy-category-comedy'
           ))
  AND dt > '20220201'
  AND dt != '20220301'
;
SELECT count(*) FROM vb_ukraine_journeys;--103169
SELECT DISTINCT container FROM vb_ukraine_journeys;

SELECT DISTINCT dt, frequency_band, count(*) FROM dataforce_insights.df_homepage_journey_to_playback_summary
WHERE dt >= '20220222'
GROUP BY 1,2
ORDER BY 1,2;

--module positions
DROP TABLE IF EXISTS central_insights_sandbox.vb_iplayer_pos_clicks;
CREATE TABLE central_insights_sandbox.vb_iplayer_pos_clicks as
SELECT dt,
       CASE
           WHEN container ILIKE '%ukraine%' THEN 'ukraine'
           WHEN container ILIKE '%film%' THEN 'film'
           WHEN container ILIKE '%recommendations%' THEN 'recommended'
           WHEN container ILIKE '%added%' THEN 'your-added'
           WHEN container ILIKE '%comedy%' THEN 'comedy'
           WHEN container ILIKE '%trending%' THEN 'new-trending'
    ELSE container END as container,
       split_part(split_part(metadata, '=', 2), '::', 1)                       as app_type,
       split_part(split_part(metadata, 'POS=', 2), '::', 1)                    as rail_pos,
       split_part(split_part(metadata, 'POS=', 2), '::', 2)                    as item_pos,
       sum(publisher_impressions)                                              as impr,
       sum(publisher_clicks)                                                   as clicks
FROM s3_audience.publisher
WHERE dt > '20220222'
  AND (container ILIKE '%ukraine%' OR container ILIKE '%film%' OR
       container in ('module-watching-continue-watching',
                                                    'module-editorial-new-trending',
                                                    'module-recommendations-recommended-for-you',
                                                    'module-added-your-added-programmes',
                                                    'module-comedy-category-comedy')
    )
  AND dt > '20220222' AND dt != '20220301'
  AND destination = 'PS_IPLAYER'
  AND metadata ILIKE '%POS=%'
  AND placement IN ('iplayer.tv.page', 'iplayer.tv.home.page')
GROUP BY 1, 2, 3, 4, 5
ORDER BY 1;

SELECT distinct container FROM central_insights_sandbox.vb_iplayer_pos_clicks;
SELECT * FROM central_insights_sandbox.vb_iplayer_pos_clicks;

SELECT disticnt container FROM

WHERE
SELECT DISTINCT click_container, sum(num_clicks)
FROM dataforce_insights.df_homepage_journey_to_playback_summary
WHERE dt > '20220222'
GROUP BY 1
ORDER BY 2 DESC;

/*'watching-continue-watching'
'editorial-new-trending'
'recommendations-recommended-for-you'
'added-your-added-programmes'*/


SELECT container, sum(num_clicks) as clicks, sum(num_starts) as starts, sum(num_completes) as completes
FROM vb_ukraine_journeys
WHERE dt = '20220227'
GROUP BY 1


--- User factfile
DROP TABLE IF EXISTS vb_ukraine_ipl_viewers;
CREATE TABLE vb_ukraine_ipl_viewers AS
with viewers as (
    SELECT hashed_id,
           app_type,
           click_placement,
           CASE
               WHEN click_container ILIKE '%ukraine%' THEN 'ukraine'
               WHEN click_container ILIKE '%watching-continue-watching%' THEN 'continue-watching'
               WHEN click_container ILIKE '%editorial-new-trending%' THEN 'new-trending'
               WHEN click_container ILIKE '%recommendations%' THEN 'recommended'
               WHEN click_container ILIKE '%comedy-category-comedy%' THEN 'comedy'
               ELSE 'module' END as container,
           age_range,
           frequency_group_aggregated,
           start_flag,
           complete_flag
    FROM dataforce_insights.df_journey_to_playback
    WHERE  dt > '20220222'
      AND dt != '20220301'
      AND click_placement IN ('channels_page', 'home_page')
),
     demographic as (
         SELECT DISTINCT bbc_hid3,
                         CASE
                             WHEN gender != 'male' AND gender != 'female'  THEN 'unknown'
                             ELSE gender END                                                     as gender,
                         LPAD(acorn_category::text, 2, '0') || '_' || acorn_category_description as acorn_cat
         FROM prez.profile_extension
         WHERE bbc_hid3 in (SELECT DISTINCT hashed_id FROM viewers)
     )

SELECT a.*, gender,  acorn_cat
FROM viewers a
         LEFT JOIN demographic b on a.hashed_id = b.bbc_hid3
;


SELECT distinct click_container FROM dataforce_insights.df_journey_to_playback LIMIT 100;


SELECT * FROM  vb_ukraine_ipl_viewers_summary LIMIT 10;

CREATE TABLE vb_ukraine_ipl_viewers_summary AS
SELECT app_type,
       age_range, frequency_group_aggregated, gender, acorn_cat,
       click_placement,
       container,
       count(*) as clicks, sum(start_flag) as starts, sum(complete_flag) as completes
FROM vb_ukraine_ipl_viewers
GROUP BY 1,2,3,4,5,6,7;

DELETE FROM vb_ukraine_ipl_viewers_summary
WHERE click_placement = 'channels_page' AND container not in ('module','ukraine');

SELECT DISTINCT has FROM vb_ukraine_ipl_viewers_summary GROUP BY 1,2;


-- how many who started watching something were News app/web users
SELECT count(distinct audience_id)                                                         as users,
       (SELECT count(DISTINCT hashed_id) FROM vb_ukraine_ipl_viewers WHERE start_flag = 1 AND container = 'ukraine') as ipl_ukraine_viewers
FROM audience.audience_activity_daily_summary_enriched
WHERE destination = 'PS_NEWS'
  AND date_of_event > '2022-02-01'
  AND audience_id IN (SELECT DISTINCT hashed_id FROM vb_ukraine_ipl_viewers WHERE start_flag = 1 AND container = 'ukraine')
;


-- generic iPlayer audience
DROP TABLE IF EXISTS vb_typical_ipl_viewers;
CREATE TABLE vb_typical_ipl_viewers AS
with viewers as (
    SELECT DISTINCT hashed_id,
           age_range,
           frequency_group_aggregated
    FROM dataforce_insights.df_journey_to_playback
    WHERE  dt > '20220222'
      AND dt != '20220301'
    AND age_range NOT IN ('13-15', 'Under 13')
),
     demographic as (
         SELECT DISTINCT bbc_hid3,
                         CASE
                             WHEN gender = 'male' THEN 'male'
                             WHEN gender = 'female' THEN 'female'
                             ELSE 'unknown' END                                                  as gender,
                         LPAD(acorn_category::text, 2, '0') || '_' || acorn_category_description as acorn_cat
         FROM prez.profile_extension
         WHERE bbc_hid3 in (SELECT DISTINCT hashed_id FROM viewers)
     )

SELECT  age_range, frequency_group_aggregated, gender,  acorn_cat, count(distinct hashed_id) as users
FROM viewers a
         LEFT JOIN demographic b on a.hashed_id = b.bbc_hid3
GROUP BY 1,2,3,4
;
SELECT count(*) FROM vb_typical_ipl_viewers;

-- generic iPlayer audience
DROP TABLE IF EXISTS vb_ukraine_ipl_demo_summary;
CREATE TABLE vb_ukraine_ipl_demo_summary AS
with viewers as (
    SELECT DISTINCT hashed_id,
           age_range,
           frequency_group_aggregated
    FROM dataforce_insights.df_journey_to_playback
    WHERE  dt > '20220222'
      AND dt != '20220301'
    AND click_container ILIKE '%ukraine%'
    AND age_range NOT IN ('13-15', 'Under 13')
),
     demographic as (
         SELECT DISTINCT bbc_hid3,
                         CASE
                             WHEN gender = 'male' THEN 'male'
                             WHEN gender = 'female' THEN 'female'
                             ELSE 'unknown' END                                                  as gender,
                         LPAD(acorn_category::text, 2, '0') || '_' || acorn_category_description as acorn_cat
         FROM prez.profile_extension
         WHERE bbc_hid3 in (SELECT DISTINCT hashed_id FROM viewers)
     )

SELECT age_range, frequency_group_aggregated, gender,  acorn_cat, count(distinct hashed_id) as users
FROM viewers a
         LEFT JOIN demographic b on a.hashed_id = b.bbc_hid3
GROUP BY 1,2,3,4
;
SELECT count(*) FROM vb_ukraine_ipl_demo_summary;

---frequency
SELECT DISTINCT frequency_group_aggregated,
                count(distinct hashed_id) as users,
                'all'                     as category
FROM dataforce_insights.df_journey_to_playback
WHERE dt >= '20220225'
  AND dt <= '20220227'
  AND age_range NOT IN ('13-15', 'Under 13')
GROUP BY 1

UNION
SELECT DISTINCT frequency_group_aggregated,
                count(distinct hashed_id) as users,
                'ukraine'                 as category
FROM dataforce_insights.df_journey_to_playback
WHERE dt >= '20220225'
  AND dt <= '20220227'
  AND age_range NOT IN ('13-15', 'Under 13')
  AND click_container ILIKE '%ukraine%'
GROUP BY 1

-- iplayer home position clicks
DROP TABLE vb_iplayer_heatmap;
CREATE TABLE vb_iplayer_heatmap as
SELECT
       split_part(split_part(split_part(metadata, 'POS=', 2), '::', 1),'~',1)                    as rail_pos,
       left(split_part(split_part(metadata, 'POS=', 2), '::', 2),1)                 as item_pos,
       sum(publisher_impressions)                                              as impr,
       sum(publisher_clicks)                                                   as clicks
FROM s3_audience.publisher
WHERE  dt > '20220222' AND dt != '20220301'
  AND destination = 'PS_IPLAYER'
  AND metadata ILIKE '%POS=%'
  AND placement IN ('iplayer.tv.page', 'iplayer.tv.home.page') AND container in
                                                                   (SELECT DISTINCT click_container
                                                                    FROM dataforce_insights.df_journey_to_playback
                                                                    WHERE dt > '20220222' AND dt != '20220301'
                                                                    GROUP BY 1
                                                                   )
AND  item_pos IS NOT NULL
GROUP BY 1, 2
ORDER BY 1;
DELETE FROM vb_iplayer_heatmap WHERE rail_pos ILIKE '%-%';
SELECT * FROM vb_iplayer_heatmap;



SELECT click_placement, count(*) as clicks, sum(start_flag) as starts,sum(complete_flag) as completes
FROM dataforce_insights.df_journey_to_playback
WHERE dt > '20220222'
  AND dt != '20220301'
AND click_placement != 'unknown'
GROUP BY 1

--What items?
with vmb as (SELECT DISTINCT brand_title, episode_title, episode_id FROM prez.scv_vmb),
     content as (SELECT content_id,
                                 count(*)           as clicks,
                                 sum(start_flag)    as starts,
                                 sum(complete_flag) as completes
                 FROM dataforce_insights.df_journey_to_playback a
                 WHERE dt > '20220222'
                   AND dt != '20220301'
                   AND click_container ILIKE '%ukraine%'
                   AND content_id IS NOT NULL
                 GROUP BY 1)

SELECT b.*, clicks, starts, completes
FROM content a
         LEFT join vmb b on a.content_id = b.episode_id
ORDER BY starts DESC
LIMIT 10
;