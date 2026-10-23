# Data Quality Report

## 1. Orders

**Source:** 'olist_orders_dataset.csv'

**Population:** 99,441 orders

### 1.1 Missing Timestamp Investigation

| Column | Missing Values |
|---|---:|
| 'order_approved_at' | 160 |
| 'order_delivered_carrier_date' | 1,783 |
| 'order_delivered_customer_date' | 2,965 |

**Findings:**
- 8 orders are marked 'delivered' but have no customer delivery timestamp.
- 7 of these 8 orders have a carrier handoff timestamp.
- 1 is also missing the carrier handoff timestamp.
- 6 orders are marked 'canceled' despite having a customer delivery timestamp.

**Interpretation:**

Missing timestamps may be expected for orders that have not completed the delivery lifecycle.

However, the recorded order status and delivery timestamps are not always consistent.

The underlying causes cannot be determined from the available fields. 

**Proposed handling:**
- Preserved original records.
- Flag inconsistent status and timestamp combinations
- For primary delivery-performance metrics, use orders marked 'delivered' with a valid customer delivery timestamp.
- Keep canceled orders available for separate investigation.
- Document metric-specific exclusions.

**Status:** Initial investigation completed; causes unverified.

### 1.2 Timestamp Chronology Validation

**Objective:** Determine whether recorded timestamps follow the expected order lifecycle.

Expected sequence:

Purchase → Approval → Carrier Handoff → Customer Delivery

#### Validation Results

| Validation Rule | Violations |
|---|---:|
| Approval before purchase | 0 |
| Carrier handoff before purchase | 166 |
| Custmoer delivery before purchase | 0 |
| Carrier handoff before approval | 1,359 |
| Customer delivery before carrier handoff | 23 |

**Consolidated results:**
- Distinct affected orders: **1,382**
- Anomaly rate: **1.39%** of all orders
- Individual rule violations may overlap.

#### Method

Five Boolean validation conditions were evaluated using pandas.

The conditions were combined using the OR ('|') operator to identify order violating at least one rule.

Because 'order_id' was verified as unique, counting matching rows gives the number of distinct affected orders.

Missing timestamps were handled separately and were not classified as chronology violations by these comparisons.

### 1.3 Carrier-Before-Purchase Investigation

**Finding:** 166 orders contain carrier handoff timestamps earlier than their purchase timestamps.

**Discrepancy observations:**
- Median discrepancy: approximately 36 minutes early
- Maximum discrepancy: approximately 171 days and 5 hours early

**Most extreme record:**
- Order ID: '7c48bb55e8e4f7e56d412e9653db37bc'
- Purchase: 2018-07-16 18:40:53
- Carrier handoff: 2018-01-26 13:35:00
- Customer delivery: 2018-08-07 00:00:00

**Interpretation:**

These timestamps are inconsistent with the expected order lifecycle.

Possible explanation include recording errors or synchronization issues, but the actual causes remain unknown. 

### 1.4 Handling Recommendations

- Preserve original source values.
- Flag records with chronology violations.
- Avoid automatically deleting affected orders.
- Exclude invalid timestamps from calculations that require those specific timestamps.
- Do not automatically exclude an entire order from delivery-performance analysis because of an unrelated timestamp issue.
- Finalize inclusion and exclusion rules when constructing analytical models.

**Status:** Initial validation completed; root causes unresolved.

## 2. Customers

**Source:** 'olist_customers_dataset.csv'

**Population:** 99,441 customer records

### 2.1 Customer Identifier Validation

| Validation | Result |
|---|---:|
| Unique 'customer_id values | 99,441 |
| Duplicate 'customer_id' occurrences | 0 |
| Unique 'customer_unique_id' values | 96,096 |
| Duplicate 'customer_unique_id' occurrences | 3,345 |
| Missing values | 0 |

**Interpretation:**

'customer_id' uniquely identifies each customer record associated with an order.

'customer_unique_id' can appear across multiple customer records, allwoing purchases associated with the same identifiable customer to be grouped. 

### w2.2 Customer Location Consistency

**Finding:**

250 distinct 'customer_unique_id' values are associated with more than one ZIP code prefix.

**Methodology:**

Customer records were grouped by 'customer_unique_id'. The number of distinct ZIP code prefixes was calculated using 'nunique()'.

Customers associated with more than one distinct ZIP code prefix were identified.

**Interpretation:**

Some identifiable customers have multiple recorded geographic locations.

