-- ==================================================
-- Analysis 04: Distribution of delivery estimate errors
-- Population: All valid delivered orders
-- Grain: One row per delivery delay day
-- ==================================================

SELECT 
    delivery_delay_days,
    COUNT(*) AS order_count
FROM analytics.order_delivery_performance
WHERE has_valid_delivery_timeline
GROUP BY delivery_delay_days
ORDER BY delivery_delay_days;