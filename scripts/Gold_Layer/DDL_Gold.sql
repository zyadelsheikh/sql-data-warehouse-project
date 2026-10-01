/*
===============================================================================
                       SQL DATA WAREHOUSE - GOLD LAYER
-------------------------------------------------------------------------------
- OVERVIEW & ARCHITECTURE
-------------------------------------------------------------------------------
This script builds the analytical Gold Layer for the Data Warehouse.
The Gold Layer transforms cleansed, normalized data from the Silver Layer 
into a business-ready Star Schema comprised of:
  - Dimension Tables (dim_): Descriptive context (Who, What, Where).
  - Fact Tables (fact_): Numerical measures & metrics (Sales, Quantities).

Data Architecture Flow:
  [Source CSVs] ---> [Bronze (Raw)] ---> [Silver (Cleansed)] ---> [Gold (Views)]

-------------------------------------------------------------------------------
- OBJECTS CREATED IN THIS SCRIPT
-------------------------------------------------------------------------------
  1. gold.dim_customers : Customer Dimension View.
  2. gold.dim_products  : Product Dimension View.
  3. gold.fact_sales     : Sales Transactions Fact View.

===============================================================================
*/


-- =============================================================================
-- 1. View: gold.dim_customers
-- Purpose: Customer Dimension Table for Star Schema Analytics
-- =============================================================================

CREATE OR ALTER VIEW gold.dim_customers AS
SELECT 
    -- Surrogate Key for Data Warehouse modeling
    ROW_NUMBER() OVER (ORDER BY ci.cst_id) AS customer_key,
    
    -- Natural Keys & Attributes from CRM
    ci.cst_id              AS customer_id,
    ci.cst_key             AS customer_number,
    ci.cst_firstname       AS firstname,
    ci.cst_lastname        AS lastname,
    
    -- Attributes joined from ERP Location
    la.cntry               AS country,
    
    -- Demographic Attributes from CRM & ERP
    ci.cst_material_status AS marital_status,
    CASE 
        WHEN ci.cst_gender != 'N/A' THEN ci.cst_gender -- CRM is the primary master for Gender
        ELSE COALESCE(ca.gen, 'N/A')
    END                    AS gender,
    ca.bdate               AS birth_date,
    ci.cst_crate_date      AS create_date

FROM silver.crm_cust_info ci
LEFT JOIN silver.erp_cust_az12 ca 
    ON ci.cst_key = ca.cid
LEFT JOIN silver.erp_loc_a101 la 
    ON ci.cst_key = la.cid;
GO


-- =============================================================================
-- 2. View: gold.dim_products
-- Purpose: Product Dimension Table for Star Schema Analytics
-- =============================================================================

CREATE OR ALTER VIEW gold.dim_products AS
SELECT 
    -- Surrogate Key for Data Warehouse modeling
    ROW_NUMBER() OVER (ORDER BY pf.prd_start_dt, pf.prd_key) AS product_key,
    
    -- Natural Keys & Product Details
    pf.prd_id        AS product_id,
    pf.prd_key       AS product_number,
    pf.prd_nm        AS product_name,
    
    -- Category Hierarchy joined from ERP Category table
    pf.cat_id        AS category_id,
    pc.cat           AS category,
    pc.subcat        AS subcategory,
    pc.maintenance   AS maintenance,
    
    -- Cost & Historical Attributes
    pf.prd_cost      AS cost,
    pf.prd_line      AS product_line,
    pf.prd_start_dt  AS start_date

FROM silver.crm_prd_info pf
LEFT JOIN silver.erp_px_cat_g1v2 pc
    ON pf.cat_id = pc.id
WHERE pf.prd_end_dt IS NULL; -- Filter out historical data to keep only active products
GO


-- =============================================================================
-- 3. View: gold.fact_sales
-- Purpose: Sales Fact Table for Star Schema Analytics
-- =============================================================================

CREATE OR ALTER VIEW gold.fact_sales AS 
SELECT 
    -- Transaction Identifiers
    sd.sls_ord_num   AS order_number,
    
    -- Dimension Foreign Keys (Surrogate Keys)
    pr.product_key   AS product_key,
    cu.customer_key  AS customer_key,
    
    -- Dates & Timestamps
    sd.sls_order_dt  AS order_date,  
    sd.sls_ship_dt   AS shipping_date,
    sd.sls_due_dt    AS due_date,
    
    -- Transactional Metrics / Measures
    sd.sls_sales     AS sales_amount,
    sd.sls_quantity  AS quantity,
    sd.sls_price     AS price

FROM silver.crm_sales_details sd
LEFT JOIN gold.dim_products pr 
    ON sd.sls_prd_key = pr.product_number 
LEFT JOIN gold.dim_customers cu
    ON sd.sls_cust_id = cu.customer_id;
GO
