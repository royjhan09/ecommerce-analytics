-- ==================================================
-- Olist E-Commerce Analytics
-- Analytics: Order-Level fact table
-- 
-- Grain: one row per order_id
-- ==================================================

DROP TABLE IF EXISTS analytics.fact_orders;

CREATE TABLE analytics.fact_orders AS 
WITH items_by_order AS (
    SELECT 
        order_id,
        COUNT(*) AS item_count,
        SUM(price) AS item_value,
        SUM(freight_value) AS freight_value
    FROM staging.order_items
    GROUP BY order_id
),
payments_by_order AS (
    SELECT 
        order_id,
        COUNT(*) AS payment_count,
        SUM(payment_value) AS payment_value
    FROM staging.order_payments
    GROUP BY order_id
)
SELECT 
    o.order_id,
    o.customer_id,
    o.order_status,
    o.order_purchase_timestamp,
    o.order_approved_at,
    o.order_delivered_carrier_date,
    o.order_delivered_customer_date,
    o.order_estimated_delivery_date,

    COALESCE(i.item_count, 0) AS item_count,
    i.item_value,
    i.freight_value,

    COALESCE(p.payment_count, 0) AS payment_count,
    p.payment_value

FROM staging.orders AS o
LEFT JOIN items_by_order AS i 
    ON o.order_id = i.order_id
LEFT JOIN payments_by_order AS p 
    ON o.order_id = p.order_id;

ALTER TABLE analytics.fact_orders
    ADD CONSTRAINT pk_fact_orders
    PRIMARY KEY (order_id);