 CREATE OR ALTER PROCEDURE [dbo].[asFullBackup]
	@pLocation Nvarchar(100),
	@pBackupFile Nvarchar(100),
	@pRet Int OUTPUT
AS
	IF @pLocation IS NULL OR @pLocation = ''
	BEGIN
		SET @pRet = 1
		RETURN;
	END

	IF @pBackupFile IS NULL OR @pBackupFile = ''
	BEGIN
		SET @pRet = 2
		RETURN;
	END

	DECLARE @file_path Nvarchar(255) = @pLocation + @pBackupFile
	DECLARE @db Nvarchar(128) = QUOTENAME(DB_NAME())
	DECLARE @paramDefinition Nvarchar(MAX) = N'@file_path Nvarchar(255), @db Nvarchar(128)'
	DECLARE @sql Nvarchar(MAX) = '
	USE [master];
	BACKUP DATABASE @db
	TO DISK = @file_path
		WITH
			SKIP,
			NOREWIND,
			FORMAT,
			MEDIANAME = ''SQLProjectBackups'',
			NAME = N''Full backup of SQLProjectDB'', 
			STATS = 10;
	'
	EXEC sp_executesql 
		@sql,
		@paramDefinition,
		@db,
		@file_path