/*
===============================================================================
Script Name: Cafe Sales Data Cleaning Pipeline
===============================================================================
Purpose:
    This SQL script performs a multi-stage data cleaning process on the
    'dirty_cafe_sales' dataset to prepare it for reliable analysis.

Key Steps:
    1. Standardizes text and handles string/numeric anomalies
    2. Converts data into appropriate types
    3. Imputes missing values using:
       - Default pricing rules
       - Logical relationships (e.g., quantity * price = total)
       - Column averages (optional step)
    4. Infers missing item names based on price
    5. Provides two final options:
       - Drop incomplete rows (default)
       - Fill missing values using averages (commented out alternative)

Output:
    A cleaned and validated dataset with complete and consistent numeric fields. String and date columns
    still contain some NULL values that could not be reliably imputed and are retained as-is for transparency.
    The dataset is suitable for analysis with appropriate handling of missing categorical and date values.

Author:
    Muhammad Munsif

Last Update: 2025-07-29
===============================================================================
*/



-- ============================================
-- CTE 1: Initial Cleanup and Standardization
-- --------------------------------------------
-- This step:
-- - Converts values to lowercase for consistency
-- - Replaces string anomalies ('', 'Unknown', 'Error') with 'unknown'
-- - Replaces numeric anomalies ('', 'UNKNOWN', 'ERROR') with NULL
-- - Converts appropriate columns to proper data types
-- ============================================
WITH clean_step1 AS (
  SELECT
    LOWER(transaction_id) AS transaction_id,

    CASE 
      WHEN item IN ('', 'Unknown', 'Error') THEN 'unknown'
      ELSE LOWER(item)
    END AS item,

    CASE 
      WHEN quantity IN ('', 'UNKNOWN', 'ERROR') THEN NULL
      ELSE TRY_CAST(quantity AS FLOAT)
    END AS quantity,

    CASE 
      WHEN price_per_unit IN ('', 'UNKNOWN', 'ERROR') THEN NULL
      ELSE TRY_CAST(price_per_unit AS FLOAT)
    END AS price_per_unit,

    CASE 
      WHEN total_spent IN ('', 'UNKNOWN', 'ERROR') THEN NULL
      ELSE TRY_CAST(total_spent AS FLOAT)
    END AS total_spent,

    CASE 
      WHEN payment_method IN ('', 'Unknown', 'Error') THEN 'unknown'
      ELSE REPLACE(LOWER(payment_method), ' ', '_')
    END AS payment_method,

    CASE 
      WHEN LOWER(location) IN ('', 'unknown', 'error') THEN 'unknown'
      ELSE REPLACE(LOWER(location), '-', '')
    END AS location,

    CASE 
      WHEN transaction_date IN ('', 'UNKNOWN', 'ERROR') THEN NULL
      ELSE TRY_CAST(transaction_date AS DATE)
    END AS transaction_date

  FROM dirty_cafe_sales
),

-- ============================================
-- CTE 2: Impute Price per Unit for Known Items
-- --------------------------------------------
-- For rows where `price_per_unit` is NULL but `item` is known,
-- replace with a predefined standard price for that item.
-- Items marked as 'unknown' are skipped here.
-- ============================================
clean_step2 AS (
  SELECT
    transaction_id,
    item,
    quantity,

    CASE 
      WHEN price_per_unit IS NULL AND item != 'unknown' THEN
        CASE 
          WHEN item = 'cake' THEN 3.0
          WHEN item = 'coffee' THEN 2.0
          WHEN item = 'cookie' THEN 1.0
          WHEN item = 'juice' THEN 3.0
          WHEN item = 'salad' THEN 5.0
          WHEN item = 'sandwich' THEN 4.0
          WHEN item = 'smoothie' THEN 4.0
          WHEN item = 'tea' THEN 1.5
          ELSE price_per_unit
        END
      ELSE price_per_unit
    END AS price_per_unit,

    total_spent,
    payment_method,
    location,
    transaction_date

  FROM clean_step1
),

