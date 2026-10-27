-- ==================================================
-- Analysis 07: Delivery reliability by state
-- 
-- Population: Valid delivered orders
-- Grain: One row per customer state
-- ==================================================

SELECT 
    c.customer_state,
    COUNT(*) AS delivered_orders,

    ROUND(
        AVG(d.delivery_delay_days), 2
    ) AS mean_error_days,

    PERCENTILE_CONT(0.5) WITHIN GROUP (
        ORDER BY d.delivery_delay_days
    ) AS median_error_days,

    PERCENTILE_CONT(0.9) WITHIN GROUP (
        ORDER BY d.delivery_delay_days
    ) AS p90_error_days,

    PERCENTILE_CONT(0.95) WITHIN GROUP (
        ORDER BY d.delivery_delay_days
    ) AS p95_error_days,

    ROUND(
        100.0 * COUNT(*) FILTER (
            WHERE d.delivery_delay_days >= 7
        ) / COUNT(*),
        2
    ) AS seven_plus_days_late_pct

FROM analytics.order_delivery_performance AS d 
JOIN analytics.dim_customers AS c 
    ON d.customer_id = c.customer_id
WHERE d.has_valid_delivery_timeline
  AND c.customer_state IN ('SP', 'RJ', 'RS', 'MG', 'BA')
GROUP BY c.customer_state
ORDER BY p90_error_days DESC;