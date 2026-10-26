### Product colum naming standardization

**Decision:** Correct the source colum names 'product_name_lenght' and 'product_description_lenght' to 'product_name_length' and 'product_description_length' in staging.

**Rationale:** Preserve the original dataset structure in 'raw' while providing consistent, correctly spelled column names to downstream analytical models.

**Impact:** Column names change in staging; underlying values remain unchanged.

### Order-level review selection

**Decision:** For order-level analysis, select the most recent review by 'review_creation_date', using 'review_answer_timestamp' and 'review_id' as deterministic tie-breakers.

**Rationale:** Some orders contain multiple reviews. Selecting one review per order prevents join fanout when analyzing delivery performance against review scores.

**Limitations:**
- The latest review is not necessarily the customer's definitive assessment.
- Ties are resolved deterministically rather than through a verified business rule.
- Orders with conflicting review scores are flagged using 'has_conflicting_scores'.
- Sensitivity analysis will compare results with and without conflicting-score orders.

**Source preservation:** All original review records remain in the raw and staging layers.