-- ==============================================
-- Olist E-Commerce Analytics
-- Load source CSV files into raw schema
--
-- Run from project root using psql.
-- Intended for a fresh or explicitly reset raw layer.
-- Source CSV files are expected to be UTF-8 encoded.
-- ==============================================

-- Full refresh of source tables.
-- Run this script with psql --single-transaction (-1)

TRUNCATE TABLE 
    raw.orders,
    raw.customers,
    raw.order_items,
    raw.order_payments,
    raw.order_reviews,
    raw.geolocation,
    raw.sellers,
    raw.products,
    raw.product_category_name_translation;

SET client_encoding = 'UTF8';

\copy raw.orders FROM 'data/raw/olist_orders_dataset.csv' WITH (FORMAT csv, HEADER true, NULL '');

\copy raw.customers FROM 'data/raw/olist_customers_dataset.csv' WITH (FORMAT csv, HEADER true, NULL '');

\copy raw.order_items FROM 'data/raw/olist_order_items_dataset.csv' WITH (FORMAT csv, HEADER true, NULL '');

\copy raw.order_payments FROM 'data/raw/olist_order_payments_dataset.csv' WITH (FORMAT csv, HEADER true, NULL '');

\copy raw.order_reviews FROM 'data/raw/olist_order_reviews_dataset.csv' WITH (FORMAT csv, HEADER true, NULL '');

\copy raw.geolocation FROM 'data/raw/olist_geolocation_dataset.csv' WITH (FORMAT csv, HEADER true, NULL '');

\copy raw.sellers FROM 'data/raw/olist_sellers_dataset.csv' WITH (FORMAT csv, HEADER true, NULL '');

\copy raw.products FROM 'data/raw/olist_products_dataset.csv' WITH (FORMAT csv, HEADER true, NULL '');

\copy raw.product_category_name_translation FROM 'data/raw/product_category_name_translation.csv' WITH (FORMAT csv, HEADER true, NULL '');