-- ==================================================
-- Olist E-Commerce Analytics
-- Analytics: Core dimensions
-- 
-- Grain:
--   dim_products:  one row per product_id
--   dim_customers: one row per customer_id
--   dim_sellers:   one row per seller_id
-- ==================================================

-- 1. Product dimension

DROP TABLE IF EXISTS analytics.dim_products;

CREATE TABLE analytics.dim_products AS 
SELECT 
    p.product_id,
    p.product_category_name,
    t.product_category_name_english,
    p.product_name_length,
    p.product_description_length,
    p.product_photos_qty,
    p.product_weight_g,
    p.product_length_cm,
    p.product_height_cm,
    p.product_width_cm
FROM staging.products AS p
LEFT JOIN staging.product_category_name_translation AS t 
    ON p.product_category_name = t.product_category_name;

ALTER TABLE analytics.dim_products
    ADD CONSTRAINT pk_dim_products
    PRIMARY KEY (product_id);


-- 2. Customer dimension

DROP TABLE IF EXISTS analytics.dim_customers;

CREATE TABLE analytics.dim_customers AS 
SELECT 
    customer_id,
    customer_unique_id,
    customer_zip_code_prefix,
    customer_city,
    customer_state
FROM staging.customers;

ALTER TABLE analytics.dim_customers
    ADD CONSTRAINT pk_dim_customers
    PRIMARY KEY (customer_id);


-- 3. Seller dimension

DROP TABLE IF EXISTS analytics.dim_sellers;

CREATE TABLE analytics.dim_sellers AS 
SELECT 
    seller_id,
    seller_zip_code_prefix,
    seller_city,
    seller_state
FROM staging.sellers;

ALTER TABLE analytics.dim_sellers
    ADD CONSTRAINT pk_dim_sellers
    PRIMARY KEY (seller_id);