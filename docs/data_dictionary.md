# Data Dictionary

## 1. Orders

### Overview

**Source:** 'olist_orders_dataset.csv'

**Description:** Contains order-level information, including customer references, order status, and timestamps associated with the order lifecycle.

### Structure

- **Row count:** 99,441
- **Column count:** 8
- **Grain:** One row per order
- **Candidate primary key:** 'order_id'

### Column Definitions

| Column | Source Type | Description |
|---|---|---|
| 'order_id' | string | Unique order identifier |
| 'customer_id' | string | Customer reference associated with the order |
| 'order_status' | string | Recorded order status |
| 'order_purchase_timestamp' | string | Order purchase timestamp |
| 'order_approved_at' | string | Order approval timestamp |
| 'order_delivered_carrier_date' | string | Recorded carrier handoff timestamp |
| 'order_delivered_customer_date' | string | Recorded customer delivery timestamp |
| 'order_estimated_delivery_date' | string | Estimated customer delivery date |

**Type conversion:** The five timestamp columns were initially loaded as strings and subsequently converted to 'datetime64[us]' during pandas profiling. The original CSV files remain unchanged.

### Key Validation

| Check | Result |
|---|---:|
| Total rows | 99,441 |
| Unique 'order_id' values | 99,441 |
| Duplicate 'order_id' values | 0 |
| Missing 'order_id' values | 0 |


**Conclusion:** 'order_id' is unique and non-null across the source dataset.

### Data Quality Summary

**Missing timestamps:**
- order_approved_at: 160 missing values
- order_delivered_carrier_date: 1,783 missing values
- order_delivered_customer_date: 2,965 missing values

**Status inconsistencies:**
- 8 orders are marked 'delivered' but lack a customer delivery timestamp.
- 6 orders are marked 'canceled' but contain a customer deliver timestamp.

**Chronological inconsistencies:**
- 1,382 distinct orders violate at least on of tive tested chronology rules.
- THis represent approximately 1.39% of all orders

