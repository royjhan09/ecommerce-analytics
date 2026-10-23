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