SELECT TOP 100
	cst_id,
	cst_key
FROM bronze.crm_cust_info

SELECT TOP 100
	prd_key
FROM bronze.crm_prd_info

SELECT TOP 100
	sls_cust_id,
	sls_prd_key
FROM bronze.crm_sales_details



SELECT TOP 100
	cid
FROM bronze.erp_cust_az12

SELECT TOP 100
	cid
FROM bronze.erp_loc_a101

SELECT TOP 100
	id
FROM bronze.erp_px_cat_g1v2




-- Source CRM
IF OBJECT_ID('silver.crm_cust_info') IS NOT NULL
	DROP TABLE silver.crm_cust_info;
CREATE TABLE silver.crm_cust_info (
	cst_id Int,
	cst_key Nvarchar(50),
	cst_firstname Nvarchar(50),
	cts_lastname Nvarchar(50),
	cts_material_status Nvarchar(50),
	cst_gndr Nvarchar(50),
	cst_create_date Date,
	dwh_create_date Datetime2 DEFAULT GETDATE()
);

IF OBJECT_ID('silver.crm_prd_info') IS NOT NULL
	DROP TABLE silver.crm_prd_info;
CREATE TABLE silver.crm_prd_info (
	prd_id Int,
	prd_key Nvarchar(50),
	prd_nm Nvarchar(50),
	prd_cost Int,
	prd_line Nvarchar(50),
	prd_start_dt Date,
	prd_end_dt Date,
	dwh_create_date Datetime2 DEFAULT GETDATE()
);

IF OBJECT_ID('silver.crm_sales_details') IS NOT NULL
	DROP TABLE silver.crm_sales_details;
CREATE TABLE silver.crm_sales_details (
	sls_ord_num Nvarchar(50),
	sls_prd_key Nvarchar(50),
	sls_cust_id Int,
	sls_order_dt Int,
	sls_ship_dt Int,
	sls_due_dt Int,
	sls_sales Int,
	sls_quantity Int,
	sls_price Int,
	dwh_create_date Datetime2 DEFAULT GETDATE()
);



-- Source ERP
IF OBJECT_ID('silver.erp_cust_az12') IS NOT NULL
	DROP TABLE silver.erp_cust_az12;
CREATE TABLE silver.erp_cust_az12 (
	cid Nvarchar(50),
	bdate Date,
	gen Nvarchar(10),
	dwh_create_date Datetime2 DEFAULT GETDATE()
);

IF OBJECT_ID('silver.erp_loc_a101') IS NOT NULL
	DROP TABLE silver.erp_loc_a101;
CREATE TABLE silver.erp_loc_a101 (
	cid Nvarchar(50),
	cntry Nvarchar(50),
	dwh_create_date Datetime2 DEFAULT GETDATE()
);

IF OBJECT_ID('silver.erp_px_cat_g1v2') IS NOT NULL
	DROP TABLE silver.erp_px_cat_g1v2;
CREATE TABLE silver.erp_px_cat_g1v2 (
	id Nvarchar(50),
	cat Nvarchar(50),
	subcat Nvarchar(50),
	maintenance Nvarchar(10),
	dwh_create_date Datetime2 DEFAULT GETDATE()
);



-- Cleansing data
-- Check for null or duplicates in primary key
SELECT 
	cst_id,
	COUNT(*)
FROM bronze.crm_cust_info
GROUP BY cst_id
HAVING COUNT(*) > 1 OR cst_id IS NULL

SELECT *
FROM (
	SELECT 
		*,
		ROW_NUMBER() OVER (PARTITION BY cst_id ORDER BY cst_create_date DESC) AS flag_last
	FROM bronze.crm_cust_info
) t 
WHERE t.flag_last = 1



-- Check for unwanted spaces
SELECT
	*
FROM bronze.crm_cust_info
WHERE cst_firstname != TRIM(cst_firstname)
;
SELECT
	*
FROM bronze.crm_cust_info
WHERE cts_lastname != TRIM(cts_lastname)


SELECT 
	cst_id,
	cst_key,
	TRIM(cst_firstname) AS cst_firstname,
	TRIM(cts_lastname) AS cts_lastname,
	cts_material_status,
	cst_gndr,
	cst_create_date
FROM bronze.crm_cust_info




-- Data Standardization & Consistency
SELECT DISTINCT cst_gndr
FROM bronze.crm_cust_info

SELECT DISTINCT cts_material_status -- cst_martial_status
FROM bronze.crm_cust_info



-- Load data to silver layer
INSERT INTO silver.crm_cust_info (
	cst_id,
	cst_key,
	cst_firstname,
	cts_lastname,
	cts_material_status,
	cst_gndr,
	cst_create_date
)
SELECT 
	cst_id,
	cst_key,
	TRIM(cst_firstname) AS cst_firstname,
	TRIM(cts_lastname) AS cst_lastname,
	CASE UPPER(TRIM(cts_material_status))
		WHEN 'S' THEN 'Single'
		WHEN 'M' THEN 'Married'
		ELSE 'n/a'
	END AS cst_material_status,
	CASE UPPER(TRIM(cst_gndr))
		WHEN 'F' THEN 'Female'
		WHEN 'M' THEN 'Male'
		ELSE 'n/a'
	END AS cst_gndr,
	cst_create_date
FROM bronze.crm_cust_info
