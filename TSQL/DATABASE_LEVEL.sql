
CREATE DATABASE [AdventureWorks2025_backup]

USE [master];
ALTER DATABASE [AdventureWorks2025] SET RECOVERY FULL;


USE [AdventureWorks2025_backup];
TRUNCATE TABLE sysBackupHistory

USE msdb;
GO
EXEC sp_delete_backuphistory @oldest_date = '01/01/2050';





use AdventureWorks2025_backup
DECLARE @pRet Int,
	@pRecovery_id Int
EXEC [dbo].[asFullBackup] 'AdventureWorks2025', 0, @pRet OUTPUT, @pRecovery_id OUTPUT
SELECT @pRet


use AdventureWorks2025_backup
DECLARE @pRet Int
EXEC [dbo].[asDifferentialBackup] 'AdventureWorks2025', @pRet OUTPUT
SELECT @pRet


use AdventureWorks2025_backup
DECLARE @pRet Int
EXEC [dbo].[asLogBackup] 'AdventureWorks2025', @pRet OUTPUT
SELECT @pRet



USE [AdventureWorks2025_backup];
select * from sysBackupHistory order by timestamp desc



USE [AdventureWorks2025_backup];
DECLARE @pRet Int
EXEC [dbo].[asRestoreBackup] 9, 'AdventureWorks2025', @pRet OUTPUT
SELECT @pRet



ALTER DATABASE AdventureWorks2025 SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
RESTORE DATABASE [AdventureWorks2025] FROM DISK = 'D:\Projects\SQL-Projects\Backup\Full\AdventureWorks2025_FullBackup_20260621.bak' WITH REPLACE, NORECOVERY
RESTORE LOG [AdventureWorks2025] FROM DISK = 'D:\Projects\SQL-Projects\Backup\Log\AdventureWorks2025_LogBackup_1.bak' WITH REPLACE, RECOVERY
ALTER DATABASE AdventureWorks2025 SET MULTI_USER



ALTER DATABASE AdventureWorks2025 SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
RESTORE DATABASE [AdventureWorks2025] FROM DISK = 'D:\Projects\SQL-Projects\Backup\Full\AdventureWorks2025_FullBackup_20260621.bak' WITH REPLACE, RECOVERY
ALTER DATABASE AdventureWorks2025 SET MULTI_USER

RESTORE DATABASE [AdventureWorks2025] FROM DISK = 'D:\Projects\SQL-Projects\Backup\Full\AdventureWorks2025_FullBackup__Recovery_20260621.bak' WITH REPLACE, RECOVERY

SELECT session_id, login_name, host_name
FROM sys.dm_exec_sessions
WHERE database_id = DB_ID('AdventureWorks2025');

kill 56

USE [master]; ALTER DATABASE AdventureWorks2025 SET MULTI_USER

SELECT TOP 1
		 ref_backup_id,
		 id,
		[type],
		[status],
		stt,
		[level]
	FROM [dbo].[sysBackupHistory]
	WHERE id = 9


select TOP 1 CAST([level] AS NVARCHAR(100)) from sysBackupHistory where group_level = 1 order by [level] desc
select CAST(MAX([level]) AS NVARCHAR(100)) AS [MAX Level] from sysBackupHistory GROUP BY group_level
select *, 
	group_level,
	CAST([Level] AS NVARCHAR(100)) AS [Converted Level], 
	CAST([Level].GetAncestor(0) AS NVARCHAR(100)) AS [Converted Ancestor Level 0] 
from sysBackupHistory order by timestamp DESC
select * from sysFullBackup
select * from sysDifferentialBackup
select * from sysLogBackup











use AdventureWorks2025

declare @level hierarchyid = (select TOP 1 [level]
from [dbo].[sysBackupHistory]
order by timestamp DESC)


declare @t Hierarchyid = 0x6B56

select [level]
from [dbo].[sysBackupHistory]
where group_level = 1 AND @t.IsDescendantOf([level]) = 1