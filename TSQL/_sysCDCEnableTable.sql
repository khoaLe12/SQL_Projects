IF OBJECT_ID('dbo.sysCDCEnableTable') IS NULL
BEGIN
	CREATE TABLE [dbo].[sysCDCEnableTable] (
		id Int NOT NULL IDENTITY(1, 1) PRIMARY KEY,
		table_name Nvarchar(128) NOT NULL DEFAULT '',
		cdc_enabled Bit NOT NULL DEFAULT 0,
		description Nvarchar(200) NOT NULL DEFAULT ''
	)

	IF NOT EXISTS (SELECT * FROM sys.indexes WHERE object_id = OBJECT_ID('dbo.sysCDCEnableTable') AND name = 'Idx_sysCDCEnableTable_TableName_CdcEnabled')
		CREATE NONCLUSTERED INDEX Idx_sysCDCEnableTable_TableName_CdcEnabled ON [dbo].[sysCDCEnableTable](table_name, cdc_enabled)
END

IF NOT EXISTS (SELECT * FROM [dbo].[sysCDCEnableTable])
BEGIN
	--TRUNCATE TABLE [dbo].[sysCDCEnableTable]
	INSERT INTO [dbo].[sysCDCEnableTable] (table_name, cdc_enabled, description)
	VALUES('Person.Address', 1, ''),
		  ('Person.BusinessEntity', 1, ''),
		  ('Person.BusinessEntityAddress', 1, '')
END

EXEC sys.sp_cdc_enable_table
	@source_schema = N'Person',
	@source_name = N'Address',
	@role_name = NULL,
	@capture_instance = NULL,
	@supports_net_changes = 1,
	@index_name = NULL,
	@captured_column_list = NULL,
	@filegroup_name = NULL

EXEC sys.sp_cdc_enable_table
	@source_schema = N'Person',
	@source_name = N'BusinessEntity',
	@role_name = NULL,
	@capture_instance = NULL,
	@supports_net_changes = 1,
	@index_name = NULL,
	@captured_column_list = NULL,
	@filegroup_name = NULL

EXEC sys.sp_cdc_enable_table
	@source_schema = N'Person',
	@source_name = N'BusinessEntityAddress',
	@role_name = NULL,
	@capture_instance = NULL,
	@supports_net_changes = 1,
	@index_name = NULL,
	@captured_column_list = NULL,
	@filegroup_name = NULL