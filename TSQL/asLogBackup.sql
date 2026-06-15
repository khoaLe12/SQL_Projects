 CREATE OR ALTER PROCEDURE [dbo].[asLogBackup]
	@pRet Int OUTPUT
AS	
	SET NOCOUNT ON;
	SET @pRet= 0;

	BEGIN TRY
		DECLARE @backup_path Nvarchar(512) = '',
			@backup_name Nvarchar(100),
			@db Nvarchar(128),
			@paramDefinition Nvarchar(MAX),
			@sql Nvarchar(MAX),
			@stt Int = 1,
			@last_ref_backup_id Int = 0,
			@ref_backup_id Int = 0,
			@last_full_backup Int = 0,
			@ref_full_backup Int = 0,
			@auto_chain_initial Bit = 0,
			@root_level Hierarchyid = NULL,
			@last_level Hierarchyid = NULL,
			@next_level Hierarchyid = NULL,
			@start_time Datetimeoffset = GETDATE();


		SELECT TOP 1 
			@backup_path = [location],
			@auto_chain_initial = auto_chain_initial
		FROM [dbo].[sysBackupConfig]
		WHERE [type] = 'L'


		-- Retrieve recent backup
		SELECT TOP 1
			@ref_backup_id = id,
			@ref_full_backup = ref_backup_id
		FROM [dbo].[sysBackupHistory]
		WHERE [type] = 'I'
			AND [status] = '1'
		ORDER BY [timestamp] DESC

		SELECT TOP 1
			@last_full_backup = id
		FROM [dbo].[sysBackupHistory]
		WHERE [type] = 'D'
			AND [status] = '1'
			AND recovery_backup = 0
		ORDER BY [timestamp] DESC

		SELECT TOP 1
			@stt = stt,
			@last_ref_backup_id = ref_backup_id,
			@last_level = [level]
		FROM [dbo].[sysBackupHistory]
		WHERE [type] = 'L'
		ORDER BY [timestamp] DESC

		IF ISNULL(@ref_full_backup, 0) = 0 OR ISNULL(@last_full_backup, 0) = 0 OR @ref_full_backup <> @last_full_backup
		BEGIN
			DECLARE @pResult Int = 1;

			IF @auto_chain_initial = 1
			BEGIN
				EXEC [dbo].[asDifferentialBackup] @pResult OUTPUT
				SET @start_time = GETDATE();
			END

			IF @pResult <> 0
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
				SELECT
					@start_time,
					'L',
					'2',
					@stt,
					0,
					@ref_backup_id,
					'/',
					'',
					0,
					'Backup chain is invalid',
					0

				SET @pRet = 1;

				RETURN;
			END

			SELECT TOP 1
				@ref_backup_id = id,
				@ref_full_backup = ref_backup_id
			FROM [dbo].[sysBackupHistory]
			WHERE [type] = 'I'
				AND [status] = '1'
			ORDER BY [timestamp] DESC
		END

		IF @last_ref_backup_id <> @ref_backup_id
		BEGIN
			SET @stt = 0;
			SET @last_level = NULL
		END

		SELECT TOP 1
			@root_level = [level]
		FROM [dbo].[sysBackupHistory]
		WHERE id = @ref_backup_id
			AND [type] = 'I'

		SET @next_level = @root_level.GetDescendant(@last_level, NULL);



		-- Execute backup
		SET @stt = ISNULL(@stt, 0) + 1

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
		SET @backup_path = @backup_path + '\' + DB_NAME() + '_LogBackup_' + TRIM(CAST(@stt AS NVARCHAR(10))) + '.bak'

		SET @backup_name = N'LogBackup ' + CAST(NEWID() AS Nvarchar(36))

 		SET @db = DB_NAME()

		SET @paramDefinition = N'@file_path Nvarchar(255), @db Nvarchar(128), @backup_name Nvarchar(100)'
		SET @sql = '
			USE [master];
			BACKUP LOG @db
			TO DISK = @file_path
				WITH
					MEDIANAME = ''SQLProjectBackups'',
					NAME = @backup_name
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
		WHERE bs.type = 'L' AND bs.database_name = DB_NAME() AND bs.name = @backup_name AND bmf.physical_device_name = @backup_path

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
			SELECT
				@start_time,
				'L',
				'1',
				@stt,
				0,
				@ref_backup_id,
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
			SELECT
				@start_time,
				'L',
				'2',
				@stt,
				0,
				@ref_backup_id,
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
		SELECT
			@start_time,
			'L',
			'2',
			@stt,
			0,
			@ref_backup_id,
			@next_level,
			'',
			0,
			'Error Number: ' + CAST(ERROR_NUMBER() AS VARCHAR(10)) + ', Error Message: ' + ERROR_MESSAGE(),
			0

		SET @pRet = 2;
	END CATCH

	IF @pRet = 0 SET @pRet = @@ERROR

	IF OBJECT_ID('tempdb..#temp') IS NOT NULL
			DROP TABLE #temp

	SET NOCOUNT OFF;