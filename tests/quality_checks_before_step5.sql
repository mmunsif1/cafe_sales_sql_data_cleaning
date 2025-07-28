-- =============================================================================
-- Post-Imputation Check → After filling missing values using the formula
-- Step 2: Verify that imputed values in clean_step4 do not violate the business rule
-- Expectation: No result (i.e., imputation using the formula was accurate)
-- =============================================================================
SELECT quantity, price_per_unit, total_spent
FROM clean_step4
WHERE quantity * price_per_unit != total_spent;

-- Conclusion:
-- No mismatches found post-imputation. All rows, including those with filled values,
-- satisfy the formula `quantity × price_per_unit = total_spent`.
-- This confirms the imputation logic was applied correctly.
