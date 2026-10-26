-- ==================================================
-- Olist E-Commerce Analytics
-- Analytics: Order-item-level fact table
-- 
-- Grain: one row per (order_id, order_item_id)
-- ==================================================

DROP TABLE IF EXISTS analytics.fact_order_items;

CREATE TABLE analytics.fact_order_items AS 
SELECT 
    order_id,
    order_item_id,
    product_id,
    seller_id,
    shipping_limit_date,
    price AS item_price,
    freight_value AS item_freight_value
FROM staging.order_items;

ALTER TABLE analytics.fact_order_items
    ADD CONSTRAINT pk_fact_order_items
    PRIMARY KEY (order_id, order_item_id);