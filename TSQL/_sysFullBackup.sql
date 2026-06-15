IF OBJECT_ID('dbo.sysFullBackup', 'U') IS NULL
BEGIN
	CREATE TABLE [dbo].[sysFullBackup] (
		id Int PRIMARY KEY IDENTITY(1, 1) NOT NULL,
		[timestamp] Datetime NOT NULL DEFAULT '',
		[status] Nvarchar(1) NOT NULL DEFAULT '',		-- 1. Success, 2. Fail
		[location] Nvarchar(255) NOT NULL DEFAULT '',	-- Absolute path
		[size_mb] Decimal(10,2) NOT NULL DEFAULT 0,
		[error_message] Nvarchar(MAX) NOT NULL DEFAULT '',
		[duration_sec] Decimal(10,2) NOT NULL DEFAULT ''
	)

	IF NOT EXISTS (SELECT * FROM sys.indexes WHERE object_id = OBJECT_ID('dbo.sysFullBackup') AND name = 'Idx_sysFullBackup_Status_Timestamp_Type')
		CREATE NONCLUSTERED INDEX Idx_sysFullBackup_Status_Timestamp_Type ON [dbo].[sysFullBackup] ([status], [timestamp])

	IF NOT EXISTS (SELECT * FROM sys.indexes WHERE object_id = OBJECT_ID('dbo.sysFullBackup') AND name = 'Idx_sysFullBackup_Timestamp')
		CREATE NONCLUSTERED INDEX Idx_sysFullBackup_Timestamp ON [dbo].[sysFullBackup] ([timestamp])
END