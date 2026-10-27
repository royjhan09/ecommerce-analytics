-- ==================================================
-- Olist E-Commerce Analytics
-- Analysis 03: Delivery Estimate Accuracy
--
-- Grain: One row per delivered order
-- Population: Valid delivered orders
-- Reviews are NOT required
-- ==================================================

WITH delivery_metrics AS (
    SELECT 
        order_id,
        order_purchase_timestamp,
        order_estimated_delivery_date,
        order_delivered_customer_date,

        -- Promised delivery duration in calender days 
        (order_estimated_delivery_date::DATE 
            - order_purchase_timestamp::DATE 
        ) AS promised_days,

        -- Actual delivery duration in calender days 
        delivery_days AS actual_days,

        -- Negative = early, Positive = late
        delivery_delay_days

    FROM analytics.order_delivery_performance
    WHERE has_valid_delivery_timeline
)

SELECT
    COUNT(*) AS delivered_orders,
    
    ROUND(AVG(promised_days), 2)
        AS avg_promised_days,

    ROUND(AVG(actual_days), 2)
        AS avg_actual_days,

    ROUND(AVG(delivery_delay_days), 2)
        AS avg_delivery_delay_days,

    ROUND(
        AVG(delivery_delay_days)
            FILTER (WHERE delivery_delay_days < 0),
        2
    ) AS avg_early_days,

    ROUND(
        100.0 * COUNT(*)
            FILTER (WHERE delivery_delay_days < 0)
        / NULLIF(COUNT(*), 0),
        2
    ) AS early_delivery_pct,

    ROUND(
        100.0 * COUNT(*)
            FILTER (WHERE delivery_delay_days = 0)
        / NULLIF(COUNT(*), 0),
        2
    ) AS on_time_pct,

    ROUND(
        100.0 * COUNT(*)
            FILTER (WHERE delivery_delay_days > 0)
        / NULLIF(COUNT(*), 0),
        2
    ) AS late_delivery_pct

FROM delivery_metrics;

