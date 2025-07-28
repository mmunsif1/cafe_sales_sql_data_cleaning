-- =========================================================================================
-- Validation Check: Business Logic Consistency After clean_step4
-- -----------------------------------------------------------------------------------------
-- Purpose:
-- - Ensure that the values filled using business logic are accurate
-- - Specifically, check whether the formula `quantity * price_per_unit = total_spent` holds
--   for all rows where all three fields are now populated
--
-- Expectation:
-- - No mismatches should be found if the logic in `clean_step4` was correctly applied
--
-- Notes:
-- - This step helps catch any edge cases (e.g., rounding, division by zero)
-- =========================================================================================
SELECT quantity, price_per_unit, total_spent
FROM clean_step4
WHERE quantity IS NOT NULL
  AND price_per_unit IS NOT NULL
  AND total_spent IS NOT NULL
  AND quantity * price_per_unit != total_spent;
