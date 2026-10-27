
-- ==================================================
-- Analysis 09: Seller-origin states for RJ deliveries
--
-- Final grain: one row per seller-origin state
-- Population:
--   - Valid delivered orders to RJ customers
--   - Exactly one distinct seller per order
--
-- Customer state is a destination proxy.
-- Seller state is a seller-location proxy.
-- ==================================================

WITH sellers_by_order AS (
    SELECT
        order_id,
        COUNT(DISTINCT seller_id) AS seller_count,
        MIN(seller_id) AS seller_id
    FROM analytics.fact_order_items
    GROUP BY order_id
),

rj_orders AS (
    SELECT
        d.order_id,
        s.seller_state,
        d.delivery_days,
        d.delivery_delay_days,
        d.is_late_delivery,

        d.order_estimated_delivery_date::DATE
            - d.order_purchase_timestamp::DATE
            AS promised_days

    FROM analytics.order_delivery_performance AS d

    JOIN analytics.dim_customers AS c
        ON d.customer_id = c.customer_id

    JOIN sellers_by_order AS so
        ON d.order_id = so.order_id
       AND so.seller_count = 1

    JOIN analytics.dim_sellers AS s
        ON so.seller_id = s.seller_id

    WHERE d.has_valid_delivery_timeline
      AND c.customer_state = 'RJ'
      AND s.seller_state IS NOT NULL
)

SELECT
    seller_state AS origin_state,

    CASE
        WHEN seller_state = 'RJ' THEN 'Same-state'
        ELSE 'Interstate'
    END AS shipping_type,

    COUNT(*) AS delivered_orders,

    COUNT(*) FILTER (
        WHERE is_late_delivery
    ) AS late_orders,

    ROUND(
        100.0 * COUNT(*) FILTER (
            WHERE is_late_delivery
        ) / NULLIF(COUNT(*), 0),
        2
    ) AS late_delivery_pct,

    COUNT(*) FILTER (
        WHERE delivery_delay_days >= 7
    ) AS seven_plus_days_late_orders,

    ROUND(
        100.0 * COUNT(*) FILTER (
            WHERE delivery_delay_days >= 7
        ) / NULLIF(COUNT(*), 0),
        2
    ) AS seven_plus_days_late_pct,

    ROUND(AVG(promised_days), 2)
        AS avg_promised_days,

    ROUND(AVG(delivery_days), 2)
        AS avg_actual_days,

    ROUND(AVG(delivery_delay_days), 2)
        AS avg_estimate_error_days

FROM rj_orders
GROUP BY seller_state
ORDER BY late_orders DESC;