The available data does not establish whether these differences result from address changes, alternative delivery locations, or other circumstances.

**Handling:**

- Preserve the original geographic information.
- Do not assume each 'customer_unique_id' has a single permanent location.
- Define geographic analysis at the appropriate grain, such as the order-associated customer record.

**Status:** Initial validation completed.

## 3. Order Items

**Source:** 'olist_order_items_dataset.csv'

### 3.1 Orders Without Items

**Finding:** 775 orders have no matching item records.

| Order Status | Orders |
|---|---:|
| unavailable | 603 |
| canceled | 164 |
| created | 5 |
| invoiced | 2 |
| shipped | 1 |
| **Total** | **775** |

**Interpretation:**

Most unmatched orders are classified as 'unavailable' or 'canceled'.

No orders marked 'delivered' were found without item records.

The underlying reasons for the remaining unmatched orders have not been verified.

**Proposed handling:**
- Preserve unmatched orders in order-level analyses.
- Use LEFT JOIN when unmatched orders must be retained.
- Define appropriate inclusion criteria for item-level metrics.

### 3.2 Join Fanout Validation

**Finding:**

Joining 'orders' to 'order_items' using a LEFT JOIN increases the row count from 99,441 to 113,425.

**Validation results:**
- Original orders: 99,441
- Joined rows: 113,425
- Distinct orders after join: 99,441
- Additional rows: 13,984

**Interpretation:**

The increase is consistent with the one-to-many relationship between orders and order items.

This is expected join behavior, not inherently a data quality error.

**Modeling consideration:**

Order-level measures must not be summed directly over item-level joined rows without accunting for repeated values.

**Status:** Initial relationship and join validation completed.

## 4. Order Payments

**Source:** 'olist_order_payments_dataset.csv'

**Population:** 103,886 payment records

### 4.1 Referential Integrity and Missing Payments

**Findings:**
- 99,440 distinct orders have payment records.
- One delivered order has no corresponding payment record.
- No payment records reference nonexistent orders.

**Interpretation:**

The missing payment record represents a completeness issue in the relationship between orders and payments.

It does not establish that the customer failed to pay.

**Proposed handling:**
- Preserve the original order record.
- Flag the order as missing payment information.
- Do not interpret missing payments as zero-value payments.
- Document exclusion rules for payment-based analyses.

### 4.2 Multiple Payment Entries

**Findings:**
- Average payment entries per order with payments: 1.045
- Median: 1
- Maximum: 29

The order with 29 payment entries contains:
- 29 voucher payment entries
- Total recorded payment value: R$457.99
- 2 zero-value payment entries
- 0 negative-value payment entries

**Interpretation:**

Multiple payment entries are permitted by the source data model and are not automatically duplicated records.

The reasons for the high voucher count and zero-value entries remain unverified.

### 4.3 Join Fanout Investigation

**Objective:** Determine whether directly joining order items and payment records changes calculated payment totals.

#### Direct Join Results

| Metric | Result |
|---|---:|
| Original payment records | 103,886 |
| Joined records | 117,601 |
| Original payment total (all orders) | R$16,008,872.12 |
| Joined payment total | R$20,308,134.71 |

The INNER JOIN excludes payments associated with orders without items, so the original and joined totals do not cover identical populations.

#### Like-for-Like Comparison

Restricted to orders with item records:

| Metric | Result |
|---|---:|
| Correct payment total | R$15,846,280.17 |
| Payment total after direct join | R$20,308,134.71 |
| Inflated amount | R$4,461,854.54 |
| Inflated percentage | 28.16% |

**Root cause:**

Both 'order_items' and 'order_payments' can contain multiple records per order.

Joining them directly on 'order_id' creates multiple combinations of item and payment records, repeating payment values. 

#### Corrected Approach

1. Aggregate payment records to one row per order.
2. Aggregate item records to one row per order.
3. Join the resulting order-level tables using 'order_id'.
4. Validate row counts, uniqueness, and financial totals.

**Validation Results:**
- Orders with items: 98,666
- Rows after corrected join: 98,666
- Duplicate order IDs: 0
- Orders with items but missing payments: 1
- Item total before and after join: R$13,591,643.70
- Payment total before and after join for matching orders: R$15,846,280.17
- Payment reconciliation difference: R$0.00 (rounded)

**Conclusion:**

Aggregating each dataset to the intended analytical grain before joining prevents unintended duplication of order-level financial measures.

