/*
==============================================================
Stored Procedure: Load Silver Layer (Bronze -> Silver)

Description:
This procedure cleans, transforms, and loads data from the
Bronze layer into the Silver layer.

Main Tasks:
- Clean and standardize raw data.
- Remove duplicate customer records.
- Handle missing and invalid values.
- Apply required data transformations.
- Track the loading time for each table.
==============================================================
*/

CREATE OR ALTER PROCEDURE silver.load_silver
AS
BEGIN

    DECLARE @start_time DATETIME,
            @end_time DATETIME,
            @batch_start_time DATETIME,
            @batch_end_time DATETIME;

    BEGIN TRY

        SET @batch_start_time = GETDATE();

        PRINT '================================================';
        PRINT 'Loading Silver Layer';
        PRINT '================================================';


        --------------------------------------------------------------
        -- 1. Table: crm_cust_info (Customer Information)
        --------------------------------------------------------------

        SET @start_time = GETDATE();

        PRINT '>> Loading silver.crm_cust_info';

        TRUNCATE TABLE silver.crm_cust_info;

        INSERT INTO silver.crm_cust_info (
            cst_id,
            cst_key,
            cst_firstname,
            cst_lastname,
            cst_material_status,
            cst_gender,
            cst_crate_date
        )
        SELECT
            cst_id,
            cst_key,

            -- Remove extra spaces from customer names
            TRIM(cst_firstname) AS cst_firstname,
            TRIM(cst_lastname) AS cst_lastname,

            -- Convert marital status codes into readable values
            CASE
                WHEN UPPER(TRIM(cst_material_status)) = 'S'
                    THEN 'Single'

                WHEN UPPER(TRIM(cst_material_status)) = 'M'
                    THEN 'Married'

                ELSE 'N/A'
            END AS cst_marital_status,

            -- Standardize gender values
            CASE
                WHEN UPPER(TRIM(cst_gender)) = 'F'
                    THEN 'Female'

                WHEN UPPER(TRIM(cst_gender)) = 'M'
                    THEN 'Male'

                ELSE 'N/A'
            END AS cst_gndr,

            cst_crate_date

        FROM (
            SELECT
                *,
                ROW_NUMBER() OVER (
                    PARTITION BY cst_id
                    ORDER BY cst_crate_date DESC
                ) AS flag_last

            FROM bronze.crm_cust_info

            -- Ignore records without customer ID
            WHERE cst_id IS NOT NULL
        ) t

        -- Keep the latest record for each customer
        WHERE flag_last = 1;


        SET @end_time = GETDATE();

        PRINT '>> Load Duration: '
            + CAST(
                DATEDIFF(
                    SECOND,
                    @start_time,
                    @end_time
                ) AS NVARCHAR
              )
            + ' seconds';

        PRINT '>> --------------------------------';


        --------------------------------------------------------------
        -- 2. Table: crm_prd_info (Product Information)
        --------------------------------------------------------------

        SET @start_time = GETDATE();

        PRINT '>> Loading silver.crm_prd_info';

        TRUNCATE TABLE silver.crm_prd_info;

        INSERT INTO silver.crm_prd_info (
            prd_id,
            cat_id,
            prd_key,
            prd_nm,
            prd_cost,
            prd_line,
            prd_start_dt,
            prd_end_dt
        )
        SELECT
            prd_id,

            -- Extract category ID from product key
            REPLACE(
                SUBSTRING(prd_key, 1, 5),
                '-',
                '_'
            ) AS cat_id,

            -- Extract product key
            SUBSTRING(
                prd_key,
                7,
                LEN(prd_key)
            ) AS prd_key,

            prd_nm,

            -- Replace missing costs with zero
            ISNULL(prd_cost, 0) AS prd_cost,

            -- Convert product line codes into readable values
            CASE
                WHEN UPPER(TRIM(prd_line)) = 'M'
                    THEN 'Mountain'

                WHEN UPPER(TRIM(prd_line)) = 'R'
                    THEN 'Road'

                WHEN UPPER(TRIM(prd_line)) = 'S'
                    THEN 'Other Sales'

                WHEN UPPER(TRIM(prd_line)) = 'T'
                    THEN 'Touring'

                ELSE 'N/A'
            END AS prd_line,

            -- Convert start date to DATE
            CAST(prd_start AS DATE) AS prd_start_dt,

            -- Set end date before the next product version
            CAST(
                LEAD(prd_start) OVER (
                    PARTITION BY prd_key
                    ORDER BY prd_start
                ) - 1
                AS DATE
            ) AS prd_end_dt

        FROM bronze.crm_prd_info;


        SET @end_time = GETDATE();

        PRINT '>> Load Duration: '
            + CAST(
                DATEDIFF(
                    SECOND,
                    @start_time,
                    @end_time
                ) AS NVARCHAR
              )
            + ' seconds';

        PRINT '>> --------------------------------';


        --------------------------------------------------------------
        -- 3. Table: crm_sales_details (Sales Information)
        --------------------------------------------------------------

        SET @start_time = GETDATE();

        PRINT '>> Loading silver.crm_sales_details';

        TRUNCATE TABLE silver.crm_sales_details;

        INSERT INTO silver.crm_sales_details (
            sls_ord_num,
            sls_ord_key,
            sls_cust_id,
            sls_order_dt,
            sls_ship_dt,
            sls_due_dt,
            sls_quantity,
            sls_sales,
            sls_price
        )
        SELECT
            sls_ord_num,
            sls_ord_key,
            sls_cust_id,

            -- Validate order date
            CASE
                WHEN sls_order_dt = 0
                     OR LEN(sls_order_dt) != 8
                    THEN NULL

                ELSE CAST(
                    CAST(sls_order_dt AS VARCHAR) AS DATE
                )
            END AS sls_order_dt,

            -- Validate shipping date
            CASE
                WHEN sls_ship_dt = 0
                     OR LEN(sls_ship_dt) != 8
                    THEN NULL

                ELSE CAST(
                    CAST(sls_ship_dt AS VARCHAR) AS DATE
                )
            END AS sls_ship_dt,

            -- Validate due date
            CASE
                WHEN sls_due_dt = 0
                     OR LEN(sls_due_dt) != 8
                    THEN NULL

                ELSE CAST(
                    CAST(sls_due_dt AS VARCHAR) AS DATE
                )
            END AS sls_due_dt,

            -- Recalculate incorrect sales values
            CASE
                WHEN sls_sales IS NULL
                     OR sls_sales <= 0
                     OR sls_sales != sls_quantity * ABS(sls_price)
                    THEN sls_quantity * ABS(sls_price)

                ELSE sls_sales
            END AS sls_sales,

            sls_quantity,

            -- Calculate price when the original value is invalid
            CASE
                WHEN sls_price IS NULL
                     OR sls_price <= 0
                    THEN sls_sales /
                         NULLIF(sls_quantity, 0)

                ELSE sls_price
            END AS sls_price

        FROM bronze.crm_sales_details;


        SET @end_time = GETDATE();

        PRINT '>> Load Duration: '
            + CAST(
                DATEDIFF(
                    SECOND,
                    @start_time,
                    @end_time
                ) AS NVARCHAR
              )
            + ' seconds';

        PRINT '>> --------------------------------';


        --------------------------------------------------------------
        -- 4. Table: erp_cust_az12 (Customer Demographics)
        --------------------------------------------------------------

        SET @start_time = GETDATE();

        PRINT '>> Loading silver.erp_cust_az12';

        TRUNCATE TABLE silver.erp_cust_az12;

        INSERT INTO silver.erp_cust_az12 (
            cid,
            bdate,
            gen
        )
        SELECT

            -- Remove NAS prefix from customer ID
            CASE
                WHEN cid LIKE 'NAS%'
                    THEN SUBSTRING(
                        cid,
                        4,
                        LEN(cid)
                    )

                ELSE cid
            END AS cid,

            -- Remove invalid future birth dates
            CASE
                WHEN bdate > GETDATE()
                    THEN NULL

                ELSE bdate
            END AS bdate,

            -- Standardize gender values
            CASE
                WHEN UPPER(TRIM(gen))
                     IN ('F', 'FEMALE')
                    THEN 'Female'

                WHEN UPPER(TRIM(gen))
                     IN ('M', 'MALE')
                    THEN 'Male'

                ELSE 'N/A'
            END AS gen

        FROM bronze.erp_cust_az12;


        SET @end_time = GETDATE();

        PRINT '>> Load Duration: '
            + CAST(
                DATEDIFF(
                    SECOND,
                    @start_time,
                    @end_time
                ) AS NVARCHAR
              )
            + ' seconds';

        PRINT '>> --------------------------------';


        --------------------------------------------------------------
        -- 5. Table: erp_loc_a101 (Customer Location)
        --------------------------------------------------------------

        SET @start_time = GETDATE();

        PRINT '>> Loading silver.erp_loc_a101';

        TRUNCATE TABLE silver.erp_loc_a101;

        INSERT INTO silver.erp_loc_a101 (
            cid,
            cntry
        )
        SELECT

            -- Remove hyphens from customer ID
            REPLACE(cid, '-', '') AS cid,

            -- Standardize country names
            CASE
                WHEN TRIM(cntry) = 'DE'
                    THEN 'Germany'

                WHEN TRIM(cntry)
                     IN ('US', 'USA')
                    THEN 'United States'

                WHEN cntry IS NULL
                     OR TRIM(cntry) = ''
                    THEN 'N/A'

                ELSE TRIM(cntry)
            END AS cntry

        FROM bronze.erp_loc_a101;


        SET @end_time = GETDATE();

        PRINT '>> Load Duration: '
            + CAST(
                DATEDIFF(
                    SECOND,
                    @start_time,
                    @end_time
                ) AS NVARCHAR
              )
            + ' seconds';

        PRINT '>> --------------------------------';


        --------------------------------------------------------------
        -- 6. Table: erp_px_cat_g1v2 (Product Categories)
        --------------------------------------------------------------

        SET @start_time = GETDATE();

        PRINT '>> Loading silver.erp_px_cat_g1v2';

        TRUNCATE TABLE silver.erp_px_cat_g1v2;

        INSERT INTO silver.erp_px_cat_g1v2 (
            id,
            cat,
            subcat,
            maintenance
        )
        SELECT
            id,
            cat,
            subcat,
            maintenance

        FROM bronze.erp_px_cat_g1v2;


        SET @end_time = GETDATE();

        PRINT '>> Load Duration: '
            + CAST(
                DATEDIFF(
                    SECOND,
                    @start_time,
                    @end_time
                ) AS NVARCHAR
              )
            + ' seconds';

        PRINT '>> --------------------------------';


        --------------------------------------------------------------
        -- Final Load Summary
        --------------------------------------------------------------

        SET @batch_end_time = GETDATE();

        PRINT '================================================';
        PRINT 'Silver Layer Loading Completed';

        PRINT 'Total Load Duration: '
            + CAST(
                DATEDIFF(
                    SECOND,
                    @batch_start_time,
                    @batch_end_time
                ) AS NVARCHAR
              )
            + ' seconds';

        PRINT '================================================';


    END TRY

    BEGIN CATCH

        PRINT '================================================';
        PRINT 'Error occurred while loading Silver Layer';

        PRINT 'Error Message: '
            + ERROR_MESSAGE();

        PRINT 'Error Number: '
            + CAST(ERROR_NUMBER() AS NVARCHAR);

        PRINT 'Error State: '
            + CAST(ERROR_STATE() AS NVARCHAR);

        PRINT '================================================';

    END CATCH

END;

EXEC silver.load_silver
