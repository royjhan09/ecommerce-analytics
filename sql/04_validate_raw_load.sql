-- ==================================================
-- Validate raw table row counts
-- ==================================================

WITH row_counts AS (
    SELECT 'orders' AS table_name, 99441 AS expected, COUNT(*) AS actual
    FROM raw.orders

    UNION ALL 
    SELECT 'customers', 99441, COUNT(*)
    FROM raw.customers

    UNION ALL 
    SELECT 'order_items', 112650, COUNT(*)
    FROM raw.order_items

    UNION ALL 
    SELECT 'order_payments', 103886, COUNT(*)
    FROM raw.order_payments

    UNION ALL 
    SELECT 'order_reviews', 99224, COUNT(*)
    FROM raw.order_reviews

    UNION ALL 
    SELECT 'geolocation', 1000163, COUNT(*)
    FROM raw.geolocation

    UNION ALL 
    SELECT 'sellers', 3095, COUNT(*)
    FROM raw.sellers

    UNION ALL 
    SELECT 'products', 32951, COUNT(*)
    FROM raw.products 

    UNION ALL 
    SELECT 'product_category_name_translation', 71, COUNT(*)
    FROM raw.product_category_name_translation
)

SELECT 
    table_name,
    expected,
    actual,
    CASE 
        WHEN actual = expected THEN 'PASS'
        ELSE 'FAIL'
    END AS status
FROM row_counts
ORDER BY table_name;

-- Fail the execution if any raw table has an unexpected row count.

DO $$ 
BEGIN
    IF EXISTS (
        SELECT 1 FROM (
            SELECT COUNT(*) <> 99441 AS mismatch FROM raw.orders
            UNION ALL 
            SELECT COUNT(*) <> 99441 FROM raw.customers
            UNION ALL 
            SELECT COUNT(*) <> 112650 FROM raw.order_items
            UNION ALL 
            SELECT COUNT(*) <> 103886 FROM raw.order_payments 
            UNION ALL 
            SELECT COUNT(*) <> 99224 FROM raw.order_reviews
            UNION ALL 
            SELECT COUNT(*) <> 1000163 FROM raw.geolocation
            UNION ALL 
            SELECT COUNT(*) <> 3095 FROM raw.sellers
            UNION ALL 
            SELECT COUNT(*) <> 32951 FROM raw.products 
            UNION ALL 
            SELECT COUNT(*) <> 71 FROM raw.product_category_name_translation
        ) AS checks
        WHERE mismatch
    ) THEN
        RAISE EXCEPTION 'Raw data validation failed: row counts differ from expected values.';
    END IF;
END
$$;