**Status:** Initial join fanout investigation completed and corrected approach validated.


## 5. Order Reviews

**Source:** `olist_order_reviews_dataset.csv`

**Population:** 99,224 review records

### 5.1 Missing Values and Score Validity

| Column | Missing Values |
|---|---:|
| `review_comment_title` | 87,656 |
| `review_comment_message` | 58,247 |
| `review_score` | 0 |
| `review_creation_date` | 0 |
| `review_answer_timestamp` | 0 |

**Review score distribution:**

| Review Score | Records |
|---|---:|
| 1 | 11,424 |
| 2 | 3,151 |
| 3 | 8,179 |
| 4 | 19,142 |
| 5 | 57,328 |

**Validation:** All recorded review scores fall within the expected 1–5 range.

**Interpretation:** Missing review comments may reflect optional text fields rather than invalid records.

### 5.2 Repeated Review Identifiers

**Findings:**
- 789 review IDs appear more than once.
- These review IDs correspond to 1,603 records.
- Maximum records per review ID: 3.
- All 789 repeated review IDs have consistent scores, comments, and timestamps.

**Interpretation:**

The same review identifier may be associated with multiple orders.

Repeated identifiers do not necessarily indicate duplicate records.

**Proposed handling:**
- Preserve the original review-order associations.
- Distinguish unique reviews from review-order relationships.
- Avoid assuming every row represents an independent customer opinion.

### 5.3 Orders with Multiple Reviews

**Findings:**
- 547 orders have multiple review records.
- These orders account for 1,098 review records.
- Maximum review records per order: 3.
- 345 orders have identical review scores across their records.
- 202 orders have different review scores.

**Timestamp investigation of the 202 conflicting-score orders:**
- 172 have different review creation dates.
- 30 have the same review creation date.
- Median span between creation dates: 5 days.
- Maximum span: 88 days.

**Interpretation:**

Multiple review records may reflect different customer feedback events or other source-system behavior.

The available data does not establish whether customers revised earlier ratings.

**Proposed handling:**
- Retain original review records.
- Do not automatically select the latest score or calculate an average.
- Define and document an order-level review aggregation rule during analytical modeling.
- Evaluate how the chosen rule affects satisfaction metrics.

### 5.4 Review Coverage

**Findings:**
- Total orders: 99,441
- Orders with reviews: 98,673
- Orders without reviews: 768

| Order Status | Total Orders | Without Reviews | Coverage |
|---|---:|---:|---:|
| approved | 2 | 0 | 100.00% |
| canceled | 625 | 20 | 96.80% |
| created | 5 | 2 | 60.00% |
| delivered | 96,478 | 646 | 99.33% |
| invoiced | 314 | 5 | 98.41% |
| processing | 301 | 6 | 98.01% |
| shipped | 1,107 | 75 | 93.22% |
| unavailable | 609 | 14 | 97.70% |

**Interpretation:**

Review coverage varies across order statuses.

Most orders without reviews are marked `delivered`, although review coverage among delivered orders remains high.

**Analytical considerations:**
- Orders without reviews cannot contribute observed satisfaction scores.
- Review availability may introduce selection bias.
- Satisfaction analyses should report the population and inclusion criteria.

**Status:** Initial profiling and validation completed. Order-level review modeling decisions remain pending.

## 6. Geolocation

**Source:** 'olist_geolocation_dataset.csv'

**Population:** 1,000,163 geographic records

### 6.1 Duplicate Records and ZIP Prefix Multiplicity

**Findings:**

| Check | Result |
|---|---:|
| Total records | 1,000,163 |
| Unique ZIP prefixes | 19,015 |
| Duplicate ZIP prefix occurences | 981,148 |
| Exact duplicate row occurrences | 261,831 |
| ZIP prefixes with multiple records | 17,972 |
| Maximum records per ZIP prefix | 1,146 |

**Interpretation:**

ZIP code prefixes are not unique in the source dataset.

Removing exact duplicate rows would not necessarily make ZIP prefixes unique.

**Proposed handling:**
- Preserve the original source dataset.
- Treat exact duplicate removal as a potential transformation step, not an automatic source correction.
- Construct a separate geographic lookup with one row per ZIP prefix.
- Validate lookup uniqueness before joining to customer or seller data.

### 6.2 Geographic Attribute Inconsistencies

**Findings:**
- 8,556 ZIP prefixes have multiple recorded city names.
- 8 ZIP prefixes have multiple recorded states.
- 8 records differ from their ZIP prefix's most frequently recorded state.

