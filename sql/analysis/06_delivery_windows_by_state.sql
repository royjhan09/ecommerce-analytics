-- ==================================================
-- Analysis 06: Delivery windows by customer state
-- Grain: one row per customer state
-- Population: valid delivered orders
-- ==================================================

WITH state_deliveries AS (
    SELECT 
        c.customer_state,
        d.order_id,
        d.delivery_days,
        d.delivery_delay_days,
        (
            d.order_estimated_delivery_date::DATE 
            - d.order_purchase_timestamp::DATE
        ) AS promised_days,
        d.is_late_delivery
    FROM analytics.order_delivery_performance AS d 
    JOIN analytics.dim_customers AS c 
        ON d.customer_id = c.customer_id
    WHERE d.has_valid_delivery_timeline
)
SELECT 
    customer_state,
    COUNT(*) AS delivered_orders,

    ROUND(AVG(promised_days), 2)
        AS avg_promised_days,

    ROUND(AVG(delivery_days), 2)
        AS avg_actual_days,

    ROUND(AVG(delivery_delay_days), 2)
        AS avg_estimate_error_days,
    
    ROUND(
        100.0 * COUNT(*) FILTER (
            WHERE is_late_delivery
        ) / COUNT(*),
        2
    ) AS late_delivery_pct

FROM state_deliveries
GROUP BY customer_state
ORDER BY delivered_orders DESC;