/* =====================================================================
   CASE STUDY: "Where should FocusWell launch its digital-wellbeing campaign?"
   Database : PostgreSQL 14+
   Dataset  : social_screen_time_by_location.csv (1,500 users, 28 columns)
   ---------------------------------------------------------------------
   BUSINESS SCENARIO
   FocusWell is a (fictional) digital-wellbeing app. The marketing head
   has a limited budget and asks the data team:

     1. Is the data trustworthy?
     2. Which cities have the heaviest mobile / social-media usage?
     3. Which platforms dominate in each city?
     4. Which age groups and occupations are most at risk?
     5. Where do people lose the most sleep to their phones?
     6. Which 5 cities should get the campaign first, and in what order?

   HOW TO RUN
     psql -d yourdb -f screen_time_case_study.sql
   (keep the CSV in the same folder; \copy reads it from the client side)
   ===================================================================== */


/* ---------------------------------------------------------------------
   STEP 0 - SCHEMA + LOAD
   --------------------------------------------------------------------- */
DROP TABLE IF EXISTS screen_time CASCADE;

CREATE TABLE screen_time (
    user_id                  VARCHAR(10) PRIMARY KEY,
    log_date                 DATE        NOT NULL,
    age                      INT         CHECK (age BETWEEN 10 AND 100),
    gender                   VARCHAR(10),
    occupation               VARCHAR(40),
    city                     VARCHAR(40) NOT NULL,
    state                    VARCHAR(40),
    country                  VARCHAR(40),
    latitude                 NUMERIC(8,5),
    longitude                NUMERIC(8,5),
    area_type                VARCHAR(20),
    device_os                VARCHAR(10),
    phone_model              VARCHAR(40),
    daily_screen_time_hrs    NUMERIC(4,1),
    weekend_screen_time_hrs  NUMERIC(4,1),
    phone_pickups_per_day    INT,
    notifications_per_day    INT,
    night_usage_min          INT,
    instagram_min            INT,
    facebook_min             INT,
    youtube_min              INT,
    whatsapp_min             INT,
    x_twitter_min            INT,
    snapchat_min             INT,
    telegram_min             INT,
    linkedin_min             INT,
    total_social_min         INT,
    most_used_platform       VARCHAR(20)
);

\copy screen_time FROM 'social_screen_time_by_location.csv' WITH (FORMAT csv, HEADER true)

-- Indexes for the columns we filter / group on most
CREATE INDEX idx_st_city     ON screen_time (city);
CREATE INDEX idx_st_date     ON screen_time (log_date);
CREATE INDEX idx_st_platform ON screen_time (most_used_platform);
ANALYZE screen_time;


/* ---------------------------------------------------------------------
   Q1. DATA QUALITY CHECK  (always the first thing a data engineer does)
   --------------------------------------------------------------------- */
SELECT
    COUNT(*)                                                       AS total_rows,
    COUNT(DISTINCT user_id)                                        AS distinct_users,
    MIN(log_date)                                                  AS first_date,
    MAX(log_date)                                                  AS last_date,
    COUNT(*) FILTER (WHERE city IS NULL OR age IS NULL)            AS rows_with_nulls,
    COUNT(*) FILTER (WHERE daily_screen_time_hrs > 16)             AS impossible_screen_time,
    COUNT(*) FILTER (WHERE total_social_min <>
        instagram_min + facebook_min + youtube_min + whatsapp_min +
        x_twitter_min + snapchat_min + telegram_min + linkedin_min) AS total_mismatch,
    COUNT(*) FILTER (WHERE total_social_min / 60.0 > daily_screen_time_hrs)
                                                                   AS social_exceeds_screen
FROM screen_time;
-- Reading the result: social_exceeds_screen > 0 would mean a user spends more
-- time on social apps than on the phone in total, which is a logging error
-- that must be investigated before trusting any averages.


/* ---------------------------------------------------------------------
   Q2. HEADLINE KPIs FOR THE DASHBOARD
   --------------------------------------------------------------------- */
