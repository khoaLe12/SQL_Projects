USE [AdventureWorks2025_backup]
GO

CREATE OR ALTER PROCEDURE [dbo].[asDifferentialBackup_GetLast]
AS
	SELECT TOP 1
		id,
		[timestamp],
		[type],
		[status],
		stt,
		recovery_backup,
		ref_backup_id,
		[location],
		size_mb,
		[error_message],
		duration_sec,
		[level],
		group_level
	FROM sysBackupHistory
	WHERE [type] = 'I'
	ORDER BY [timestamp] DESC