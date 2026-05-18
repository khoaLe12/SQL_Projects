IF OBJECT_ID('dbo.sysDAOInfo', 'U') IS NULL
BEGIN
	CREATE TABLE [dbo].[sysDAOInfo] (
		id Nvarchar(50) NOT NULL DEFAULT '',
		schema_name Nvarchar(10) NOT NULL DEFAULT '',
		table_name Nvarchar(50) NOT NULL DEFAULT '',
		sp_get Nvarchar(100) NOT NULL DEFAULT '',
		sp_ins Nvarchar(100) NOT NULL DEFAULT '',
		sp_upd Nvarchar(100) NOT NULL DEFAULT '',
		sp_del Nvarchar(100) NOT NULL DEFAULT '',
		CONSTRAINT PK_sysDAOInfo PRIMARY KEY (id)
	)

	IF NOT EXISTS (SELECT * FROM sys.indexes WHERE object_id = OBJECT_ID('dbo.sysDAOInfo', 'U') AND name = 'IX_sysDAOInfo_SchemaName_TableName')
		CREATE NONCLUSTERED INDEX IX_sysDAOInfo_SchemaName_TableName ON [dbo].[sysDAOInfo](schema_name, table_name)
END

IF NOT EXISTS (SELECT * FROM [dbo].[sysDAOInfo] WHERE schema_name = 'Person' AND table_name = 'Address')
BEGIN
	INSERT INTO [dbo].[sysDAOInfo] (id, schema_name, table_name, sp_get, sp_ins, sp_upd, sp_del)
	VALUES (NEWID(), 'Person', 'Address', 'dbo.asAddressGet', 'dbo.asAddressIns', 'dbo.asAddressUpd', 'dbo.asAddressDel')
END