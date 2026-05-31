IF OBJECT_ID('sysDictionary') IS NULL
BEGIN
	CREATE TABLE [dbo].[sysDictionary] (
		id Nvarchar(50) NOT NULL DEFAULT '',
		code_name Nvarchar(20) NOT NULL DEFAULT '',
		code_length Int NOT NULL DEFAULT '',
		table_name Nvarchar(50) NOT NULL DEFAULT '',
		schema_name Nvarchar(10) NOT NULL DEFAULT '',
		CONSTRAINT PK_sysDictionary PRIMARY KEY (id)
	)
	IF NOT EXISTS (SELECT * FROM sys.indexes WHERE object_id = OBJECT_ID('sysDictionary') AND name = 'Idx_sysDictionary_CodeName')
		CREATE NONCLUSTERED INDEX Idx_sysDictionary_CodeName ON sysDictionary(code_name)
END

IF NOT EXISTS (SELECT * FROM [dbo].[sysDictionary] WHERE code_name = 'ADDRESS_CODE')
BEGIN
	INSERT INTO [dbo].[sysDictionary] (id, code_name, code_length, table_name, schema_name)
	VALUES (NEWID(), 'ADDRESS_CODE', 20, 'Address', 'Person')
END

-- Add description
IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'sysDictionary' AND COLUMN_NAME = 'description')
BEGIN
	ALTER TABLE [dbo].[sysDictionary] ADD description Nvarchar(100) NOT NULL DEFAULT ''
END