-- ==================================================
-- Olist E-Commerce Analytics
-- Analysis 02: Daily delivery delay vs reviews
--
-- Grain: one row per delivery delay day
-- Population: valid delivered orders with reviews
-- Excludes conflicting review scores
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
)

SELECT 
    delivery_delay_days,
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

FROM reviewed_deliveries
WHERE delivery_delay_days BETWEEN -5 AND 20 
GROUP BY delivery_delay_days
ORDER BY delivery_delay_days;