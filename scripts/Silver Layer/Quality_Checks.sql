/*
===============================================================================
Quality Checks
===============================================================================

Script Purpose:
This script performs various quality checks for data consistency, accuracy,
completeness, and standardization across all tables in the 'silver' layer.

The validation checks include:
- NULL and duplicate primary key validation.
- Unwanted leading and trailing spaces.
- Data standardization and consistency checks.
- Invalid and missing values.
- Date validation and logical date sequence checks.
- Business rule validation.
- Cross-field consistency checks.

Usage Notes:
- Run these checks after loading data into the Silver Layer.
- Any returned records indicate potential data quality issues.
- Investigate and resolve all issues before loading data into the Gold Layer.
- Expected result for most validation queries is NO ROWS RETURNED.

===============================================================================
*/


-- ============================================================================
-- Checking 'silver.crm_cust_info'
-- Purpose: Validate customer master data
-- ============================================================================

-- Check for NULLs or Duplicates in Primary Key
-- Expectation: No Results
SELECT
    cst_id,
    COUNT(*) AS record_count
FROM silver.crm_cust_info
GROUP BY cst_id
HAVING COUNT(*) > 1
    OR cst_id IS NULL;


-- Check for Unwanted Spaces
-- Expectation: No Results
SELECT
    cst_key,
    cst_firstname,
    cst_lastname
FROM silver.crm_cust_info
WHERE cst_key != TRIM(cst_key)
   OR cst_firstname != TRIM(cst_firstname)
   OR cst_lastname != TRIM(cst_lastname);


-- Check Data Standardization & Consistency
SELECT DISTINCT
    cst_marital_status
FROM silver.crm_cust_info;


-- Check Data Standardization & Consistency
SELECT DISTINCT
    cst_gndr
FROM silver.crm_cust_info;


-- ============================================================================
-- Checking 'silver.crm_prd_info'
-- Purpose: Validate product master data
-- ============================================================================

-- Check for NULLs or Duplicates in Primary Key
-- Expectation: No Results
SELECT
    prd_id,
    COUNT(*) AS record_count
FROM silver.crm_prd_info
GROUP BY prd_id
HAVING COUNT(*) > 1
    OR prd_id IS NULL;


-- Check for Unwanted Spaces
-- Expectation: No Results
SELECT
    prd_key,
    prd_nm
FROM silver.crm_prd_info
WHERE prd_key != TRIM(prd_key)
   OR prd_nm != TRIM(prd_nm);


-- Check for NULL or Negative Product Cost
-- Expectation: No Results
SELECT
    prd_id,
    prd_cost
FROM silver.crm_prd_info
WHERE prd_cost IS NULL
   OR prd_cost < 0;


-- Check Data Standardization & Consistency
SELECT DISTINCT
    prd_line
FROM silver.crm_prd_info;


-- Check Product Category Consistency
SELECT DISTINCT
    prd_cat_id
FROM silver.crm_prd_info;


-- Check for Invalid Date Orders
-- Expectation: No Results
SELECT *
FROM silver.crm_prd_info
WHERE prd_end_dt < prd_start_dt;


-- ============================================================================
-- Checking 'silver.crm_sales_details'
-- Purpose: Validate sales transaction data
-- ============================================================================

-- Check for Missing Order Numbers
-- Expectation: No Results
SELECT *
FROM silver.crm_sales_details
WHERE sls_ord_num IS NULL;


-- Check for Missing Order Dates
-- Expectation: No Results
SELECT *
FROM silver.crm_sales_details
WHERE sls_order_dt IS NULL;


-- Check for Invalid Date Orders
-- Order Date should not be after Shipping or Due Date
-- Expectation: No Results
SELECT *
FROM silver.crm_sales_details
WHERE sls_order_dt > sls_ship_dt
   OR sls_order_dt > sls_due_dt;


-- Check for Invalid Quantity Values
-- Expectation: No Results
SELECT *
FROM silver.crm_sales_details
WHERE sls_quantity IS NULL
   OR sls_quantity <= 0;


-- Check for Invalid Price Values
-- Expectation: No Results
SELECT *
FROM silver.crm_sales_details
WHERE sls_price IS NULL
   OR sls_price <= 0;


-- Check for Invalid Sales Values
-- Expectation: No Results
SELECT *
FROM silver.crm_sales_details
WHERE sls_sales IS NULL
   OR sls_sales <= 0;


-- Check Data Consistency
-- Sales Amount = Quantity × Price
-- Expectation: No Results
SELECT DISTINCT
    sls_sales,
    sls_quantity,
    sls_price
FROM silver.crm_sales_details
WHERE sls_sales != (sls_quantity * sls_price);


-- Check for Duplicate Orders
-- Expectation: No Results
SELECT
    sls_ord_num,
    COUNT(*) AS record_count
FROM silver.crm_sales_details
GROUP BY sls_ord_num
HAVING COUNT(*) > 1;


-- ============================================================================
-- Checking 'silver.erp_cust_az12'
-- Purpose: Validate ERP customer demographic data
-- ============================================================================

-- Identify Out-of-Range Birth Dates
-- Expectation: Birth Dates Between 1924-01-01 and Today
SELECT DISTINCT
    bdate
FROM silver.erp_cust_az12
WHERE bdate < '1924-01-01'
   OR bdate > GETDATE();


-- Check Data Standardization & Consistency
SELECT DISTINCT
    gen
FROM silver.erp_cust_az12;


-- Check for Missing Customer IDs
-- Expectation: No Results
SELECT *
FROM silver.erp_cust_az12
WHERE cid IS NULL;


-- ============================================================================
-- Checking 'silver.erp_loc_a101'
-- Purpose: Validate customer location data
-- ============================================================================

-- Check Data Standardization & Consistency
SELECT DISTINCT
    cntry
FROM silver.erp_loc_a101
ORDER BY cntry;


-- Check for Unwanted Spaces
-- Expectation: No Results
SELECT *
FROM silver.erp_loc_a101
WHERE cntry != TRIM(cntry);


-- ============================================================================
-- Checking 'silver.erp_px_cat_g1v2'
-- Purpose: Validate product category reference data
-- ============================================================================

-- Check for Unwanted Spaces
-- Expectation: No Results
SELECT *
FROM silver.erp_px_cat_g1v2
WHERE cat != TRIM(cat)
   OR subcat != TRIM(subcat)
   OR maintenance != TRIM(maintenance);


-- Check Category Standardization
SELECT DISTINCT
    cat
FROM silver.erp_px_cat_g1v2;


-- Check Subcategory Standardization
SELECT DISTINCT
    subcat
FROM silver.erp_px_cat_g1v2;


-- Check Maintenance Standardization
SELECT DISTINCT
    maintenance
FROM silver.erp_px_cat_g1v2;


-- Check for NULL Values
-- Expectation: No Results
SELECT *
FROM silver.erp_px_cat_g1v2
WHERE cat IS NULL
   OR subcat IS NULL
   OR maintenance IS NULL;