SELECT
    COUNT(*)                                         AS users,
    ROUND(AVG(daily_screen_time_hrs), 2)             AS avg_screen_hrs,
    ROUND(percentile_cont(0.5) WITHIN GROUP
          (ORDER BY daily_screen_time_hrs)::numeric, 2) AS median_screen_hrs,
    ROUND(AVG(total_social_min))                     AS avg_social_min,
    ROUND(AVG(phone_pickups_per_day))                AS avg_pickups,
    ROUND(AVG(night_usage_min))                      AS avg_night_min
FROM screen_time;


/* ---------------------------------------------------------------------
   Q3. CITY LEADERBOARD  (Which cities use phones the most?)
   --------------------------------------------------------------------- */
SELECT
    city,
    state,
    area_type,
    COUNT(*)                                   AS users,
    ROUND(AVG(daily_screen_time_hrs), 2)       AS avg_screen_hrs,
    ROUND(AVG(total_social_min))               AS avg_social_min,
    RANK() OVER (ORDER BY AVG(daily_screen_time_hrs) DESC) AS screen_rank
FROM screen_time
GROUP BY city, state, area_type
ORDER BY screen_rank;


/* ---------------------------------------------------------------------
   Q4. PLATFORM SHARE PER CITY  (conditional aggregation = manual pivot)
   Share of each platform in that city's total social minutes.
   --------------------------------------------------------------------- */
SELECT
    city,
    ROUND(100.0 * SUM(instagram_min) / SUM(total_social_min), 1) AS instagram_pct,
    ROUND(100.0 * SUM(youtube_min)   / SUM(total_social_min), 1) AS youtube_pct,
    ROUND(100.0 * SUM(whatsapp_min)  / SUM(total_social_min), 1) AS whatsapp_pct,
    ROUND(100.0 * SUM(facebook_min)  / SUM(total_social_min), 1) AS facebook_pct,
    ROUND(100.0 * SUM(snapchat_min)  / SUM(total_social_min), 1) AS snapchat_pct,
    ROUND(100.0 * (SUM(x_twitter_min) + SUM(telegram_min) + SUM(linkedin_min))
          / SUM(total_social_min), 1)                            AS others_pct
FROM screen_time
GROUP BY city
ORDER BY instagram_pct DESC;


/* ---------------------------------------------------------------------
   Q5. AGE-GROUP ANALYSIS  (Who is most at risk?)
   --------------------------------------------------------------------- */
SELECT
    CASE
        WHEN age < 18 THEN '1. Under 18'
        WHEN age BETWEEN 18 AND 24 THEN '2. 18-24'
        WHEN age BETWEEN 25 AND 34 THEN '3. 25-34'
        WHEN age BETWEEN 35 AND 49 THEN '4. 35-49'
        ELSE '5. 50+'
    END                                          AS age_group,
    COUNT(*)                                     AS users,
    ROUND(AVG(daily_screen_time_hrs), 2)         AS avg_screen_hrs,
    ROUND(AVG(night_usage_min))                  AS avg_night_min,
    ROUND(AVG(instagram_min + snapchat_min))     AS avg_insta_snap_min,
    ROUND(AVG(linkedin_min))                     AS avg_linkedin_min
FROM screen_time
GROUP BY 1
ORDER BY 1;


/* ---------------------------------------------------------------------
   Q6. WEEKEND UPLIFT BY CITY  (Does usage jump on weekends?)
   --------------------------------------------------------------------- */
SELECT
    city,
    ROUND(AVG(daily_screen_time_hrs), 2)   AS weekday_hrs,
    ROUND(AVG(weekend_screen_time_hrs), 2) AS weekend_hrs,
    ROUND(100.0 * (AVG(weekend_screen_time_hrs) - AVG(daily_screen_time_hrs))
          / AVG(daily_screen_time_hrs), 1) AS weekend_uplift_pct
FROM screen_time
GROUP BY city
ORDER BY weekend_uplift_pct DESC;


/* ---------------------------------------------------------------------
   Q7. HEAVY-USER SEGMENTATION WITH A CTE
   Segment thresholds are relative (quartiles) so they adapt to the data.
   --------------------------------------------------------------------- */
