/*==============================================================
  STEP 1: Schema Inspection
==============================================================*/
-- Check the structure of the original table
SELECT 
    COLUMN_NAME,
    DATA_TYPE,
    CHARACTER_MAXIMUM_LENGTH,
    IS_NULLABLE,
    COLUMN_DEFAULT
FROM 
    INFORMATION_SCHEMA.COLUMNS
WHERE 
    TABLE_NAME = 'dirty_cafe_sales';

-- Observation:
-- All columns are of VARCHAR data type.
-- This suggests the presence of string-based anomalies in columns that should contain numeric or date values,
-- such as `quantity`, `price_per_unit`, `total_spent`, and `transaction_date`.


/*==============================================================
  STEP 2: Check for Duplicates and NULLs in transaction_id (Primary Key)
  Expectation: No result
==============================================================*/
SELECT
    transaction_id,
    COUNT(*) AS count
FROM 
    dirty_cafe_sales
GROUP BY 
    transaction_id
HAVING 
    COUNT(*) > 1 OR transaction_id IS NULL;

-- Conclusion:
-- There are no duplicates or NULLs in the `transaction_id` column.
-- This confirms it is a valid candidate for the primary key.


/*==============================================================
  STEP 3: String Fields Validation
           (item, payment_method, location)
==============================================================*/

-- 3.1: Check for leading/trailing spaces in item column
SELECT item 
FROM dirty_cafe_sales 
WHERE item != TRIM(item);
-- Conclusion:
-- No leading or trailing spaces found in `item`.

-- Check unique values in item column
SELECT DISTINCT item 
FROM dirty_cafe_sales;
-- Conclusion:
-- Found 3 anomalies in `item`: '', 'ERROR', and 'UNKNOWN'.
-- These represent invalid or missing values and should be standardized (e.g., replaced with 'unknown').


-- 3.2: Check for leading/trailing spaces in payment_method column
SELECT payment_method 
FROM dirty_cafe_sales 
WHERE payment_method != TRIM(payment_method);
-- Conclusion:
-- No leading or trailing spaces found in `payment_method`.

-- Check unique values in payment_method column
SELECT DISTINCT payment_method 
FROM dirty_cafe_sales;
-- Conclusion:
-- Found 3 anomalies in `payment_method`: '', 'ERROR', and 'UNKNOWN'.
-- These represent invalid or unclassified payment types and should be standardized.


-- 3.3: Check for leading/trailing spaces in location column
SELECT location 
FROM dirty_cafe_sales 
WHERE location != TRIM(location);
-- Conclusion:
-- No leading or trailing spaces found in `location`.

-- Check unique values in location column
SELECT DISTINCT location 
FROM dirty_cafe_sales;
-- Conclusion:
-- Found 3 anomalies in `location`: '', 'ERROR', and 'UNKNOWN'.
-- These are invalid entries and should be cleaned (e.g., replaced with NULL or 'unknown').

-- Summary of STEP 3:
-- All three string columns are low-cardinality and contain the same anomalies: '', 'ERROR', 'UNKNOWN'.
-- These values should be standardized or converted to NULLs to improve data quality and consistency.


/*==============================================================
  STEP 4: Numerical Fields Validation
           (quantity, price_per_unit, total_spent)
==============================================================*/

-- 4.1: Inspect distinct values in quantity column
SELECT DISTINCT quantity 
FROM dirty_cafe_sales;
-- Conclusion:
-- Found 3 anomalies: '', 'ERROR', and 'UNKNOWN'.
-- These must be replaced with NULLs to allow casting to INT or FLOAT.
-- If quantity represents whole units sold, INT is preferred.

-- 4.2: Inspect distinct values in price_per_unit column
SELECT DISTINCT price_per_unit 
FROM dirty_cafe_sales;
-- Conclusion:
-- Found anomalies: '', 'ERROR', and 'UNKNOWN'.
-- These should be converted to NULLs before casting to FLOAT.
-- Useful for per-item pricing calculations.

-- 4.3: Inspect distinct values in total_spent column
SELECT DISTINCT total_spent 
FROM dirty_cafe_sales;
-- Conclusion:
-- Found the same anomalies: '', 'ERROR', and 'UNKNOWN'.
-- Replace with NULLs for successful casting to FLOAT.
-- This field can later be validated using quantity × price_per_unit.

-- Summary of STEP 4:
-- All numerical fields contain string anomalies that make them incompatible with numeric types.
-- Cleaning is required before type conversion.
-- After cleaning, validate relationships between fields (e.g., `total_spent = quantity * price_per_unit`).


/*==============================================================
  STEP 5: Date Field Validation
==============================================================*/
-- Identify values in transaction_date that cannot be cast to DATE
SELECT transaction_date
FROM dirty_cafe_sales
WHERE TRY_CAST(transaction_date AS DATE) IS NULL;

-- Conclusion:
-- Found 3 anomalies in the `transaction_date` column that cannot be cast to DATE.
-- These should be replaced with NULLs before converting the column to DATE type.
-- This step is essential for enabling time-based analysis (e.g., monthly sales trends).