**Minority state assignments:**

| ZIP Prefix | Recorded State | Majority State |
|---|---|---|
| 2116 | RN | SP |
| 4011 | AC | SP |
| 21550 | AC | RJ |
| 23056 | AC | RJ |
| 72915 | DF | GO |
| 78557 | RO | MT |
| 79750 | RS | MS |
| 80630 | SC | PR |

**Interpretation:**

Some minority state assignments appear inconsistent with recorded cities and coordinates.

However, frequency alone is insufficient to establish the correct state.

**Proposed handling:**
- Preserve original assignments.
- Flag conflicting ZIP-prefix/state combinations.
- Use explicity, deterministic rules if selecting representative geographic attributes.
- Retain uncertainty where the correct assignment cannot be verified.

### 6.3 Coordinate Validity

**Findings:**

All recorded coordinates fall within the mathematically valid ranges:
- Latitude: -90 to +90
- Longitude: -180 to +180

**Observed coordinate extremes:**

| Coordinate | Minimum | Maximum |
|---|---:|---:|
| Latitude | -36.6054 | 45.0659 |
| Longitude | -101.4668 | 121.1054 |

**Conclusion:** No records fail basic numerical coordinate validation.

### 6.4 Geographic Plausibility 

**Screening method:**

Approximate Brazil bounding rectangle:
- Latitude: -34 to +6
- Longitude: -74 to -34

**Findings:**
- 42 records fall outside these approximate bounds.
- These records represent approximately 0.004% of the dataset.
- 21 ZIP prefixes are affected.
- Some affected prefixes also contain coordinates within the screening bounds.
- ZIP prefix '18243' has one record, which falls outside the screening bounds.

**Interpretation:**

Out-of-bounds records require investigation before use in representative coordinate calculations.

The bounding rectangle is an approximate screening rule, not an authoritative geographic validation.

**Proposed handling:**
- Preserve all source records.
- Flag suspicious coordinates.
- Avoid using flagged coordinates without additional validation.
- Do not automatically discard an entire ZIP prefix because one record is suspcious.
- Preserve missing or uncertain geographic reprsentations rather than inventing coordinates.

### 6.5 Geographic Join Fanout Risk

**Finding:**

The source contains multiple geographic records for many ZIP prefixes.

**Risk:**

Joining this table directly to customers or sellers may multiply records and distort downstream order counts or metrics.

**Proposed handling:**
1. Create a separate lookup at one row per ZIP prefix.
2. Validate key uniqueness.
3. Validate coverage of customer and seller ZIP prefixes.
4. Use cardinality validation when joining geographic attributes.
5. Reconcile row counts before and after geographic enrichment.

**Status:** Initial profiling completed. Geographic lookup transformation and coverage validation remain pending. 

## 7. Sellers

**Source:** 'olist_sellers_dataset.csv'

**Population:** 3,095 seller records

### 7.1 Identifier Validation

**Findings:**
- 3,095 unique seller identifiers
- 0 duplicate seller identifers
- 0 missing seller identifiers
- 0 exact duplicate rows

**Conclusion:** 'seller_id' is a valid candidate primary key.

### 7.2 Order Items Referential Integrity

**Findings:**
- All 3,095 sellers have associated order items.
- No order item references a seller absent from the Sellers dataset.

### 7.3 Geographic Coverage

**Findings:**
- 2,246 unique seller ZIP prefixes
- 2,239 prefies represented in Geolocation
- 7 unmatched ZIP prefixes
- 7 seller records affected

**Interpretation:**

Some seller locations cannot be enriched using the available Geolocation records.

This does not establish that the sellers' recorded ZIP prefixes are incorrect.

**Proposed handling:**
- Preserve all seller records.
- Flag sellers without matching geographic references.
- Use LEFT JOIN when geographic enrichment must retain all sellers.
- Avoid assigning replacement coordinates without supporting evidence.
- Validate coverage again after creating the geographic lookup.

**Status:** Initial profiling and relationship validation completed.

## 8. Products

**Source:** 'olist_product_dataset.csv'

**Population:** 32,951 product records

### 8.1 Identifier Validation

**Findings:**
- 32,951 unique product identifiers
- 0 duplicate product identifiers
- 0 missing product identifiers
- 0 exact duplicate rows

**Findings:**
- 32,951 unique product identifiers
- 0 duplicate product identifiers
- 0 missing product identifiers
- 0 exact duplicate rows

