/*==============================================================
  STEP 9: Business Logic Validation: total_spent = quantity × price_per_unit
==============================================================*/

-- Preview data to visually confirm that total_spent = quantity × price_per_unit
SELECT quantity, price_per_unit, total_spent 
FROM clean_step3;
-- Conclusion:
-- Visual inspection confirms that the formula seems to hold true for most rows.

-- Strict check to verify that total_spent = quantity × price_per_unit for all rows with valid (non-null) data
-- Expectation: No result (i.e., all rows satisfy the condition)
SELECT quantity, price_per_unit, total_spent
FROM clean_step3
WHERE quantity IS NOT NULL
  AND price_per_unit IS NOT NULL
  AND total_spent IS NOT NULL
  AND quantity * price_per_unit != total_spent;
-- Conclusion:
-- No mismatches found. The business logic `quantity × price_per_unit = total_spent` holds true for the entire dataset (excluding NULLs).
-- This confirms the data is internally consistent and justifies using this formula to fill missing values where applicable.
