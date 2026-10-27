## Source Entity Relationship Diagram

The source ERD documents the nine original Olist datasets, their validated candidate keys, and their logical relationships.

![Olist Source Entity Relationship Diagram](diagrams/source_erd.png)

### Modeling Notes

- 'order_id' is the primary identifier for Orders.
- Order Items, Payments, and Reviews use composite candidate keys.
- 'customer_id' identifies an order-associated customer record, while 'customer_unique_id' identifies customers across orders.
- Geolocation does not have a validated natural primary key.
- ZIP code prefixes are nonunique in Geolocation and therefore are not modeled as conventional foreign-key relationships in the source ERD.
- Source column names are retained, including the original lenght' spelling in Products.
- Standardized names, converted data types, and analytical aggregations will be introduced in later modeling layers.


## Analytics Model Validation

Analytical models are validated after transformation using `sql/analytics/06_validate_models.sql`.

The test suite covers:

- Fact-table row-count reconciliation against staging
- Financial and record-count reconciliation
- Dimension row-count preservation
- Review-summary completeness and conflicting-score flags
- Delivery timeline and delay calculation consistency
- Review attribute consistency between analytical models

Primary-key uniqueness is enforced through PostgreSQL constraints.

The validation script produces a PASS/FAIL result for each check and raises an exception if any critical check fails.

Validation is performed against source-derived expectations rather than assuming that all original Olist records are error-free.



## Analytical Data Model

The analytical layer provides fact tables, dimensions, and derived order-level models for marketplace delivery and customer satisfaction analysis.

![Olist Analytical ERD](diagrams/analytics_erd.png)

### Fact Tables

| Model | Grain | Purpose |
|---|---|---|
| `analytics.fact_orders` | One row per order | Order-level financial and operational measures |
| `analytics.fact_order_items` | One row per order item | Product- and seller-level item sales measures |

### Dimensions

| Model | Grain |
|---|---|
| `analytics.dim_products` | One row per product |
| `analytics.dim_customers` | One row per customer_id |
| `analytics.dim_sellers` | One row per seller |

### Derived Analytical Models

- `analytics.order_review_summary`: One row per reviewed order, with a documented review-selection rule.
- `analytics.order_delivery_performance`: One row per order, with delivery timing and review measures.

### Modeling Decisions

- Item and payment data are aggregated to the order grain before joining to `fact_orders`.
- Item-level and order-level financial measures remain separate.
- Product category translations preserve unmatched source categories.
- Order reviews are reduced to one selected record per order for comparative analysis.
- Invalid or missing delivery timelines are retained but excluded from applicable delivery metrics.
- Customer and seller locations are location proxies, not verified physical shipping-route data.

### Relationship Constraints

The ERD documents logical relationships. Primary keys are enforced in the analytical tables; not all foreign-key relationships are currently enforced by database constraints.
