/*==================================================================================================================
  DATA QUALITY ASSESSMENT & CLEANING VALIDATION SCRIPT: dirty_cafe_sales
  ------------------------------------------------------------------------------------------------------------------
  Purpose:
    This script performs a thorough diagnostic and post-cleaning validation on the `dirty_cafe_sales` dataset. 
    It evaluates schema structure, checks for anomalies, and confirms the success of cleaning operations 
    applied through a series of transformations (clean_step1 to clean_step5).

  Key Objectives:
    ✔ Inspect table schema to identify data type inconsistencies  
    ✔ Verify uniqueness and completeness of `transaction_id` as a primary key  
    ✔ Detect and standardize anomalies in string fields (`item`, `payment_method`, `location`)  
    ✔ Identify and replace invalid entries in numeric fields (`quantity`, `price_per_unit`, `total_spent`)  
    ✔ Validate and clean the `transaction_date` column for proper date formatting  
    ✔ Confirm correct application of business logic (e.g., `total_spent = quantity × price_per_unit`)  
    ✔ Ensure all NULLs in essential fields are handled via imputation or standardization

  Structure:
    ▸ STEP 1: Schema Inspection — Understand column types and identify potential type mismatches  
    ▸ STEP 2: transaction_id Validation — Ensure no duplicates or NULLs exist in the primary key  
    ▸ STEP 3: String Column Checks — Detect anomalies and spacing issues in categorical fields  
    ▸ STEP 4: Numeric Column Checks — Identify string-based invalid values in numeric fields  
    ▸ STEP 5: Date Field Validation — Identify and isolate uncastable date values  
    ▸ STEP 7: Post-Cleaning Checks — Confirm successful replacement of anomalies with NULLs  
    ▸ STEP 8: Item-Price Mapping — Validate whether each item maps to a fixed price  
    ▸ STEP 9: Business Logic Check — Ensure `total_spent = quantity × price_per_unit` holds true  
    ▸ STEP 10: Business Logic Consistency (Post-clean_step4) — Validate imputed values  
    ▸ Final NULL Check — Ensure that clean_step5 has no remaining NULLs in key columns

  Outcomes:
    • All structural and semantic anomalies were identified and addressed.
    • Imputation logic and business rules were verified and hold across the dataset.
    • All NULLs in critical fields have been appropriately handled.
    • The dataset is now clean, consistent, and ready for transformation or analysis.

  Usage Notes:
    ▸ Intended for analysts, engineers, or BI professionals performing SQL-based data quality assurance.

  Author: Muhammad Munsif  
  Last Updated: 2025-07-29
==================================================================================================================*/


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

-- 3.1: Check for leading/trailing spaces in `item` column
SELECT item 
FROM dirty_cafe_sales 
WHERE item != TRIM(item);

-- Conclusion:
-- No leading or trailing spaces found in `item`.

-- Check unique values in `item` column
SELECT DISTINCT item 
FROM dirty_cafe_sales;

-- Conclusion:
-- Found 3 anomalies in `item`: '', 'ERROR', and 'UNKNOWN'.
-- These represent invalid or missing values and should be standardized (e.g., replaced with 'unknown').

-- 3.2: Check for leading/trailing spaces in `payment_method` column
SELECT payment_method 
FROM dirty_cafe_sales 
WHERE payment_method != TRIM(payment_method);

-- Conclusion:
-- No leading or trailing spaces found in `payment_method`.

-- Check unique values in `payment_method` column
SELECT DISTINCT payment_method 
FROM dirty_cafe_sales;

-- Conclusion:
-- Found 3 anomalies in `payment_method`: '', 'ERROR', and 'UNKNOWN'.
-- These represent invalid or unclassified payment types and should be standardized.

-- 3.3: Check for leading/trailing spaces in `location` column
SELECT location 
FROM dirty_cafe_sales 
WHERE location != TRIM(location);

-- Conclusion:
-- No leading or trailing spaces found in `location`.

-- Check unique values in `location` column
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

-- 4.1: Inspect distinct values in `quantity` column
SELECT DISTINCT quantity 
FROM dirty_cafe_sales;