WITH ranked AS (
    SELECT
        user_id, city, daily_screen_time_hrs,
        NTILE(4) OVER (ORDER BY daily_screen_time_hrs) AS usage_quartile
    FROM screen_time
),
segmented AS (
    SELECT *,
           CASE usage_quartile
               WHEN 4 THEN 'Heavy'
               WHEN 3 THEN 'Above average'
               WHEN 2 THEN 'Below average'
               ELSE 'Light'
           END AS segment
    FROM ranked
)
SELECT
    city,
    COUNT(*)                                              AS users,
    COUNT(*) FILTER (WHERE segment = 'Heavy')             AS heavy_users,
    ROUND(100.0 * COUNT(*) FILTER (WHERE segment = 'Heavy')
          / COUNT(*), 1)                                  AS heavy_user_pct
FROM segmented
GROUP BY city
ORDER BY heavy_user_pct DESC;


/* ---------------------------------------------------------------------
   Q8. ANDROID vs iOS
   --------------------------------------------------------------------- */
SELECT
    device_os,
    COUNT(*)                              AS users,
    ROUND(AVG(daily_screen_time_hrs), 2)  AS avg_screen_hrs,
    ROUND(AVG(phone_pickups_per_day))     AS avg_pickups,
    ROUND(AVG(notifications_per_day))     AS avg_notifications,
    ROUND(AVG(total_social_min))          AS avg_social_min
FROM screen_time
GROUP BY device_os;


/* ---------------------------------------------------------------------
   Q9. TOP 3 CITIES INSIDE EACH STATE  (ROW_NUMBER + PARTITION BY)
   --------------------------------------------------------------------- */
WITH city_stats AS (
    SELECT state, city, ROUND(AVG(total_social_min)) AS avg_social_min
    FROM screen_time
    GROUP BY state, city
),
ranked AS (
    SELECT *,
           ROW_NUMBER() OVER (PARTITION BY state ORDER BY avg_social_min DESC) AS rn
    FROM city_stats
)
SELECT state, city, avg_social_min, rn AS rank_in_state
FROM ranked
WHERE rn <= 3
ORDER BY state, rn;


/* ---------------------------------------------------------------------
   Q10. WEEKLY TREND + WEEK-OVER-WEEK CHANGE  (date_trunc + LAG)
   --------------------------------------------------------------------- */
WITH weekly AS (
    SELECT
        date_trunc('week', log_date)::date   AS week_start,
        COUNT(*)                             AS records,
        ROUND(AVG(daily_screen_time_hrs), 2) AS avg_screen_hrs
    FROM screen_time
    GROUP BY 1
)
SELECT
    week_start,
    records,
    avg_screen_hrs,
    avg_screen_hrs - LAG(avg_screen_hrs) OVER (ORDER BY week_start) AS wow_change
FROM weekly
ORDER BY week_start;


/* ---------------------------------------------------------------------
   Q11. OCCUPATION x PLATFORM
   Which job groups are the best fit for which platform's audience?
   --------------------------------------------------------------------- */
SELECT
    occupation,
    COUNT(*)                         AS users,
    ROUND(AVG(linkedin_min), 1)      AS linkedin_min,
    ROUND(AVG(instagram_min), 1)     AS instagram_min,
    ROUND(AVG(youtube_min), 1)       AS youtube_min,
    ROUND(AVG(whatsapp_min), 1)      AS whatsapp_min,
    MODE() WITHIN GROUP (ORDER BY most_used_platform) AS most_common_top_platform
FROM screen_time
GROUP BY occupation
ORDER BY users DESC;


/* ---------------------------------------------------------------------
   Q12. CORRELATIONS  (what actually drives screen time?)
   --------------------------------------------------------------------- */
SELECT
    ROUND(corr(age, daily_screen_time_hrs)::numeric, 3)                 AS age_vs_screen,
    ROUND(corr(night_usage_min, daily_screen_time_hrs)::numeric, 3)     AS night_vs_screen,
    ROUND(corr(notifications_per_day, phone_pickups_per_day)::numeric, 3) AS notif_vs_pickups,
    ROUND(corr(age, snapchat_min)::numeric, 3)                          AS age_vs_snapchat