**Conclusion:** 'product_id' is a valid candidate primary key.

### 8.2 Missing Description Attributes

**Findings:**

| Attribute | Missing Values | Missing Percentage |
|---|---:|---:|
| 'product_category_name' | 610 | 1.85% |
| 'produt_name_lenght' | 610 | 1.85% |
| 'product_description_lenght' | 610 | 1.85% |
| 'product_photos_qty' | 610 | 1.85% |

All 610 affected products are missing these four attributes simultaneously.

No partially missing patterns were identified among these attributes.

**Interpretation:**

The shared missing-value pattern suggests a systematic issue or limitation in the source data.

The underlying cause has not been verified.

**Proposed handling:**
- Preserve the affected product records.
- Flag missing descriptive attributes.
- Avoid inventing missing categories or descriptions.
- Exclude products with missing categories only from analyses that explicitly require known categories, while retaining them in overall metrics.

### 8.3 Physical Attribute Validation

**Findings:**

| Attribute | Missing | Zero | Negative | Minimum | Maximum |
|---|---:|---:|---:|---:|---:|
| 'product_weight_g' | 2 | 4 | 0 | 0 | 40,425 |
| 'product_length_cm' | 2 | 0 | 0 | 7 | 105 |
| 'product_height_cm' | 2 | 0 | 0 | 2 | 105 |
| 'product_width_cm' | 2 | 0 | 0 | 6 | 118 |

Two products are missing all four physical measurements.

Four additional products have zero recorded weight.

**Impact on Order Items:**

| Issue | Products | Associated Item Records |
|---|---:|---:|
| Missing weight | 2 | 18 |
| Zero weight | 4 | 8 |
| Total | 6 | 26 |

**Interpretation:**

Missing and zero-weight values may make affected products unsuitable for analyses that depend on positive weight measurements.

No negative physical measurements were identified.

**Proposed handling:**
- Preserve original values.
- Flag products with missing or nonpositive weight.
- Exclude invalid weight observations from calculations requiring positive weights.
- Avoid replacing missing measurements with unsupported estimates.

### 8.4 Order Items Referential Integrity

**Findings:**
- All 32,951 products appear in Order Items.
- No order item references a product missing from Products.

**Conclusion:** Referential integrity between Products and Order Items is satisfied in the supplied dataset.

### 8.5 Column Naming

**Finding:**

Two source column names contain the spelling 'length'.

**Planned transformations:**
- 'product_name_lenght' → 'product_name_length'
- 'product_description_lenght' → 'product_description_length'

**Handling:** Correct names in the transformation layer without modifying raw source files.

**Status:** Initial profiling and relationship validation completed.

## 9. Product Category Translation

**Source:** 'product_category_name_translation.csv'

**Population:** 71 translation records

### 9.1 Identifier and Completeness Validation

**Findings:**
- 71 unique Portuguese category names
- 71 unique English category names
- 0 missing values
- 0 duplicate Portuguese categories
- 0 duplicate English categories
- 0 exact duplicate rows

**Conclusion:** No identifier duplication or missing-value issues were identified in the translation source.

### 9.2 Translation Coverage

**Findings:**

Of 73 distinct Portuguese categories used in Products, 71 have translations and 2 do not.

| Untranslated Category | Affected Products |
|---|---:|
| 'portateis_cozinha_e_preparadores_de_alimentos' | 10 |
| 'pc_gamer' | 3 |
| **Total** | **13** |

Additionally, 610 products have missing source category names.

**Interpretation:**

Products without English translations fall into two distinct groups:

1. Products with missing Portuguese categories.
2. Products with valid Portuguese categories absent from the translation lookup

These cases should remain distinguishable.

**Proposed handling:**
- Preserve all product records.
- Retain untranslated Portuguese categories.
- Leave English translations missing until a verified mapping is introduced.
- Flag products with missing or untranslated categories separately.
- Document any future manual translation mappings.

### 9.3 Join Cardinality Validation

**Method:** Left join Products to Category Translation on 'product_category_name', using 'validate="many_to_one"'.

**Results:**
- Source products: 32,951
- Joined products: 32,951
- Unique joined products: 32,951
- Duplicate product identifiers: 0
- Matched products: 32,328
- Unmatched products: 623

**Conclusion:**

The translation lookup does not introduce join fanout. All product records are preserved.

**Status:** Source profiling and translation coverage validation completed.