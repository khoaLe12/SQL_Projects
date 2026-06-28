USE [AdventureWorks2025_backup]
GO

IF OBJECT_ID('dbo.sysBackupHistory', 'U') IS NULL
BEGIN
	CREATE TABLE [dbo].[sysBackupHistory] (
		id Int PRIMARY KEY IDENTITY(1, 1) NOT NULL,
		[timestamp] Datetimeoffset NOT NULL DEFAULT '',
		[type] Nvarchar(1) NOT NULL DEFAULT '',			-- D: Full backup, I: Differential backup, L: Log backup
		[status] Nvarchar(1) NOT NULL DEFAULT '',		-- 1. Success, 2. Fail
		stt Int NOT NULL DEFAULT 1,
		recovery_backup Bit NOT NULL DEFAULT 0,
		ref_backup_id Int NOT NULL DEFAULT 0,
		[location] Nvarchar(255) NOT NULL DEFAULT '',	-- Absolute path
		[size_mb] Decimal(10,2) NOT NULL DEFAULT 0,
		[error_message] Nvarchar(MAX) NOT NULL DEFAULT '',
		[duration_sec] Decimal(10,2) NOT NULL DEFAULT ''
	)

	IF NOT EXISTS (SELECT * FROM sys.indexes WHERE object_id = OBJECT_ID('dbo.sysBackupHistory') AND name = 'Idx_sysBackupHistory_Timestamp_Type_Stt')
		CREATE NONCLUSTERED INDEX Idx_sysBackupHistory_Timestamp_Type_Stt ON [dbo].[sysBackupHistory] ([timestamp], [type], stt) INCLUDE (ref_backup_id)

	IF NOT EXISTS (SELECT * FROM sys.indexes WHERE object_id = OBJECT_ID('dbo.sysBackupHistory') AND name = 'Idx_sysBackupHistory_Type_Status_Timestamp')
		CREATE NONCLUSTERED INDEX Idx_sysBackupHistory_Type_Status_Timestamp ON [dbo].[sysBackupHistory] ([type], [status], [timestamp] DESC) INCLUDE (ref_backup_id, stt)

	IF NOT EXISTS (SELECT * FROM sys.indexes WHERE object_id = OBJECT_ID('dbo.sysBackupHistory') AND name = 'Idx_sysBackupHistory_Type_Timestamp')
		CREATE NONCLUSTERED INDEX Idx_sysBackupHistory_Type_Timestamp ON [dbo].[sysBackupHistory] ([type], [timestamp] DESC) INCLUDE (ref_backup_id, stt)

	IF NOT EXISTS (SELECT * FROM sys.indexes WHERE object_id = OBJECT_ID('dbo.sysBackupHistory') AND name = 'Idx_sysBackupHistory_Type_Status_RecoveryBackup_Timestamp')
		CREATE NONCLUSTERED INDEX Idx_sysBackupHistory_Type_Status_RecoveryBackup_Timestamp ON [dbo].[sysBackupHistory] ([type], [status], recovery_backup, [timestamp] DESC) WHERE [type] = 'D' AND [status] = '1' AND recovery_backup = 0
END

IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA = 'dbo' AND TABLE_NAME = 'sysBackupHistory' AND COLUMN_NAME IN ('level', 'group_level'))
BEGIN
	ALTER TABLE [dbo].[sysBackupHistory] ADD [level] Hierarchyid NOT NULL DEFAULT '/'
	ALTER TABLE [dbo].[sysBackupHistory] ADD group_level AS [level].GetLevel()

	IF NOT EXISTS (SELECT * FROM sys.indexes WHERE object_id = OBJECT_ID('dbo.sysBackupHistory') AND name = 'Idx_sysBackupHistory_BFS')
		CREATE NONCLUSTERED INDEX Idx_sysBackupHistory_BFS ON [dbo].[sysBackupHistory] (group_level, [level])

	IF NOT EXISTS (SELECT * FROM sys.indexes WHERE object_id = OBJECT_ID('dbo.sysBackupHistory') AND name = 'Idx_sysBackupHistory_DFS')
		CREATE NONCLUSTERED INDEX Idx_sysBackupHistory_DFS ON [dbo].[sysBackupHistory] ([level]) INCLUDE (group_level, stt, [location], [status], [type])

	CREATE NONCLUSTERED INDEX Idx_sysBackupHistory_Type_Timestamp ON [dbo].[sysBackupHistory] ([type], [timestamp] DESC) INCLUDE (ref_backup_id, stt, [level]) WITH (DROP_EXISTING = ON)
END