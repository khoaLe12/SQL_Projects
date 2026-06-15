IF OBJECT_ID('dbo.sysDifferentialBackup', 'U') IS NULL
BEGIN
	CREATE TABLE [dbo].[sysDifferentialBackup] (
		id Int PRIMARY KEY IDENTITY(1, 1) NOT NULL,
		[timestamp] Datetime NOT NULL DEFAULT '',
		[status] Nvarchar(1) NOT NULL DEFAULT '',		-- 1. Success, 2. Fail
		[location] Nvarchar(255) NOT NULL DEFAULT '',	-- Absolute path
		[size_mb] Decimal(10,2) NOT NULL DEFAULT 0,
		[error_message] Nvarchar(MAX) NOT NULL DEFAULT '',
		[duration_sec] Decimal(10,2) NOT NULL DEFAULT ''
	)

	IF NOT EXISTS (SELECT * FROM sys.indexes WHERE object_id = OBJECT_ID('dbo.sysDifferentialBackup') AND name = 'Idx_sysDifferentialBackup_Status_Timestamp_Type')
		CREATE NONCLUSTERED INDEX Idx_sysDifferentialBackup_Status_Timestamp_Type ON [dbo].[sysDifferentialBackup] ([status], [timestamp])

	IF NOT EXISTS (SELECT * FROM sys.indexes WHERE object_id = OBJECT_ID('dbo.sysDifferentialBackup') AND name = 'Idx_sysDifferentialBackup_Timestamp')
		CREATE NONCLUSTERED INDEX Idx_sysDifferentialBackup_Timestamp ON [dbo].[sysDifferentialBackup] ([timestamp])
END