-- Conclusion:
-- Found 3 anomalies: '', 'ERROR', and 'UNKNOWN'.
-- These must be replaced with NULLs to allow casting to INT or FLOAT.
-- If quantity represents whole units sold, INT is preferred.

-- 4.2: Inspect distinct values in `price_per_unit` column
SELECT DISTINCT price_per_unit 
FROM dirty_cafe_sales;

-- Conclusion:
-- Found anomalies: '', 'ERROR', and 'UNKNOWN'.
-- These should be converted to NULLs before casting to FLOAT.
-- Useful for per-item pricing calculations.

-- 4.3: Inspect distinct values in `total_spent` column
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
-- Identify values in `transaction_date` that cannot be cast to DATE
SELECT transaction_date
FROM dirty_cafe_sales
WHERE TRY_CAST(transaction_date AS DATE) IS NULL;

-- Conclusion:
-- Found 3 anomalies in the `transaction_date` column that cannot be cast to DATE.
-- These should be replaced with NULLs before converting the column to DATE type.
-- This step is essential for enabling time-based analysis (e.g., monthly sales trends).

/*==============================================================
  POST-CLEANING VALIDATION AFTER 1st CTE ⬇️
==============================================================*/

/*==============================================================
  STEP 7: Post-Cleaning Validation of Numeric and Date Columns
           (quantity, price_per_unit, total_spent, transaction_date)
==============================================================*/

-- Check for distinct values in `quantity` after cleaning
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
SELECT DISTINCT item, price_per_unit
FROM clean_step1
WHERE item != 'unknown' AND price_per_unit IS NOT NULL;

-- Conclusion:
-- Each item is consistently associated with only one unique `price_per_unit`.
-- This allows us to confidently impute missing prices using item-based mappings.

/*==============================================================
  POST-CLEANING VALIDATION AFTER 2nd and 3rd CTE ⬇️
==============================================================*/

/*==============================================================
  STEP 9: Business Logic Validation: total_spent = quantity × price_per_unit
==============================================================*/

-- Preview data to visually confirm that `total_spent = quantity × price_per_unit`
SELECT quantity, price_per_unit, total_spent 
FROM clean_step3;

-- Conclusion:
-- Visual inspection confirms that the formula seems to hold true for most rows.

-- Strict check to verify business logic
SELECT quantity, price_per_unit, total_spent
FROM clean_step3
WHERE quantity IS NOT NULL
  AND price_per_unit IS NOT NULL
  AND total_spent IS NOT NULL
  AND quantity * price_per_unit != total_spent;

-- Conclusion:
-- No mismatches found. The business logic `quantity × price_per_unit = total_spent` holds true for the entire dataset (excluding NULLs).
-- This confirms the data is internally consistent and justifies using this formula to fill missing values where applicable.

/*==============================================================
  POST-CLEANING VALIDATION AFTER 4th CTE ⬇️
==============================================================*/

/*==============================================================
  STEP 10: Validation Check — Business Logic Consistency After clean_step4
==============================================================*/

-- Ensure that values filled using business logic are accurate
-- Expectation: No mismatches should be found
SELECT quantity, price_per_unit, total_spent
FROM clean_step4
WHERE quantity IS NOT NULL
  AND price_per_unit IS NOT NULL
  AND total_spent IS NOT NULL
  AND quantity * price_per_unit != total_spent;

-- Conclusion:
-- No mismatches were found between `quantity × price_per_unit` and `total_spent`.
-- This confirms that all imputed or existing values in `clean_step4` adhere to the business logic.
-- The formula is reliable for future imputations or validations.

/*==============================================================
  POST-CLEANING VALIDATION AFTER 5th CTE ⬇️
==============================================================*/

/*==============================================================
  Final NULL Check After Imputation (clean_step5)
==============================================================*/

-- Purpose:
-- Verify that all NULL values in key columns have been successfully handled
-- Expectation: No rows should be returned
SELECT *
FROM clean_step5
WHERE item IS NULL 
   OR quantity IS NULL 
   OR price_per_unit IS NULL;

-- Conclusion:
-- No NULL values were found in the `item`, `quantity`, or `price_per_unit` columns.
-- This confirms that the imputation and standardization processes worked as intended,
-- and the dataset is now clean and consistent in these key fields.
