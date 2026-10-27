-- ==================================================
-- Analysis 05: Delivery performance by customer state
-- 
-- Grain: One row per customer state
-- Population: Orders with valid delivery timelines
-- 
-- Customer state is used as a proxy for destination.
-- ==================================================

WITH state_orders AS (
    SELECT 
        d.order_id,
        c.customer_state,
        d.delivery_delay_days,
        d.delivery_days,
        d.is_late_delivery,
        d.review_score,
        d.has_conflicting_scores
    FROM analytics.order_delivery_performance AS d 
    JOIN analytics.dim_customers AS c 
        ON d.customer_id = c.customer_id 
    WHERE d.has_valid_delivery_timeline
)

SELECT 
    customer_state,

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

    ROUND(
        AVG(delivery_days),
        2
    ) AS avg_delivery_days,

    ROUND(
        AVG(delivery_delay_days),
        2
    ) AS avg_estimate_error_days,

    COUNT(*) FILTER (
        WHERE review_score IS NOT NULL
          AND has_conflicting_scores IS NOT TRUE
    ) AS reviewed_orders,

    ROUND(
        AVG(review_score) FILTER (
            WHERE has_conflicting_scores IS NOT TRUE
        ),
        2
    ) AS avg_review_score,

    ROUND(
        100.0 * COUNT(*) FILTER (
            WHERE review_score <= 2
              AND has_conflicting_scores IS NOT TRUE
        )
        / NULLIF(
            COUNT(*) FILTER (
                WHERE review_score IS NOT NULL
                  AND has_conflicting_scores IS NOT TRUE
            ),
            0
        ),
        2
    ) AS low_review_pct

FROM state_orders
GROUP BY customer_state
ORDER BY late_delivery_pct DESC;