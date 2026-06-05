IF OBJECT_ID('dbo.sysDAOInfo', 'U') IS NULL
BEGIN
	CREATE TABLE [dbo].[sysDAOInfo] (
		id Nvarchar(50) NOT NULL DEFAULT '',
		table_schema Nvarchar(10) NOT NULL DEFAULT '',
		table_name Nvarchar(50) NOT NULL DEFAULT '',
		sp_schema Nvarchar(10) NOT NULL DEFAULT '',
		sp_get Nvarchar(100) NOT NULL DEFAULT '',
		sp_ins Nvarchar(100) NOT NULL DEFAULT '',
		sp_upd Nvarchar(100) NOT NULL DEFAULT '',
		sp_del Nvarchar(100) NOT NULL DEFAULT '',
		CONSTRAINT PK_sysDAOInfo PRIMARY KEY (id)
	)

	IF NOT EXISTS (SELECT * FROM sys.indexes WHERE object_id = OBJECT_ID('dbo.sysDAOInfo', 'U') AND name = 'IX_sysDAOInfo_TableSchema_TableName')
		CREATE NONCLUSTERED INDEX IX_sysDAOInfo_SchemaName_TableName ON [dbo].[sysDAOInfo](table_schema, table_name)
END

IF NOT EXISTS (SELECT * FROM [dbo].[sysDAOInfo] WHERE table_schema = 'Person' AND table_name = 'Address')
BEGIN
	INSERT INTO [dbo].[sysDAOInfo] (id, table_schema, table_name, sp_schema, sp_get, sp_ins, sp_upd, sp_del)
	VALUES (NEWID(), 'Person', 'Address', 'dbo', 'asAddressGet', 'asAddressIns', 'asAddressUpd', 'asAddressDel')
END