-- ============================================
-- CTE 3: Infer Unknown Item Using Price
-- --------------------------------------------
-- If `item` is 'unknown' but `price_per_unit` is present,
-- we infer the item name based on standard price values.
-- ============================================
clean_step3 AS (
  SELECT
    transaction_id,

    CASE 
      WHEN item = 'unknown' AND price_per_unit IS NOT NULL THEN
        CASE 
          WHEN price_per_unit = 1.0 THEN 'cookie'
          WHEN price_per_unit = 1.5 THEN 'tea'
          WHEN price_per_unit = 2.0 THEN 'coffee'
          WHEN price_per_unit = 5.0 THEN 'salad'
          ELSE item
        END
      ELSE item
    END AS item,

    quantity,
    price_per_unit,
    total_spent,
    payment_method,
    location,
    transaction_date

  FROM clean_step2
),

-- ============================================
-- CTE 4: Impute Using Logical Relationships
-- --------------------------------------------
-- Uses the formula: quantity * price_per_unit = total_spent
-- If one of the three values is missing and the other two are available,
-- it computes the missing one.
-- ============================================
clean_step4 AS (
  SELECT
    transaction_id,
    item,

    CASE 
      WHEN quantity IS NULL AND total_spent IS NOT NULL AND price_per_unit IS NOT NULL THEN 
        total_spent / price_per_unit
      ELSE quantity
    END AS quantity,

    CASE 
      WHEN price_per_unit IS NULL AND total_spent IS NOT NULL AND quantity IS NOT NULL THEN 
        total_spent / quantity
      ELSE price_per_unit
    END AS price_per_unit,

    CASE 
      WHEN total_spent IS NULL AND quantity IS NOT NULL AND price_per_unit IS NOT NULL THEN 
        quantity * price_per_unit
      ELSE total_spent
    END AS total_spent,

    payment_method,
    location,
    transaction_date

  FROM clean_step3
),

-- =====================================================================================
-- CTE 5: Final Imputation Using Column-Wise Averages
-- -------------------------------------------------------------------------------------
-- Purpose:
-- - This step retains all rows from the previous step (`clean_step4`)
-- - Missing numerical values are imputed using average values from available data (Rounded to 2 Decimals)
--
-- Columns affected:
-- - quantity           → filled with AVG(quantity)
-- - price_per_unit     → filled with AVG(price_per_unit)
-- - total_spent        → filled with AVG(total_spent)
--
-- Justification:
-- - Ensures data completeness for all records
-- - Avoids row loss due to NULLs
-- - Only 26 rows affected
--
-- Notes:
-- - Categorical fields (like item, location, etc.) remain unchanged
-- =====================================================================================
clean_step5 AS (
  SELECT
    transaction_id,
    item,

    COALESCE(
      quantity,
      ROUND((SELECT AVG(quantity) FROM clean_step4 WHERE quantity IS NOT NULL), 2)
    ) AS quantity,

    COALESCE(
      price_per_unit,
      ROUND((SELECT AVG(price_per_unit) FROM clean_step4 WHERE price_per_unit IS NOT NULL), 2)
    ) AS price_per_unit,

    COALESCE(
      total_spent,
      ROUND((SELECT AVG(total_spent) FROM clean_step4 WHERE total_spent IS NOT NULL), 2)
    ) AS total_spent,

    payment_method,
    location,
    transaction_date
  FROM clean_step4
)

-- Final cleaned dataset output
SELECT *
FROM clean_step5

/*
-- ============================================
-- Alternative CTE 5: Final Cleanup by Dropping Incomplete or Unknown Records
-- --------------------------------------------
-- This step removes all rows that:
-- - Contain NULLs in numeric or date fields
-- - Contain 'unknown' values in string columns
-- Use this approach if you want a strictly clean dataset
-- without any missing or ambiguous values.
-- ============================================
clean_step5 AS (
  SELECT
    transaction_id,
    item,
    quantity,
    price_per_unit,
    total_spent,
    payment_method,
    location,
    transaction_date
  FROM clean_step4
  WHERE 
    item != 'unknown' AND
    quantity IS NOT NULL AND
    price_per_unit IS NOT NULL AND
    total_spent IS NOT NULL AND
    payment_method != 'unknown' AND
    location != 'unknown' AND
    transaction_date IS NOT NULL
)
*/
