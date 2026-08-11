IF OBJECT_ID('dbo.sysConfiguration', 'U') IS NULL
BEGIN
	CREATE TABLE [dbo].[sysConfiguration] (
		id Int NOT NULL PRIMARY KEY IDENTITY(1,1),
		[default] Bit NOT NULL DEFAULT 0,
		cuser Nvarchar(20) NOT NULL DEFAULT '',
		cdate Smalldatetime NOT NULL DEFAULT '',
		luser Nvarchar(20) NOT NULL DEFAULT '',
		ldate Smalldatetime NOT NULL DEFAULT '',
		full_backup_interval Int NOT NULL DEFAULT 7,
		differential_backup_interval Int NOT NULL DEFAULT 24,
		log_backup_interval Int NOT NULL DEFAULT 30,
		cdc_interval Int NOT NULL DEFAULT 5
	)

	IF NOT EXISTS (SELECT * FROM sys.indexes WHERE object_id = OBJECT_ID('dbo.sysConfiguration', 'U') AND name = 'Idx_sysConfiguration_default')
		CREATE NONCLUSTERED INDEX Idx_sysConfiguration_default ON [dbo].[sysConfiguration]([default])
END

IF NOT EXISTS (SELECT * FROM [dbo].[sysConfiguration])
BEGIN
	INSERT INTO [dbo].[sysConfiguration] (
		[default],
		cuser,
		cdate,
		luser,
		ldate,
		full_backup_interval,
		differential_backup_interval,
		log_backup_interval,
		cdc_interval
	)
	VALUES (
		1,
		'ADMIN',
		GETDATE(),
		'ADMIN',
		GETDATE(),
		7,
		24,
		30,
		5
	)
END