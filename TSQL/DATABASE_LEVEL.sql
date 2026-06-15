

USE [master];
ALTER DATABASE [AdventureWorks2025] SET RECOVERY FULL;


USE [AdventureWorks2025];
TRUNCATE TABLE sysBackupHistory

USE msdb;
GO
EXEC sp_delete_backuphistory @oldest_date = '01/01/2050';





use AdventureWorks2025

DECLARE @pRet Int
EXEC [dbo].[asFullBackup] 0, @pRet OUTPUT
SELECT @pRet

DECLARE @pRet Int
EXEC [dbo].[asDifferentialBackup] @pRet OUTPUT
SELECT @pRet

DECLARE @pRet Int
EXEC [dbo].[asLogBackup] @pRet OUTPUT
SELECT @pRet

select * from sysBackupHistory order by timestamp desc


DECLARE @pRet Int
EXEC [dbo].[asRestoreBackup] 1, @pRet OUTPUT
SELECT @pRet

USE [master]; ALTER DATABASE  MULTI_USER



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