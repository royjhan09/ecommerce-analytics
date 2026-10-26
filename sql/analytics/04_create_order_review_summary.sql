-- ==================================================
-- Olist E-Commerce Analytics
-- Analytics: Order-Level review summary
-- 
-- Grain: one row per reviewed order_id 
-- 
-- Selection rule:
-- Most recent review_creation_date,
-- followed by review_answer_timestamp and review_id.
-- ==================================================

DROP TABLE IF EXISTS analytics.order_review_summary;

CREATE TABLE analytics.order_review_summary AS 
WITH ranked_reviews AS (
    SELECT 
        order_id,
        review_id,
        review_score,
        review_creation_date,
        review_answer_timestamp,

        COUNT(*) OVER (
            PARTITION BY order_id
        ) AS review_count,

        MIN(review_score) OVER (
            PARTITION BY order_id
        ) AS min_review_score,

        MAX(review_score) OVER (
            PARTITION BY order_id
        ) AS max_review_score,

        ROW_NUMBER() OVER (
            PARTITION BY order_id
            ORDER BY 
                review_creation_date DESC NULLS LAST,
                review_answer_timestamp DESC NULLS LAST,
                review_id DESC
        ) AS review_rank

    FROM staging.order_reviews
)
SELECT 
    order_id,
    review_id AS selected_review_id,
    review_score,
    review_creation_date,
    review_count,
    (min_review_score <> max_review_score)
        AS has_conflicting_scores

FROM ranked_reviews
WHERE review_rank = 1;

ALTER TABLE analytics.order_review_summary
    ADD CONSTRAINT pk_order_review_summary
    PRIMARY KEY (order_id);