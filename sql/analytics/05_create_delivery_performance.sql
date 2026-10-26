-- ==================================================
-- Olist E-Commerce Analytics
-- Analytics: Delivery performance and customer reviews
-- 
-- Grain: one row per order_id
-- ==================================================

DROP TABLE IF EXISTS analytics.order_delivery_performance;

CREATE TABLE analytics.order_delivery_performance AS 
WITH delivery_base AS (
    SELECT 
        o.order_id,
        o.customer_id,
        o.order_status,
        o.order_purchase_timestamp,
        o.order_delivered_customer_date,
        o.order_estimated_delivery_date,

        r.review_score,
        r.review_count,
        r.has_conflicting_scores,

        (
            o.order_status = 'delivered'
            AND o.order_purchase_timestamp IS NOT NULL
            AND o.order_delivered_customer_date IS NOT NULL
            AND o.order_estimated_delivery_date IS NOT NULL
            AND o.order_delivered_customer_date
                >= o.order_purchase_timestamp
        ) AS has_valid_delivery_timeline

    FROM analytics.fact_orders AS o
    LEFT JOIN analytics.order_review_summary AS r 
        ON o.order_id = r.order_id
)
SELECT 
    order_id,
    customer_id,
    order_status,
    order_purchase_timestamp,
    order_delivered_customer_date,
    order_estimated_delivery_date,

    review_score,
    review_count,
    has_conflicting_scores,
    has_valid_delivery_timeline,

    CASE
        WHEN has_valid_delivery_timeline THEN 
            order_delivered_customer_date::DATE 
            - order_purchase_timestamp::DATE 
    END AS delivery_days,

    CASE 
        WHEN has_valid_delivery_timeline THEN
            order_delivered_customer_date::DATE 
            - order_estimated_delivery_date::DATE 
    END AS delivery_delay_days,

    CASE 
        WHEN has_valid_delivery_timeline THEN 
            order_delivered_customer_date::DATE 
            > order_estimated_delivery_date::DATE 
    END AS is_late_delivery

FROM delivery_base;

ALTER TABLE analytics.order_delivery_performance
    ADD CONSTRAINT pk_order_delivery_performance
    PRIMARY KEY (order_id);