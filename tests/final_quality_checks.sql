/*
=======================================================================================
Validation Script: Final NULL Check After Imputation
=======================================================================================
Purpose:
- To verify that all NULL values in key columns (`item`, `quantity`, `price_per_unit`) 
  have been successfully handled during the data cleaning process.
- This check runs after clean_step5, which includes:
  - Business rule-based filling (in clean_step4)
  - Average-based imputation (in clean_step5)
  - Standardization of string anomalies like 'unknown'

Query Logic:
- Select any rows from clean_step5 where item, quantity, or price_per_unit is still NULL.
- Expectation: No rows should be returned.
=======================================================================================
*/

SELECT *
FROM clean_step5
WHERE item IS NULL 
   OR quantity IS NULL 
   OR price_per_unit IS NULL;

/*
=======================================================================================
Conclusion:
- No NULL values were found in the `item`, `quantity`, or `price_per_unit` columns.
- This confirms that the imputation and standardization processes worked as intended,
  and the dataset is now clean and consistent in these key fields.
=======================================================================================
*/
