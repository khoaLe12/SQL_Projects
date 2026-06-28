USE [AdventureWorks2025_backup]
GO

IF OBJECT_ID('dbo.sysBackupConfig', 'U') IS NULL
BEGIN
	CREATE TABLE [dbo].[sysBackupConfig] (
		[type] Nvarchar(1) NOT NULL DEFAULT '',			-- D: Full backup, I: Differential backup, L: Log backup
		[location] Nvarchar(255) NOT NULL DEFAULT '',	-- directory path
		[description] Nvarchar(500) NOT NULL DEFAULT '',
		cdate Smalldatetime NOT NULL DEFAULT '',
		cuser Nvarchar(20) NOT NULL DEFAULT '',
		ldate Smalldatetime NOT NULL DEFAULT '',
		luser Nvarchar(20) NOT NULL DEFAULT '',
		CONSTRAINT PK_sysBackupConfig PRIMARY KEY ([type])
	)
END

IF NOT EXISTS (SELECT * FROM [dbo].[sysBackupConfig] WHERE [type] IN ('D', 'I', 'L'))
BEGIN
	INSERT INTO [dbo].[sysBackupConfig] ([type], [location], [description], cdate, cuser, ldate, luser)
	VALUES ('D', 'D:\Projects\SQL-Projects\Backup\Full', 'Full backup storage', GETDATE(), 'admin', GETDATE(), 'admin'),
		   ('I', 'D:\Projects\SQL-Projects\Backup\Differential', 'Differential backup storage', GETDATE(), 'admin', GETDATE(), 'admin'),
		   ('L', 'D:\Projects\SQL-Projects\Backup\Log', 'Log backup storage', GETDATE(), 'admin', GETDATE(), 'admin')

END

IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA = 'dbo' AND TABLE_NAME = 'sysBackupConfig' AND COLUMN_NAME = 'auto_chain_initial')
BEGIN
	ALTER TABLE [dbo].[sysBackupConfig] ADD auto_chain_initial Bit NOT NULL DEFAULT 0

	DECLARE @sql Nvarchar(MAX) = N'
		UPDATE [dbo].[sysBackupConfig]
		SET auto_chain_initial = 1
		WHERE [type] IN (''I'', ''L'')
	'
	EXEC(@sql)
END