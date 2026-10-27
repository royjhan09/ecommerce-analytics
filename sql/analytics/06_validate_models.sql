
-- ============================================================
-- Olist E-Commerce Analytics
-- Analytics layer validation
--
-- Checks:
--   1. Fact-table grains
--   2. Financial reconciliation
--   3. Dimension grains
--   4. Review summary integrity
--   5. Delivery performance integrity
--
-- Run after all analytical models have been built.
-- ============================================================

DROP TABLE IF EXISTS pg_temp.analytics_validation_results;

CREATE TEMP TABLE analytics_validation_results (
    test_name TEXT PRIMARY KEY,
    passed BOOLEAN NOT NULL
);

-- ============================================================
-- 1. Fact table row-count reconciliation
-- ============================================================

INSERT INTO analytics_validation_results
SELECT
    'fact_orders_row_count',
    (SELECT COUNT(*) FROM analytics.fact_orders)
    =
    (SELECT COUNT(*) FROM staging.orders)

UNION ALL
SELECT
    'fact_order_items_row_count',
    (SELECT COUNT(*) FROM analytics.fact_order_items)
    =
    (SELECT COUNT(*) FROM staging.order_items);


-- ============================================================
-- 2. Financial and record-count reconciliation
-- ============================================================

INSERT INTO analytics_validation_results
SELECT
    'fact_orders_item_count',
    (SELECT SUM(item_count) FROM analytics.fact_orders)
    =
    (SELECT COUNT(*) FROM staging.order_items)

UNION ALL
SELECT
    'fact_orders_payment_count',
    (SELECT SUM(payment_count) FROM analytics.fact_orders)
    =
    (SELECT COUNT(*) FROM staging.order_payments)

UNION ALL
SELECT
    'fact_orders_item_value',
    (SELECT SUM(item_value) FROM analytics.fact_orders)
    =
    (SELECT SUM(price) FROM staging.order_items)

UNION ALL
SELECT
    'fact_orders_freight_value',
    (SELECT SUM(freight_value) FROM analytics.fact_orders)
    =
    (SELECT SUM(freight_value) FROM staging.order_items)

UNION ALL
SELECT
    'fact_orders_payment_value',
    (SELECT SUM(payment_value) FROM analytics.fact_orders)
    =
    (SELECT SUM(payment_value) FROM staging.order_payments)

UNION ALL
SELECT
    'fact_order_items_price',
    (SELECT SUM(item_price) FROM analytics.fact_order_items)
    =
    (SELECT SUM(price) FROM staging.order_items)

UNION ALL
SELECT
    'fact_order_items_freight',
    (SELECT SUM(item_freight_value)
     FROM analytics.fact_order_items)
    =
    (SELECT SUM(freight_value) FROM staging.order_items);


-- ============================================================
-- 3. Dimension row-count reconciliation
-- ============================================================

INSERT INTO analytics_validation_results
SELECT
    'dim_products_row_count',
    (SELECT COUNT(*) FROM analytics.dim_products)
    =
    (SELECT COUNT(*) FROM staging.products)

UNION ALL
SELECT
    'dim_customers_row_count',
    (SELECT COUNT(*) FROM analytics.dim_customers)
    =
    (SELECT COUNT(*) FROM staging.customers)

UNION ALL
SELECT
    'dim_sellers_row_count',
    (SELECT COUNT(*) FROM analytics.dim_sellers)
    =
    (SELECT COUNT(*) FROM staging.sellers);


-- ============================================================
-- 4. Review summary integrity
-- ============================================================

INSERT INTO analytics_validation_results
SELECT
    'review_summary_order_count',
    (SELECT COUNT(*) FROM analytics.order_review_summary)
    =
    (SELECT COUNT(DISTINCT order_id)
     FROM staging.order_reviews)

UNION ALL
SELECT
    'review_summary_record_count',
    (SELECT SUM(review_count)
     FROM analytics.order_review_summary)
    =
    (SELECT COUNT(*) FROM staging.order_reviews)

UNION ALL
SELECT
    'review_conflict_flags',
    NOT EXISTS (
        SELECT 1
        FROM (
            SELECT
                order_id,
                MIN(review_score) <> MAX(review_score)
                    AS expected_conflict
            FROM staging.order_reviews
            GROUP BY order_id
        ) AS source_reviews
        JOIN analytics.order_review_summary AS r
            ON source_reviews.order_id = r.order_id
        WHERE r.has_conflicting_scores
              IS DISTINCT FROM source_reviews.expected_conflict
    );


-- ============================================================
-- 5. Delivery model integrity
-- ============================================================

INSERT INTO analytics_validation_results
SELECT
    'delivery_model_row_count',
    (SELECT COUNT(*)
     FROM analytics.order_delivery_performance)
    =
    (SELECT COUNT(*) FROM analytics.fact_orders)

UNION ALL
SELECT
    'delivery_valid_timeline_count',
    (SELECT COUNT(*)
     FROM analytics.order_delivery_performance
     WHERE has_valid_delivery_timeline)
    =
    (
        SELECT COUNT(*)
        FROM analytics.fact_orders
        WHERE order_status = 'delivered'
          AND order_purchase_timestamp IS NOT NULL
          AND order_delivered_customer_date IS NOT NULL
          AND order_estimated_delivery_date IS NOT NULL
          AND order_delivered_customer_date
              >= order_purchase_timestamp
    )

UNION ALL
SELECT
    'delivery_days_calculation',
    NOT EXISTS (
        SELECT 1
        FROM analytics.order_delivery_performance
        WHERE delivery_days IS DISTINCT FROM
            CASE
                WHEN has_valid_delivery_timeline
                THEN order_delivered_customer_date::DATE
                     - order_purchase_timestamp::DATE
            END
    )

UNION ALL
SELECT
    'delivery_delay_calculation',
    NOT EXISTS (
        SELECT 1
        FROM analytics.order_delivery_performance
        WHERE delivery_delay_days IS DISTINCT FROM
            CASE
                WHEN has_valid_delivery_timeline
                THEN order_delivered_customer_date::DATE
                     - order_estimated_delivery_date::DATE
            END
    )

UNION ALL
SELECT
    'delivery_review_reference',
    NOT EXISTS (
        SELECT 1
        FROM analytics.order_delivery_performance AS d
        LEFT JOIN analytics.order_review_summary AS r
            ON d.order_id = r.order_id
        WHERE d.review_score IS DISTINCT FROM r.review_score
           OR d.review_count IS DISTINCT FROM r.review_count
           OR d.has_conflicting_scores
              IS DISTINCT FROM r.has_conflicting_scores
    );


-- ============================================================
-- 6. Display results
-- ============================================================

SELECT
    test_name,
    CASE
        WHEN passed THEN 'PASS'
        ELSE 'FAIL'
    END AS status
FROM analytics_validation_results
ORDER BY test_name;


-- ============================================================
-- 7. Raise an error if any validation fails
-- ============================================================

DO $$
DECLARE
    failed_tests TEXT;
BEGIN
    SELECT STRING_AGG(test_name, ', ' ORDER BY test_name)
    INTO failed_tests
    FROM analytics_validation_results
    WHERE passed IS NOT TRUE;

    IF failed_tests IS NOT NULL THEN
        RAISE EXCEPTION
            'Analytics validation failed: %',
            failed_tests;
    END IF;

    RAISE NOTICE 'All analytics validations passed.';
END
$$;
