IF OBJECT_ID('dbo.sysLogBackup', 'U') IS NULL
BEGIN
	CREATE TABLE [dbo].[sysLogBackup] (
		id Int PRIMARY KEY IDENTITY(1, 1) NOT NULL,
		[timestamp] Datetime NOT NULL DEFAULT '',
		[status] Nvarchar(1) NOT NULL DEFAULT '',		-- 1. Success, 2. Fail
		[location] Nvarchar(255) NOT NULL DEFAULT '',	-- Absolute path
		[size_mb] Decimal(10,2) NOT NULL DEFAULT 0,
		[error_message] Nvarchar(MAX) NOT NULL DEFAULT '',
		[duration_sec] Decimal(10,2) NOT NULL DEFAULT ''
	)

	IF NOT EXISTS (SELECT * FROM sys.indexes WHERE object_id = OBJECT_ID('dbo.sysLogBackup') AND name = 'Idx_sysLogBackup_Status_Timestamp_Type')
		CREATE NONCLUSTERED INDEX Idx_sysLogBackup_Status_Timestamp_Type ON [dbo].[sysLogBackup] ([status], [timestamp])

	IF NOT EXISTS (SELECT * FROM sys.indexes WHERE object_id = OBJECT_ID('dbo.sysLogBackup') AND name = 'Idx_sysLogBackup_Timestamp')
		CREATE NONCLUSTERED INDEX Idx_sysLogBackup_Timestamp ON [dbo].[sysLogBackup] ([timestamp])
END