**Detailed investigation:** See [Data Quality — Orders](data_quality.md#1-orders).

### Relationships

- 'customer_id' is a potential reference to the customers dataset.
- Referential integrity has not yet been verified.

## 2. Customer

### Overview

**Source:** 'olist_customers_dataset.csv'

**Description:** Contains customer identifiers and geographic information assicated with marketplace orders.

### Structure

- **Row count:** 99,441
- **Column count:** 5
- **Grain:** One row per order-associated customer record
- **Candidate primary key:** 'customer_id'

### Column Definitions

| Column | Source Type | Description |
|---|---|---|
| 'customer_id' | string | Identifier associated with a customer record for an order |
| 'customer_unique_id' | string | Identifier used to recognize the same customer across different orders |
| 'customer_zip_code_prefix' | integer | Customer postal code prefix |
| 'customer_city' | string | Customer city |
| 'customer_state' | string | Customer state abbreviation |

### Key Validation

| Check | Result |
|---|---:|
| Total rows | 99,441 |
| Unique 'customer_id' values | 99,441 |
| Duplicate 'customer_id' values | 0 |
| Unique 'customer_unique_id' values | 96,096 |
| Duplicate 'customer_unique_id' occurrences | 3,345 |
| Missing identifier values | 0 |

**Conclusion:**

'customer_id' is unique and non-null, making it a valid candidate primary key.

'customer_unique_id' is not unique across rows and can be used to identify customers associated with multiple orders.

### Data Quality Summary

- No missing values were identified across the five source columns.
- No duplicate 'customer_id' values were identified.
- Geographic value validity and consistency have not yet been evaluated.
- 250 distinct 'customer_unique_id' values are associated with multiple ZIP code prefixes.
- Geographic information may vary across records sharing the same 'customer_unique_id'.
- See [Data Quality — Customers](data_quality.md#2-customers) for details

### Relationships 

**Related table:** 'orders'

**Join key:** 'customer_id'

**Relationship:** One-to-one in the supplied dataset.

**Referential Integrity Validation:**

| Check | Result |
|---|---:|
| Unique customer IDs referenced by orders | 99,441 |
| Unique customer IDs in customers | 99,441 |
| Order customer IDs missing from customers | 0 |

**Conclusion:** Every customer identifier referenced by the orders table exists in the customers table.

**Additional note:** 'customer_unique_id' can repeat across customer records, making it suitable for investigating repeat purchasing behavior.

## 3. Order Items

### Overview

**Source:** 'olist_order_items_dataset.csv'

**Description:** Contains item-level information associated with marketplace orders, including products, sellers, item prices, freight charges, and shipping deadline.

### Structure

- **Row count:** 112,650
- **Column count:** 7
- **Grain:** One row per item entry within an order
- **Candidate composite primary key:** ('order_id', 'order_item_id')

### Column Definitions

| Column | Source Type | Description |
|---|---|---|
| 'order_id' | string | Identifier of the associated order |
| 'order_item_id' | integer | Sequential item identifier within an order |
| 'product_id' | string | Identifier of the associated product |
| 'seller_id' | string | Identifier of the associated seller |
| 'shipping_limit_date' | string | Recorded shipping deadline |
| 'price' | float | Recorded item price |
| 'freight_value' | float | Recorded freight charge |

### Key Validation

| Check | Result |
|---|---:|
| Total rows | 112,650 |
| Unique orders | 98,666 |
| Unique composite keys | 112,650 |
| Duplicate composite keys | 0 |
| Rows with missing key components | 0 |

**Conclusion:** ('order_id', 'order_item_id') is unique and non-null across the source dataset.

### Data Quality Summary

- No missing values were identified across the seven source columns.
- No duplicate composite keys were identified.
- All item records reference an existing order.
- 775 orders have no corresponding item records.
- Monetary value validity and shipping deadlines have not yet been evaluated.

**Detailed investigation:** See [Data Quality — Order Items](data_quality.md#3-order-items).

### Relationships

**Related table:** 'orders'

**Join key:** 'order_id'

**Relationship:** One-to-many from orders to order items, with some orders having no matching items.

#### Referential Integrity

| Check | Result |
|---|---:|
| Orders with at least one item | 98,666 |
| Orders without items | 775 |
| Item order IDs abset from orders | 0 |

#### Item Distribution

| Metric | Result |
|---|---:|
| Orders before LEFT JOIN | 99,441 |
| Rows after LEFT JOIN | 113,425 |
| Distinct orders after LEFT JOIN | 99,441 |
| Unmatched orders | 775 |

**Modeling consideration:** Joining order-level data to item-level records changes the grain of the result and may duplicate order-level measures. Aggregations must account for this one-to-many relationship.

## 4. Order Payments

### Overview

**Source:** 'olist_order_payments_dataset.csv'

**Description:** Contains payment entries associated with marketplace orders, including payment methods, installments, and recorded amounts.

### Structure

- **Row count:** 103,886
- **Column count:** 5
- **Grain:** One row per payment entry within an order
- **Candidate composite primary key:** ('order_id', 'payment_sequential')

### Column Definitions

| Column | Source Type | Description |
|---|---|---|
| 'order_id' | string | Identifier of the associated order |
| 'payment_sequential' | integer | Payment sequence identifier within an order |
| 'payment_type' | string | Recorded payment method |
| 'payment_installments' | integer | Number of installments associated with the payment |
| 'payment_value' | float | Recorded payment amount in BRL |

### Key Validation

| Check | Result |
|---|---:|
| Total rows | 103,886 |
| Unique orders | 99,440 |
| Unique composite keys | 103,886 |
| Duplicate composite keys | 0 |
| Rows with missing key components | 0 |

**Conclusion:** ('order_id', 'payment_sequential') is unique and non-null across the source dataset.

### Data Quality Summary

- No missing values were identified across the five columns.
- No duplicate composite keys were identified.
- All payment records reference exisintg orders.
- One delivered order has no matching payment record.
- The order with the most payment records has 29 voucher entries, including two zero-value entries.
- Negative payment values have not yet been assessed across the entire dataset.

**Detailed investigations:** See [Data Quality — Order Payments](data_quality.md#4-order-payments).

### Relationships

**Related table:** 'orders'

**Join key:** 'order_id

**Relationship:** One-to-many from orders to payments, with one order having no payment record.

#### Referential Integrity

| Check | Result |
|---|---:|
| Orders with payments | 99,440 |
| Orders without payments | 1 |
| Payment order IDs absent from orders | 0 |

#### Payment Distribution

| Metric | Result |
|---|---:|
| Average payment entries per order with payments | 1.045 |
| Median | 1 |
| Maximum | 29 |

#### Modeling Considerations

- Payment records should be aggregated to order grain before joing with order-level analytical tables.
- Direct joins between payment-level and item-level data may produce many-to-many fanout.
- 'payment_value' represents recorded payment, not necessarily recognized revenue.
- Missing payment values must not automatically be interpreted as zero.

## 5. Order Reviews

### Overview

**Source:** 'olist_order_reviews_dataset.csv'

**Description:** Contains customer review scores, optional comments, and review-related timestamps associated with marketplace orders.

### Structure

- **Row count:** 99,224
- **Column count:** 7
- **Grain:** One row per order-review association
- **Candidate composite primary key:** ('review_id', 'order_id')

### Column Definitions

| Column | Source Type | Description |
|---|---|---|
| 'review_id' | string | Identifier associated with a review |
| 'order_id' | string | Identifier of the associated order |
| 'review_score' | integer | Customer rating from 1 to 5 |
| `review_comment_title` | string | Optional review title |
| `review_comment_message` | string | Optional written review |
| `review_creation_date` | string | Recorded review creation date |
| `review_answer_timestamp` | string | Recorded review answer timestamp |

**Type conversion:** Review timestamps were converted to datetime during the conflicting-review investigation. The original source DataFrame and CSV remain unchanged.

### Key Validation

| Check | Result |
|---|---:|
| Total review records | 99,224 |
| Unique `review_id` values | 98,410 |
| Duplicate `review_id` occurrences | 814 |
| Unique `order_id` values | 98,673 |
| Duplicate `order_id` occurrences | 551 |
| Unique composite keys | 99,224 |
| Duplicate composite keys | 0 |
| Missing key values | 0 |

**Conclusion:** (`review_id`, `order_id`) is unique and non-null across the source dataset.

### Data Quality Summary

**Missing values:**
- `review_comment_title`: 87,656
- `review_comment_message`: 58,247
- No missing review scores or timestamps were identified.

**Review score validity:**
- Valid range: 1–5
- Missing scores: 0
- Out-of-range scores: 0

**Repeated review identifiers:**
- 789 review IDs appear in multiple records.
- All 789 have consistent scores, comments, and timestamps across their associated records.

**Multiple reviews per order:**
- 547 orders have multiple review records.
- 202 of these orders have conflicting review scores.

**Detailed investigations:** See [Data Quality — Order Reviews](data_quality.md#5-order-reviews).

### Relationships

**Related table:** `orders`

**Join key:** `order_id`

**Relationship:** One-to-many from orders to review records, with some orders having no reviews.

#### Referential Integrity

| Check | Result |
|---|---:|
| Orders with reviews | 98,673 |
| Orders without reviews | 768 |
| Review order IDs absent from orders | 0 |

#### Modeling Considerations

- Multiple review records may be associated with one order.
- A review ID may be associated with multiple orders.
- Review records must not be assumed to represent independent customer opinions.
- Order-level review aggregation requires an explicitly defined business rule.
- Review coverage and potential selection bias must be considered when analyzing satisfaction.

## 6. Geolocation

## Overview

**Source:** 'olist_geolocation_dataset.csv'

**Description:** Contains geographic coordinates, city names, state abbreviations, and ZIP code prefixes associated with Brazilian locations.

### Structure

- **Row count:** 1,000,163
- **Column count:** 5
- **Grain:** One source geolocation record per row; multiple records may share a ZIP prefix
- **Primary key:** No validated natural primary key
- **Distinct ZIP prefixes:** 19,015

### Column Definitions

| Column | Source Type | Description |
|---|---|---|
| 'geolocation_zip_code_prefix' | integer | Five-digit postal code prefix |
| 'geolocation_lat' | float | Latitude in decimal degrees |
| 'geolocation_lng' | float | Longitude in decimal degrees |
| 'geolocation_city' | string | Recorded city name |
| 'geolocation_state' | string | Recorded state abbreviation |

**Modeling note:** ZIP prefixes may contain leading zeros when represented as five-character postal codes.
Standardized lookup keys should preserve those zeros.

### Key and Duplicate Validation

| Check | Result |
|---|---:|
| Total records | 1,000,163 |
| Unique ZIP prefixes | 19,015 |
| Duplicate ZIP prefix occurrences | 981,148 |
| Exact duplicate row occurences | 981,148 |
| Exact duplicate row occurrences | 261,831 |
| Missing values | 0 |

**Conclusion:** 'geolocation_zip_code_prefix' is not unique and cannot serve as a primary key for the raw dataset.

### Data Quality Summary

- 17,972 ZIP prefixes have multiple geographic records.
- 17,781 ZIP prefixes have multiple recorded latitude values.
- 8,556 ZIP prefixes have multiple city names.
- 8 ZIP prefixes have multiple state abbreviations.
- 8 individual records disagree with the most frequently recorded state for their ZIP prefix.
- All coordinates fall within mathematically valid latitude and longitude ranges.
- 42 records across 21 ZIP prefixes fall outside the approximate geographic bounds used to screen Brazilian coordinates.
- Geographic plausibility has not been validated against an authoritative Brazil boundary.

**Detailed investigations:** See [Data Quality — Geolocation](data_quality.md#6-geolocation)

### Relationships

**Potential related tables:** 'customers', 'sellers'

**Join keys:**
- 'customer_zip_code_prefix' → 'geolocation_zip_code_prefix'
- 'seller_zip_code_prefix' → 'geolocation_zip_code_prefix'

**Relationship:** Many geographic records may exist for a single ZIP prefix.

**Referential integrity:** Customer and seller ZIP-prefix coverage has not yet been validated.

### Modeling Considerations

- Raw geolocation records must not be joined directly to order-level analytical tables without controlling join cardinality.
- A one-row-per-ZIP-prefix lookup is required for the proposed geographic enrichment.
- Representative coordinates and location attributes require explicit selection rules.
- Suspicious records should be flagged rather than silently modified.
- ZIP prefixes without suitable coordinates must remain identifiable.

## 7. Sellers

### Overview

**Source:** 'olist_sellers_dataset.csv'

**Description:** Contains seller identifiers and geographic information associated with marketplace sellers.

### Structure

- **Row count:** 3,095
- **Column count:** 4
- **Grain:** One row per seller
- **Candidate primary key:** 'seller_id'

### Column Definitions

| Column | Source Type | Description |
|---|---|---|
| 'seller_id' | string | Unique identifier for a seller |
| 'seller_zip_code_prefix' | integer | Seller postal code prefix |
| 'seller_city' | string | Seller city |
| 'seller_state' | string | Seller state abbreviation |

### Key Validation

| Check | Result |
|---|---:|
| Total records | 3,095 |
| Unique seller IDs | 3,095 |
| Duplicate seller IDs | 0 |
| Missing seller IDs | 0 |
| Exact duplicate rows | 0 |

**Conclusion:** 'seller_id' is unique and non-null, making it a valid candidate primary key.

### Data Quality Summary

- No missing values were identified across the four columns.
- No duplicate seller identifiers or exact duplicate rows were identified.
- All sellers have at least one associated order item.
- Seven sellers have ZIP prefixes absent from the Geolocation dataset.
- Seller city and state consistency has not been independently verified.

**Detailed investigations:** See [Data Quality — Sellers](data_quality.md#7-sellers).

### Relationships

#### Order Items

**Related table:** 'order_items'

**Join key:** 'seller_id'

**Relationship:** One-to-many from sellers to order items.

| Validation | Result |
|---|---:|
| Sellers with associated order items | 3,095 |
| Sellers without associated order items | 0 |
| Item seller IDs missing from Sellers | 0 |

**Conclusion:** All seller identifiers referenced by Order Items exist in Sellers.

#### Geolocation

**Related table:** 'geolocation'

**Join keys:**
- 'seller_zip_code_prefix'
- 'geolocation_zip_code_prefix'

| Validation | Result |
|---|---:|
| Unique seller ZIP prefixes | 2,246 |
| Matched ZIP prefixes | 2,239 |
| Unmatched ZIP prefixes | 7 |
| Sellers without matching ZIP prefixes | 7 |

**Modeling considerations:**
- Geographic enrichment must use a lookup with one row per ZIP prefix.
- Sellers without geographic matches must be preserved.
- Missing geographic coordinates must not be replaced with fabricated values.
- ZIP prefixes should be standardized consistently across datasets.

## 8. Products

### Overview

**Source:** 'olist_products_dataset.csv'

**Description:** Contains product identifiers, category information, descriptive attributes, photo counts, and physical measurements.

### Structure

- **Row count:** 32,951
- **Column count:** 9
- **Grain:** One row per product
- **Candidate primary key:** 'product_id'

### Column Definitions

| Column | Source Type | Description |
|---|---|---|
| 'product_id' | string | Unique product identifier |
| 'product_category_name' | string | Product category in Portuguese | 
| 'product_name_lenght' | float | Length of product name |
| 'product_description_lenght' | float | Length of product description |
| 'product_photos_qty' | float | Number of product photos |
| 'product_weight_g' | float | Recorded product weight in grams |
| 'product_length_cm' | float | Product length in centimeters |
| 'product_height_cm' | float | Product height in centimeters |
| 'product_width_cm' | float | Product width in centimeters |

**Naming consideration:** The source uses 'lenght' instead of 'length'. These columns will be renmaed during transformation while preserving the original raw dataset.

### Key Validation
| Check | Result |
|---|---:|
| Total products | 32,951 |
| Unique product IDs | 32,951 |
| Duplicate product IDs | 0 |
| Missing product IDs | 0 |
| Exact duplicate rows | 0 |

**Conclusion:** 'product_id' is unique and non-null across the source dataset.

### Data Quality Summary

**Missing descriptive attributes:**
- 610 products are missing category, name length, description length, and photo quantity simultaneously.
- No products have only a subset of these four attributes missing.

**Physical attributes:**
- 2 products are missing all four physical measurements.
- 4 products have zero recorded weight.
- No negative weights or dimensions were identified.
- The six products with missing or zero weight are associated with 26 order-item records.

**Detailed investigations:** See [Data Quality — Products](data_quality.md#8-products).

### Relationships

#### Order Items

**Related table:** 'order_items'

**Join key:** 'product_id'

**Relationship:** One-to-many from products to order items.

| Validation | Result |
|---|---:|
| Products with order items | 32,951 |
| Products without order items | 0 |
| Item product IDs absent from Products | 0 |

**Conclusion:** All products referenced in Order Items exist in Products.

#### Product Category Translation

**Potential related table:** 'product_category_name_translation'

**Join key:** 'product_category_name'

**Relationship validation:** Pending.

### Modeling Considerations

- Preserve raw product records and identifiers.
- Standardize misspelled column names in the transformation layer.
- Flag missing descriptive and physical attributes.
- Treat zero weight as invalid for analyses requiring positive product weight, without assuming its underlying cause.
- Retain products with incomplete attrivutes when joining to Order Items.
- Validate category translation coverage before using English category names.

## 9. Product Category Translation

### Overview

**Source:** 'product_category_name_translation.csv'

**Description:** Provides English translations for Portuguese product category names.

### Structure

- **Row count:** 71
- **Column count:** 2
- **Grain:** One row per Portuguese product cateogry
- **Candidate primary key:** 'product_ctegory_name'

### Column Definitions

| Column | Source Type | Description |
|---|---|---|
| Total rows | 71 |
| Unique Portuguese categories | 71 |
| Unique English categories | 71 |
| Duplicate Portuguese categories | 71 |
| Duplicate English categories | 0 |
| Missing values | 0 |
| Exact duplicate rows | 0 |

**Conclusion:** Both category columns are unique and non-null. The Portuguese category is the candidate primary key because it is used as the join key Products.

### Relationships

**Related table:** 'products'

**Join key:** 'product_category_name'

**Relationship:** One-to-many from category translations to products with a matching category.

### Translation Coverage

| Check | Result |
|---|---:|
| Distinct product categories | 73 |
| Categories with translations | 71 |
| Categories without translations | 2 |
| Products with missing categories | 610 |
| Products with untranslated categories | 13 |
| Unused translation categories | 0 |

### Join Validation 

| Check | Result |
|---|---:|
| Products before join | 32,951 |
| Products after join | 32,951 |
| Unique product IDs after join | 32,951 |
| Duplicate product IDs after join | 0 |
| Products with matching translations | 32,328 |
| Products without matching translations | 623 |

**Conclusion:** A many-to-one left join preserves product grain without introducing duplicate records.

### Modeling Considerations

- Preserve Portuguese category identifiers as the original source values.
- Use English translations for reporting where available.
- Distinguish missing product categories from untranslated categories.
- Preserve products without translations.
- Avoid silently inventing translation mappings.
- Validate row counts and product uniqueness after joining.

**Detailed investigations:** See [Data Quality — Product Category Translation](data_quality.md#9-product-category-translation).