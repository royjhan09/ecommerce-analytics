### Product colum naming standardization

**Decision:** Correct the source colum names 'product_name_lenght' and 'product_description_lenght' to 'product_name_length' and 'product_description_length' in staging.

**Rationale:** Preserve the original dataset structure in 'raw' while providing consistent, correctly spelled column names to downstream analytical models.

**Impact:** Column names change in staging; underlying values remain unchanged.