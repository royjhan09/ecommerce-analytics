-- ==================================================
-- Analysis 08: Interstate shipping and delivery performance
-- 
-- Grain of analysis: one row per order
-- Population:
--   - Valid delivered orders
--   - Exactly one distinct seller per order
-- 
-- Customer state is used as a destination proxy.
-- ==================================================

WITH sellers_by_order AS (
    SELECT 
        i.order_id,
        COUNT(DISTINCT i.seller_id) AS seller_count,
        MIN(i.seller_id) AS seller_id
    FROM analytics.fact_order_items AS i 
    GROUP BY i.order_id
),

single_seller_deliveries AS (
    SELECT 
        d.order_id,
        c.customer_state,
        s.seller_state,
        d.delivery_days,
        d.delivery_delay_days,
        d.is_late_delivery,

        d.order_estimated_delivery_date::DATE 
            - d.order_purchase_timestamp::DATE 
            AS promised_days,

        CASE 
            WHEN c.customer_state = s.seller_state
                THEN 'Same-state'
            ELSE 'Interstate'
        END AS shipping_type

    FROM analytics.order_delivery_performance AS d 

    JOIN sellers_by_order AS so 
        ON d.order_id = so.order_id 
       AND so.seller_count = 1

    JOIN analytics.dim_sellers AS s 
        ON so.seller_id = s.seller_id

    JOIN analytics.dim_customers AS c 
        ON d.customer_id = c.customer_id 
    
    WHERE d.has_valid_delivery_timeline
      AND c.customer_state IS NOT NULL 
      AND s.seller_state IS NOT NULL
),

analysis_populations AS (
    -- Overall comparison
    SELECT 
        'All states' AS population,
        shipping_type,
        delivery_days,
        promised_days,
        delivery_delay_days,
        is_late_delivery
    FROM single_seller_deliveries

    UNION ALL 

    -- Focused RJ comparison
    SELECT 
        'RJ only' AS population,
        shipping_type,
        delivery_days,
        promised_days,
        delivery_delay_days,
        is_late_delivery
    FROM single_seller_deliveries
    WHERE customer_state = 'RJ'
)

SELECT 
    population,
    shipping_type,
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
        ) / NULLIF(COUNT(*), 0),
        2
    ) AS late_delivery_pct,

    ROUND(
        100.0 * COUNT(*) FILTER (
            WHERE delivery_delay_days >= 7
        ) / NULLIF(COUNT(*), 0),
        2
    ) AS seven_plus_days_late_pct

FROM analysis_populations
GROUP BY population, shipping_type
ORDER BY population, shipping_type;