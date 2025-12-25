-- Source CRM
IF OBJECT_ID('bronze.crm_cust_info') IS NOT NULL
	DROP TABLE bronze.crm_cust_info;
CREATE TABLE bronze.crm_cust_info (
	cst_id Int,
	cst_key Nvarchar(50),
	cst_firstname Nvarchar(50),
	cts_lastname Nvarchar(50),
	cts_material_status Nvarchar(50),
	cst_gndr Nvarchar(50),
	cst_create_date Date
);

IF OBJECT_ID('bronze.crm_prd_info') IS NOT NULL
	DROP TABLE bronze.crm_prd_info;
CREATE TABLE bronze.crm_prd_info (
	prd_id Int,
	prd_key Nvarchar(50),
	prd_nm Nvarchar(50),
	prd_cost Int,
	prd_line Nvarchar(50),
	prd_start_dt Date,
	prd_end_dt Date
);

IF OBJECT_ID('bronze.crm_sales_details') IS NOT NULL
	DROP TABLE bronze.crm_sales_details;
CREATE TABLE bronze.crm_sales_details (
	sls_ord_num Nvarchar(50),
	sls_prd_key Nvarchar(50),
	sls_cust_id Int,
	sls_order_dt Int,
	sls_ship_dt Int,
	sls_due_dt Int,
	sls_sales Int,
	sls_quantity Int,
	sls_price Int
);



-- Source ERP
IF OBJECT_ID('bronze.erp_cust_az12') IS NOT NULL
	DROP TABLE bronze.erp_cust_az12;
CREATE TABLE bronze.erp_cust_az12 (
	cid Nvarchar(50),
	bdate Date,
	gen Nvarchar(10)
);

IF OBJECT_ID('bronze.erp_loc_a101') IS NOT NULL
	DROP TABLE bronze.erp_loc_a101;
CREATE TABLE bronze.erp_loc_a101 (
	cid Nvarchar(50),
	cntry Nvarchar(50)
);

IF OBJECT_ID('bronze.erp_px_cat_g1v2') IS NOT NULL
	DROP TABLE bronze.erp_px_cat_g1v2;
CREATE TABLE bronze.erp_px_cat_g1v2 (
	id Nvarchar(50),
	cat Nvarchar(50),
	subcat Nvarchar(50),
	maintenance Nvarchar(10)
);


EXEC bronze.Sload_bronze

CREATE OR ALTER PROCEDURE bronze.Sload_bronze AS
BEGIN
	SET NOCOUNT ON;
	PRINT CHAR(13) + CHAR(10);
	DECLARE @start_time DATETIME, @end_time DATETIME;
	BEGIN TRY

		SET @start_time = GETDATE();

		TRUNCATE TABLE bronze.crm_cust_info;
		BULK INSERT bronze.crm_cust_info
		FROM 'D:\Projects\SQL-Projects\sql-data-warehouse-project\datasets\source_crm\cust_info.csv'
		WITH (
			FIRSTROW = 2,
			FIELDTERMINATOR = ',',
			TABLOCK
		);
		PRINT 'INSERTED ' + CAST(@@ROWCOUNT AS Nvarchar) + ' rows into crm_cust_info'

		TRUNCATE TABLE bronze.crm_prd_info;
		BULK INSERT bronze.crm_prd_info
		FROM 'D:\Projects\SQL-Projects\sql-data-warehouse-project\datasets\source_crm\prd_info.csv'
		WITH (
			FIRSTROW = 2,
			FIELDTERMINATOR = ',',
			TABLOCK
		);
		PRINT 'INSERTED ' + CAST(@@ROWCOUNT AS Nvarchar) + ' rows into crm_prd_info'

		TRUNCATE TABLE bronze.crm_sales_details;
		BULK INSERT bronze.crm_sales_details
		FROM 'D:\Projects\SQL-Projects\sql-data-warehouse-project\datasets\source_crm\sales_details.csv'
		WITH (
			FIRSTROW = 2,
			FIELDTERMINATOR = ',',
			TABLOCK
		);
		PRINT 'INSERTED ' + CAST(@@ROWCOUNT AS Nvarchar) + ' rows into crm_sales_details'

		SET @end_time = GETDATE();
		PRINT CHAR(13) + CHAR(10);
		PRINT 'Load duration: ' + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS Nvarchar) + ' seconds';
		PRINT CHAR(13) + CHAR(10);
		---------------

		PRINT CHAR(13) + CHAR(10);
		SET @start_time = GETDATE();

		TRUNCATE TABLE bronze.erp_cust_az12;
		BULK INSERT bronze.erp_cust_az12
		FROM 'D:\Projects\SQL-Projects\sql-data-warehouse-project\datasets\source_erp\CUST_AZ12.csv'
		WITH (
			FIRSTROW = 2,
			FIELDTERMINATOR = ',',
			TABLOCK
		);
		PRINT 'INSERTED ' + CAST(@@ROWCOUNT AS Nvarchar) + ' rows into erp_cust_az12'

		TRUNCATE TABLE bronze.erp_loc_a101;
		BULK INSERT bronze.erp_loc_a101
		FROM 'D:\Projects\SQL-Projects\sql-data-warehouse-project\datasets\source_erp\LOC_A101.csv'
		WITH (
			FIRSTROW = 2,
			FIELDTERMINATOR = ',',
			TABLOCK
		);
		PRINT 'INSERTED ' + CAST(@@ROWCOUNT AS Nvarchar) + ' rows into erp_loc_a101'

		TRUNCATE TABLE bronze.erp_px_cat_g1v2;
		BULK INSERT bronze.erp_px_cat_g1v2
		FROM 'D:\Projects\SQL-Projects\sql-data-warehouse-project\datasets\source_erp\PX_CAT_G1V2.csv'
		WITH (
			FIRSTROW = 2,
			FIELDTERMINATOR = ',',
			TABLOCK
		);
		PRINT 'INSERTED ' + CAST(@@ROWCOUNT AS Nvarchar) + ' rows into erp_px_cat_g1v2'

		SET @end_time = GETDATE();

		PRINT CHAR(13) + CHAR(10);
		PRINT 'Load duration: ' + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS Nvarchar) + ' seconds';

	END TRY
	BEGIN CATCH
		PRINT 'ERROR OCCURED DURING LOADING BRONZE LAYER'
		PRINT 'Error Message: ' + ERROR_MESSAGE();
		PRINT 'Error Message: ' + CAST(ERROR_NUMBER() AS Nvarchar);
		PRINT 'Error Message: ' + CAST(ERROR_STATE() AS Nvarchar);
	END CATCH
	SET NOCOUNT OFF
END;

