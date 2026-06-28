USE [AdventureWorks2025_backup]
GO

CREATE OR ALTER PROCEDURE [dbo].[asFullBackup]
	@pDb_name Nvarchar(128),
	@pIs_recovery Bit = 0,
	@pRet Int OUTPUT,
	@pRecovery_id Int OUTPUT
AS	
	SET NOCOUNT ON;

	IF @pIs_recovery IS NULL
		SET @pIs_recovery = 0

	SET @pRet = 0;

	DECLARE @backup_path Nvarchar(512) = '',
			@backup_name Nvarchar(100),
			@db Nvarchar(128),
			@paramDefinition Nvarchar(MAX),
			@sql Nvarchar(MAX),
			@stt Int,
			@ref_backup_id Int,
			@last_level Hierarchyid = NULL,
			@next_level Hierarchyid = NULL,
			@start_time Datetimeoffset = GETDATE();
	DECLARE @inserted TABLE (id Int);

	BEGIN TRY
		SELECT TOP 1
			@stt = stt,
			@ref_backup_id = ref_backup_id,
			@last_level = [level]
		FROM [dbo].[sysBackupHistory]
		WHERE [type] = 'D'
		ORDER BY [timestamp] DESC

		SET @next_level = Hierarchyid::GetRoot().GetDescendant(@last_level, NULL);


		-- Construct backup file path
		SELECT TOP 1 
			@backup_path = [location]
		FROM [dbo].[sysBackupConfig]
		WHERE [type] = 'D'

		IF @backup_path IS NULL OR @backup_path = ''
		BEGIN
			IF ((@@microsoftversion / 0x1000000) & 0xff) > 10
				SELECT @backup_path = CAST(SERVERPROPERTY('InstanceDefaultBackupPath') AS Nvarchar)
			ELSE 
				EXEC master.dbo.xp_instance_regread
					N'HKEY_LOCAL_MACHINE',
					N'Software\Microsoft\MSSQLServer\MSSQLServer',
					N'BackupDirectory',
					@backup_path OUTPUT;
		END

		SET @backup_path = @backup_path + '\' + @pDb_name + '_FullBackup_' + CASE @pIs_recovery WHEN 1 THEN '_Recovery_' ELSE '' END + FORMAT(GETDATE(), 'yyyyMMdd') + '.bak'



		-- Execute backup
		SET @stt = ISNULL(@stt, 0) + 1
		SET @backup_name = N'FullBackup ' + CAST(NEWID() AS Nvarchar(36))
 		SET @db = @pDb_name
		SET @paramDefinition = N'@file_path Nvarchar(255), @db Nvarchar(128), @backup_name Nvarchar(100)'
		SET @sql = '
			BACKUP DATABASE @db
			TO DISK = @file_path
				WITH
					SKIP,
					NOREWIND,
					FORMAT,
					MEDIANAME = ''SQLProjectBackups'',
					NAME = @backup_name, 
					STATS = 50;
		'
		EXEC sp_executesql 
			@sql,
			@paramDefinition,
			@db = @db,
			@file_path = @backup_path,
			@backup_name = @backup_name



		-- Get backup information
		IF OBJECT_ID('tempdb..#temp') IS NOT NULL
			DROP TABLE #temp

		SELECT TOP 1
			bs.database_name AS database_name,
			CAST(bs.backup_size / 1024.0 / 1024 AS Decimal(10, 2)) AS backup_size_mb,
			bs.type AS backup_type,
			CASE bs.type
				WHEN 'D' THEN 'Full backup'
				WHEN 'L' THEN 'Log backup'
				WHEN 'I' THEN 'Differential backup'
			END AS backup_type_name,
			bs.backup_start_date AS backup_start_date,
			bs.backup_finish_date AS backup_finish_date,
			CAST(bs.backup_finish_date - backup_start_date AS TIME) AS backup_duration,
			bmf.physical_device_name
		INTO #temp
		FROM msdb.dbo.backupset bs
		INNER JOIN msdb.dbo.backupmediafamily bmf ON bmf.media_set_id = bs.media_set_id
		WHERE bs.type = 'D' AND bs.database_name = @pDb_name AND bs.name = @backup_name AND bmf.physical_device_name = @backup_path

		IF EXISTS (SELECT * FROM #temp)
		BEGIN
			INSERT INTO [dbo].[sysBackupHistory] (
				[timestamp],
				[type],
				[status],
				stt,
				recovery_backup,
				ref_backup_id,
				[level],
				[location],
				[size_mb],
				[error_message],
				[duration_sec]
			)
			OUTPUT INSERTED.id INTO @inserted(id)
			SELECT
				@start_time,
				'D',
				'1',
				@stt,
				@pIs_recovery,
				'',
				@next_level,
				physical_device_name,
				backup_size_mb,
				'',
				DATEDIFF(MILLISECOND, '00:00:00', backup_duration) / 1000.0
			FROM #temp
		END
		ELSE
		BEGIN
			INSERT INTO [dbo].[sysBackupHistory] (
				[timestamp],
				[type],
				[status],
				stt,
				recovery_backup,
				ref_backup_id,
				[level],
				[location],
				[size_mb],
				[error_message],
				[duration_sec]
			)
			OUTPUT INSERTED.id INTO @inserted(id)
			SELECT
				@start_time,
				'D',
				'2',
				@stt,
				@pIs_recovery,
				'',
				@next_level,
				'',
				0,
				'Backup set not found',
				0


			SET @pRet = 1;
		END
	END TRY
	BEGIN CATCH
		INSERT INTO [dbo].[sysBackupHistory] (
			[timestamp],
			[type],
			[status],
			stt,
			recovery_backup,
			ref_backup_id,
			[level],
			[location],
			[size_mb],
			[error_message],
			[duration_sec]
		)
		OUTPUT INSERTED.id INTO @inserted(id)
		SELECT
			@start_time,
			'D',
			'2',
			@stt,
			@pIs_recovery,
			'',
			@next_level,
			'',
			0,
			'Error Number: ' + CAST(ERROR_NUMBER() AS VARCHAR(10)) + ', Error Message: ' + ERROR_MESSAGE(),
			0

		SET @pRet = 2;
	END CATCH

	IF @pRet = 0 SET @pRet = @@ERROR

	-- IF @pIs_recovery = 1 SELECT * FROM @inserted
	SELECT TOP 1 @pRecovery_id = id FROM @inserted

	IF OBJECT_ID('tempdb..#temp') IS NOT NULL
			DROP TABLE #temp

	SET NOCOUNT OFF;