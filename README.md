# SQL Data Cleaning Project: Dirty Cafe Sales

This project showcases an end-to-end SQL-based data cleaning pipeline applied to a fictional cafe’s sales dataset, `dirty_cafe_sales`. The raw dataset contains various real-world data quality issues such as placeholder anomalies (`''`, `'UNKNOWN'`, `'ERROR'`), inconsistent formatting, missing values, and incorrect data types.

Using Common Table Expressions (CTEs), the project transforms the messy raw data into a clean, consistent, and analysis-ready dataset with minimal information loss.

---

## 🚀 Objectives

- Handle placeholder anomalies (`''`, `'UNKNOWN'`, `'ERROR'`) across **all columns**
- Standardize string fields by applying `LOWER()`, removing extra characters (spaces, dashes)
- Convert columns to appropriate data types using `TRY_CAST`
- Impute missing values using:
  - **Logical rules** (e.g., `quantity * price_per_unit = total_spent`)
  - **Statistical averages** (optional step)
- Use **modular CTEs** to structure the cleaning process
- Offer two alternative final cleaning strategies:
  - Drop remaining incomplete records (minimal data loss)
  - Impute remaining missing numeric values with column averages (retain more data)

---

## 🧰 Tools & Technologies

- **Microsoft SQL Server**
- **Common Table Expressions (CTEs)**
- Functions used: `CASE`, `TRY_CAST`, `LOWER`, `REPLACE`, `AVG`

---

## 🧼 Data Cleaning Pipeline (CTE Breakdown)

The project uses a series of 5 CTEs to progressively clean and enrich the dataset.

### 🔹 `clean_step1`: Standardization & Type Conversion

- Replaces anomalies like `''`, `'UNKNOWN'`, `'ERROR'`:
  - Converts them to `'unknown'` for string columns
  - Converts them to `NULL` for numeric/date columns
- Applies consistent formatting:
  - Lowercases all text
  - Replaces spaces/dashes where needed
- Converts data types using `TRY_CAST`

---

### 🔹 `clean_step2`: Impute Missing `price_per_unit`

- Fills `NULL` values in `price_per_unit` based on known item prices
- Only imputes price if `item != 'unknown'`

**Example logic:**
```sql
CASE 
      WHEN price_per_unit IS NULL AND item != 'unknown' THEN
        CASE 
          WHEN item = 'cake' THEN 3.0
          WHEN item = 'tea' THEN 1.5
          ELSE price_per_unit
        END
      ELSE price_per_unit
    END AS price_per_unit
```

---

### 🔹 `clean_step3`: Infer Missing `item` from `price_per_unit`

- Replaces `'unknown'` in `item` by reverse-mapping known `price_per_unit` values
- Applied only when `price_per_unit IS NOT NULL`

**Example logic:**
```sql
CASE 
      WHEN item = 'unknown' AND price_per_unit IS NOT NULL THEN
        CASE 
          WHEN price_per_unit = 1.0 THEN 'cookie'
          WHEN price_per_unit = 5.0 THEN 'salad'
          ELSE item
        END
      ELSE item
    END AS item
```

---

### 🔹 `clean_step4`: Calculate Missing Numeric Values

- Uses the formula: `quantity * price_per_unit = total_spent`
- If one of the three values is missing and the other two are known, it is calculated

**Example logic:**
```sql
    CASE 
      WHEN total_spent IS NULL AND quantity IS NOT NULL AND price_per_unit IS NOT NULL THEN 
        quantity * price_per_unit
      ELSE total_spent
    END AS total_spent
```

---

### 🔹 `clean_step5`: Two Final Cleaning Options

#### ✅ Option A: Drop Incomplete Rows

- Removes rows with any remaining `NULL` or `'unknown'` values
- Results in a loss of only 486 rows out of 10,000 (4.86%)
- Suitable when aiming for high data precision with minimal information loss

#### ✅ Option B: Impute Final Missing Numeric Values

- Fills in remaining `NULL` values in `quantity`, `price_per_unit`, and `total_spent` using column averages
- Suitable when:
  - Proportion of missing values is low (<10–15%)
  - Dataset is large enough to absorb the effect of imputation

**Example logic:**
```sql
COALESCE(
      quantity,
      (SELECT AVG(quantity) FROM clean_step4 WHERE quantity IS NOT NULL)
    ) AS quantity
```

---

## 📁 Project Structure

```
dirty_cafe_sales_project/
│
├── clean_cafe_sales.sql       -- Full SQL script with all cleaning steps and options
├── README.md                  -- Project documentation (this file)
└── (Optional: schema.txt, ER diagrams, or exploratory queries)
```

---

## 📊 Outcome

The project produces **two clean datasets** as final outcomes:

1. **High Precision Dataset (Option A)**  
   - All remaining `NULL` and `'unknown'` values are removed  
   - Ensures **high data precision**  
   - Results in **minimal data loss** (~4.86% of rows dropped)

2. **Imputed Dataset (Option B)**  
   - Retains **all original rows** (no data loss)  
   - Any remaining `NULL` values in numeric columns (`quantity`, `price_per_unit`, `total_spent`) are replaced with **column averages**  
   - Ensure data completeness (Completeness is more important than perfect precision)
