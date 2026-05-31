IF OBJECT_ID('dbo.sysDAOInfo', 'U') IS NOT NULL
	DROP TABLE dbo.sysDAOInfo

IF OBJECT_ID('dbo.sysDAOInfo', 'U') IS NULL
BEGIN
	CREATE TABLE [dbo].[sysDAOInfo] (
		id Nvarchar(50) NOT NULL DEFAULT '',
		code_name Nvarchar(20) NOT NULL DEFAULT '',
		sp_schema Nvarchar(10) NOT NULL DEFAULT '',
		sp_get Nvarchar(100) NOT NULL DEFAULT '',
		sp_ins Nvarchar(100) NOT NULL DEFAULT '',
		sp_upd Nvarchar(100) NOT NULL DEFAULT '',
		sp_del Nvarchar(100) NOT NULL DEFAULT '',
		CONSTRAINT PK_sysDAOInfo PRIMARY KEY (id)
	)

	IF NOT EXISTS (SELECT * FROM sys.indexes WHERE object_id = OBJECT_ID('dbo.sysDAOInfo', 'U') AND name = 'IX_sysDAOInfo_CodeName')
		CREATE NONCLUSTERED INDEX IX_sysDAOInfo_CodeName ON [dbo].[sysDAOInfo](code_name)
END

IF NOT EXISTS (SELECT * FROM [dbo].[sysDAOInfo] WHERE code_name = 'ADDRESS_CODE')
BEGIN
	INSERT INTO [dbo].[sysDAOInfo] (id, code_name, sp_get, sp_ins, sp_upd, sp_del)
	VALUES (NEWID(), 'ADDRESS_CODE', 'asAddressGet', 'asAddressIns', 'asAddressUpd', 'asAddressDel')
END