FROM screen_time;


/* ---------------------------------------------------------------------
   Q13. LOCATION ANALYSIS: DISTANCE OF EACH CITY FROM PUNE
   Haversine formula in plain SQL (no PostGIS needed).
   Useful for planning a regional rollout from a Pune head office.
   --------------------------------------------------------------------- */
WITH centroids AS (
    SELECT city,
           AVG(latitude)  AS lat,
           AVG(longitude) AS lon,
           ROUND(AVG(daily_screen_time_hrs), 2) AS avg_screen_hrs
    FROM screen_time
    GROUP BY city
),
pune AS (
    SELECT lat AS plat, lon AS plon FROM centroids WHERE city = 'Pune'
)
SELECT
    c.city,
    c.avg_screen_hrs,
    ROUND((2 * 6371 * ASIN(SQRT(
        POWER(SIN(RADIANS(c.lat - p.plat) / 2), 2) +
        COS(RADIANS(p.plat)) * COS(RADIANS(c.lat)) *
        POWER(SIN(RADIANS(c.lon - p.plon) / 2), 2)
    )))::numeric) AS km_from_pune
FROM centroids c CROSS JOIN pune p
ORDER BY km_from_pune;


/* ---------------------------------------------------------------------
   Q14. FINAL RECOMMENDATION: CAMPAIGN PRIORITY SCORE
   Combine three signals per city into one 0-100 score using
   PERCENT_RANK, so no single metric dominates because of its scale:
       40%  average daily screen time
       30%  average night usage (sleep impact)
       30%  average social-media minutes
   --------------------------------------------------------------------- */
WITH city_metrics AS (
    SELECT
        city,
        state,
        COUNT(*)                      AS users,
        AVG(daily_screen_time_hrs)    AS screen_hrs,
        AVG(night_usage_min)          AS night_min,
        AVG(total_social_min)         AS social_min
    FROM screen_time
    GROUP BY city, state
),
scored AS (
    SELECT *,
        100 * (0.40 * PERCENT_RANK() OVER (ORDER BY screen_hrs) +
               0.30 * PERCENT_RANK() OVER (ORDER BY night_min)  +
               0.30 * PERCENT_RANK() OVER (ORDER BY social_min)) AS priority_score
    FROM city_metrics
)
SELECT
    RANK() OVER (ORDER BY priority_score DESC) AS priority,
    city,
    state,
    users,
    ROUND(screen_hrs::numeric, 2)  AS avg_screen_hrs,
    ROUND(night_min::numeric)      AS avg_night_min,
    ROUND(social_min::numeric)     AS avg_social_min,
    ROUND(priority_score::numeric, 1) AS priority_score
FROM scored
ORDER BY priority
LIMIT 5;


/* ---------------------------------------------------------------------
   Q15. PRODUCTIONISE IT: A VIEW + A MATERIALIZED VIEW
   Dashboards should query these, not the raw table.
   --------------------------------------------------------------------- */
CREATE OR REPLACE VIEW v_city_summary AS
SELECT
    city, state, area_type,
    COUNT(*)                              AS users,
    ROUND(AVG(daily_screen_time_hrs), 2)  AS avg_screen_hrs,
    ROUND(AVG(total_social_min))          AS avg_social_min,
    ROUND(AVG(night_usage_min))           AS avg_night_min
FROM screen_time
GROUP BY city, state, area_type;

DROP MATERIALIZED VIEW IF EXISTS mv_platform_by_city;
CREATE MATERIALIZED VIEW mv_platform_by_city AS
SELECT city, most_used_platform, COUNT(*) AS users
FROM screen_time
GROUP BY city, most_used_platform;

CREATE INDEX idx_mv_platform_city ON mv_platform_by_city (city);
-- After new data is loaded:  REFRESH MATERIALIZED VIEW mv_platform_by_city;

SELECT * FROM v_city_summary ORDER BY avg_screen_hrs DESC LIMIT 5;

-- Check that the index is actually used
EXPLAIN SELECT * FROM screen_time WHERE city = 'Pune';
