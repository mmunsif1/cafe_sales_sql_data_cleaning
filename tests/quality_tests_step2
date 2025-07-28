/*==============================================================
  STEP 7: Post-Cleaning Validation of Numeric and Date Columns
           (quantity, price_per_unit, total_spent, transaction_date)
==============================================================*/

-- Check for distinct values in `quantity` after cleaning
-- Expectation: All invalid entries should now be NULL
SELECT DISTINCT quantity 
FROM clean_step1;
-- Conclusion:
-- Anomalies such as '', 'ERROR', and 'UNKNOWN' have been successfully replaced with NULLs in the `quantity` column.

-- Repeat for `price_per_unit`
SELECT DISTINCT price_per_unit 
FROM clean_step1;
-- Conclusion:
-- All invalid string values have been converted to NULL in the `price_per_unit` column.

-- Repeat for `total_spent`
SELECT DISTINCT total_spent 
FROM clean_step1;
-- Conclusion:
-- Only valid numeric values or NULLs remain in the `total_spent` column, ensuring clean financial data.

-- Repeat for `transaction_date`
SELECT DISTINCT transaction_date 
FROM clean_step1;
-- Conclusion:
-- All invalid or non-date values have been removed or converted to NULL.
-- The column is now safe to cast to DATE type.

-- Summary:
-- All numeric and date fields have been successfully cleaned, with only valid entries or NULLs remaining.
-- This ensures safe data type conversions and sets the foundation for reliable calculations and time-based analysis.


/*==============================================================
  STEP 8: Item-Price Relationship Check
==============================================================*/

-- Check if each item has a fixed price throughout the dataset
-- Purpose: If consistent, we can fill missing `price_per_unit` values based on the item
SELECT DISTINCT item, price_per_unit
FROM clean_step1
WHERE item != 'unknown' AND price_per_unit IS NOT NULL;
-- Conclusion:
-- Each item is consistently associated with only one unique `price_per_unit`.
-- This allows us to confidently impute missing prices using item-based mappings.
