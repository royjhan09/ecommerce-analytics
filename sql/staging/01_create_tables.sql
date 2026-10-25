-- ==================================================
-- Olist E-Commerce Analytics
-- Staging: Nine datasets
-- 
-- Preserve row counts and source-level grains.
-- Run as a single transaction.
-- ==================================================

-- 1. Orders
DROP TABLE IF EXISTS staging.orders;

CREATE TABLE staging.orders AS 
SELECT  
    order_id,
    customer_id,
    order_status,

    order_purchase_timestamp::TIMESTAMP
        AS order_purchase_timestamp,
    
    order_approved_at::TIMESTAMP
        AS order_approved_at,
    
    order_delivered_carrier_date::TIMESTAMP
        AS order_delivered_carrier_date,

    order_delivered_customer_date::TIMESTAMP
        AS order_delivered_customer_date,

    order_estimated_delivery_date::TIMESTAMP
        AS order_estimated_delivery_date

FROM raw.orders;

ALTER TABLE staging.orders
    ADD CONSTRAINT pk_staging_orders
    PRIMARY KEY (order_id);



-- 2. Customers
DROP TABLE IF EXISTS staging.customers;

CREATE TABLE staging.customers AS 
SELECT 
    customer_id,
    customer_unique_id,
    LPAD(customer_zip_code_prefix, 5, '0')
        AS customer_zip_code_prefix,
    customer_city,
    customer_state
FROM raw.customers;

ALTER TABLE staging.customers
    ADD CONSTRAINT pk_staging_customers
    PRIMARY KEY (customer_id);


-- 3. Order Items
DROP TABLE IF EXISTS staging.order_items;

CREATE TABLE staging.order_items AS 
SELECT 
    order_id,
    order_item_id,
    product_id,
    seller_id,
    shipping_limit_date::TIMESTAMP AS shipping_limit_date,
    price,
    freight_value
FROM raw.order_items;

ALTER TABLE staging.order_items
    ADD CONSTRAINT pk_staging_order_items
    PRIMARY KEY (order_id, order_item_id);


-- 4. Order Payments
DROP TABLE IF EXISTS staging.order_payments;

CREATE TABLE staging.order_payments AS 
SELECT 
    order_id,
    payment_sequential,
    payment_type,
    payment_installments,
    payment_value
FROM raw.order_payments;

ALTER TABLE staging.order_payments
    ADD CONSTRAINT pk_staging_order_payments
    PRIMARY KEY (order_id, payment_sequential);


-- 5. Order Reviews
DROP TABLE IF EXISTS staging.order_reviews;

CREATE TABLE staging.order_reviews AS 
SELECT 
    review_id,
    order_id,
    review_score,
    review_comment_title,
    review_comment_message,
    review_creation_date::TIMESTAMP AS review_creation_date,
    review_answer_timestamp::TIMESTAMP AS review_answer_timestamp
FROM raw.order_reviews;

ALTER TABLE staging.order_reviews
    ADD CONSTRAINT pk_staging_order_reviews
    PRIMARY KEY (review_id, order_id);


-- 6. Geolocation
DROP TABLE IF EXISTS staging.geolocation;

CREATE TABLE staging.geolocation AS
SELECT 
    LPAD(geolocation_zip_code_prefix, 5, '0')
        AS geolocation_zip_code_prefix,
    geolocation_lat,
    geolocation_lng,
    geolocation_city,
    geolocation_state
FROM raw.geolocation;

-- Intentionally no primary key:
-- ZIP prefixes and complete records can repeat.


-- 7. Sellers
DROP TABLE IF EXISTS staging.sellers;

CREATE TABLE staging.sellers AS 
SELECT 
    seller_id,
    LPAD(seller_zip_code_prefix, 5, '0')
        AS seller_zip_code_prefix,
    seller_city,
    seller_state
FROM raw.sellers;

ALTER TABLE staging.sellers
    ADD CONSTRAINT pk_staging_sellers
    PRIMARY KEY (seller_id);


-- 8. Products
DROP TABLE IF EXISTS staging.products;

CREATE TABLE staging.products AS 
SELECT 
    product_id,
    product_category_name,
    product_name_lenght AS product_name_length,
    product_description_lenght AS product_description_length,
    product_photos_qty,
    product_weight_g,
    product_length_cm,
    product_height_cm,
    product_width_cm
FROM raw.products;

ALTER TABLE staging.products
    ADD CONSTRAINT pk_staging_products
    PRIMARY KEY (product_id);


-- 9. Product Category Translation
DROP TABLE IF EXISTS staging.product_category_name_translation;

CREATE TABLE staging.product_category_name_translation AS 
SELECT 
    product_category_name,
    product_category_name_english
FROM raw.product_category_name_translation;

ALTER TABLE staging.product_category_name_translation
    ADD CONSTRAINT pk_staging_category_translation
    PRIMARY KEY (product_category_name);