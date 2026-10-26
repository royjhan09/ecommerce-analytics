-- ==================================================
-- Olist E-Commerce Analytics
-- Analysis 01: Delivery delay severity vs reviews
-- 
-- Grain of input: one row per order
-- Population: valid delivered orders with a review
-- Excludes conflicting review scores for baseline
-- ==================================================

WITH reviewed_deliveries AS (
    SELECT 
        order_id,
        delivery_delay_days,
        review_score
    FROM analytics.order_delivery_performance
    WHERE has_valid_delivery_timeline
      AND review_score IS NOT NULL
      AND has_conflicting_scores IS NOT TRUE 
),

delay_segments AS (
    SELECT 
        order_id,
        review_score,
        CASE 
            WHEN delivery_delay_days < 0 THEN 'Early'
            WHEN delivery_delay_days = 0 THEN 'On time'
            WHEN delivery_delay_days BETWEEN 1 AND 3 THEN '1-3 days late'
            WHEN delivery_delay_days BETWEEN 4 AND 7 THEN '4-7 days late'
            WHEN delivery_delay_days BETWEEN 8 AND 14 THEN '8-14 days late'
            ELSE '15+ days late'
        END AS delay_segment,

        CASE 
            WHEN delivery_delay_days < 0 THEN 1 
            WHEN delivery_delay_days = 0 THEN 2
            WHEN delivery_delay_days BETWEEN 1 AND 3 THEN 3 
            WHEN delivery_delay_days BETWEEN 4 AND 7 THEN 4 
            WHEN delivery_delay_days BETWEEN 8 AND 14 THEN 5
            ELSE 6
        END AS segment_order
    FROM reviewed_deliveries
)

SELECT 
    delay_segment,
    COUNT(*) AS reviewed_orders,

    ROUND(
        AVG(review_score),
        2
    ) AS avg_review_score,

    ROUND(
        100.0 * COUNT(*) FILTER (
            WHERE review_score <= 2
        ) / COUNT(*),
        2
    ) AS low_review_pct,

    ROUND(
        100.0 * COUNT(*) FILTER (
            WHERE review_score = 5
        ) / COUNT(*),
        2
    ) AS five_star_pct
    
FROM delay_segments
GROUP BY segment_order, delay_segment
ORDER BY segment_order;