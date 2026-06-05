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