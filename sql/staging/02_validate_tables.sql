-- ==================================================
-- Olist e-Commerce Analytics
-- Staging validation
-- 
-- Compare staging against raw source data.
-- Report all failures and raise an exception if any fail.
-- ==================================================

CREATE TEMP TABLE staging_validation_results (
    test_name TEXT,
    passed BOOLEAN
);

-- 1. Row counts: all nine datasets

DO $$
DECLARE
    table_name TEXT;
    raw_count BIGINT;
    staging_count BIGINT;
BEGIN
    FOREACH table_name IN ARRAY ARRAY[
        'orders',
        'customers',
        'order_items',
        'order_payments',
        'order_reviews',
        'geolocation',
        'sellers',
        'products',
        'product_category_name_translation'
    ]
    LOOP
        EXECUTE format(
            'SELECT COUNT(*) FROM raw.%I',
            table_name
        ) INTO raw_count;

        EXECUTE format(
            'SELECT COUNT(*) FROM staging.%I',
            table_name
        ) INTO staging_count;

        INSERT INTO staging_validation_results
        VALUES (
            'row_count_' || table_name,
            raw_count = staging_count
        );
    END LOOP;
END
$$;

-- 2. Orders: timestamp null counts

INSERT INTO staging_validation_results
SELECT 
    'orders_approved_nulls',
    (SELECT COUNT(*) FROM raw.orders
     WHERE order_approved_at IS NULL)
    =
    (SELECT COUNT(*) FROM staging.orders
     WHERE order_approved_at IS NULL)

UNION ALL 
SELECT 
    'orders_carrier_nulls',
    (SELECT COUNT(*) FROM raw.orders
     WHERE order_delivered_carrier_date IS NULL)
    =
    (SELECT COUNT(*) FROM staging.orders
     WHERE order_delivered_carrier_date IS NULL)
    
UNION ALL 
SELECT 
    'orders_delivery_nulls',
    (SELECT COUNT(*) FROM raw.orders
     WHERE order_delivered_customer_date IS NULL)
    =
    (SELECT COUNT(*) FROM staging.orders
     WHERE order_delivered_customer_date IS NULL);

-- 3. Timestamp column types

INSERT INTO staging_validation_results
SELECT 
    'orders_timestamp_types',
    COUNT(*) = 5
FROM information_schema.columns
WHERE table_schema = 'staging'
  AND table_name = 'orders'
  AND column_name IN (
    'order_purchase_timestamp',
    'order_approved_at',
    'order_delivered_carrier_date',
    'order_delivered_customer_date',
    'order_estimated_delivery_date'
  )
  AND data_type = 'timestamp without time zone';

INSERT INTO staging_validation_results
SELECT 
    'items_shipping_timestamp_type',
    COUNT(*) = 1
FROM information_schema.columns
WHERE table_schema = 'staging'
  AND table_name = 'order_items'
  AND column_name = 'shipping_limit_date'
  AND data_type = 'timestamp without time zone';

INSERT INTO staging_validation_results
SELECT 
    'reviews_timestamp_types',
    COUNT(*) = 2
FROM information_schema.columns
WHERE table_schema = 'staging'
  AND table_name = 'order_reviews'
  AND column_name IN (
    'review_creation_date',
    'review_answer_timestamp'
  )
  AND data_type = 'timestamp without time zone';


-- 4. ZIP-prefix formatting

INSERT INTO staging_validation_results
SELECT 
    'customer_zip_format',
    COUNT(*) FILTER (
        WHERE customer_zip_code_prefix IS NULL
           OR customer_zip_code_prefix !~ '^[0-9]{5}$'
    ) = 0
FROM staging.customers

UNION ALL 
SELECT 
    'sellers_zip_format',
    COUNT(*) FILTER (
        WHERE seller_zip_code_prefix IS NULL
           OR seller_zip_code_prefix !~ '^[0-9]{5}$'
    ) = 0
FROM staging.sellers

UNION ALL 
SELECT 
    'geolocation_zip_format',
    COUNT(*) FILTER (
        WHERE geolocation_zip_code_prefix IS NULL
           OR geolocation_zip_code_prefix !~ '^[0-9]{5}$'
    ) = 0
FROM staging.geolocation;

-- 5. Product column-name standardization

INSERT INTO staging_validation_results
SELECT 
    'products_renamed_columns',
    COUNT(*) = 2
FROM information_schema.columns
WHERE table_schema = 'staging'
  AND table_name = 'products'
  AND column_name IN (
    'product_name_length',
    'product_description_length'
  );

-- 6. Financial measure reconciliation

INSERT INTO staging_validation_results
SELECT 
    'order_items_price_total',
    (SELECT SUM(price) FROM raw.order_items)
    =
    (SELECT SUM(price) FROM staging.order_items)

UNION ALL 
SELECT 
    'order_items_freight_total',
    (SELECT SUM(freight_value) FROM raw.order_items)
    =
    (SELECT SUM(freight_value) FROM staging.order_items)

UNION ALL 
SELECT 
    'order_payments_value_total',
    (SELECT SUM(payment_value) FROM raw.order_payments)
    =
    (SELECT SUM(payment_value) FROM staging.order_payments);

-- 7. Referential integrity

INSERT INTO staging_validation_results 
SELECT 
    'orders_customer_reference',
    NOT EXISTS (
        SELECT 1
        FROM staging.orders o 
        LEFT JOIN staging.customers c 
            ON o.customer_id = c.customer_id
        WHERE c.customer_id IS NULL
    )

UNION ALL 
SELECT 
    'items_order_reference',
    NOT EXISTS (
        SELECT 1 
        FROM staging.order_items i 
        LEFT JOIN staging.orders o
            ON i.order_id = o.order_id 
        WHERE o.order_id IS NULL
    )

UNION ALL 
SELECT 
    'items_seller_reference',
    NOT EXISTS (
        SELECT 1
        FROM staging.order_items i 
        LEFT JOIN staging.sellers s 
            ON i.seller_id = s.seller_id
        WHERE s.seller_id IS NULL
    )

UNION ALL 
SELECT 
    'payments_order_reference',
    NOT EXISTS (
        SELECT 1
        FROM staging.order_payments p 
        LEFT JOIN staging.orders o 
            ON p.order_id = o.order_id 
        WHERE o.order_id IS NULL
    )

UNION ALL 
SELECT 
    'reviews_order_reference',
    NOT EXISTS (
        SELECT 1 
        FROM staging.order_reviews r 
        LEFT JOIN staging.orders o 
            ON r.order_id = o.order_id 
        WHERE o.order_id IS NULL
    )
    
UNION ALL 
SELECT 
    'items_product_reference',
    NOT EXISTS (
        SELECT 1
        FROM  staging.order_items i 
        LEFT JOIN staging.products p 
            ON i.product_id = p.product_id 
        WHERE p.product_id IS NULL
    );

-- 8. Display validation results

SELECT 
    test_name,
    CASE 
        WHEN passed THEN 'PASS'
        ELSE 'FAIL'
    END AS status
FROM staging_validation_results
ORDER BY test_name;

-- 9. Stop execution if any check fails

DO $$ 
DECLARE 
    failed_tests TEXT;
BEGIN 
    SELECT STRING_AGG(test_name, ', ' ORDER BY test_name)
    INTO failed_tests
    FROM staging_validation_results
    WHERE passed IS DISTINCT FROM TRUE;

    IF failed_tests IS NOT NULL THEN
        RAISE EXCEPTION
            'Staging validation failed: %',
            failed_tests;
    END IF;

    RAISE NOTICE 'All staging validations passed.';
END
$$;