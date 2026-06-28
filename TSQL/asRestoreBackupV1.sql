USE [AdventureWorks2025_backup]
GO

CREATE OR ALTER PROCEDURE [dbo].[asRestoreBackupV1]
	@pId Int,
	@db Nvarchar(128),
	@pRet Int OUTPUT
AS
	SET @pRet = 0;
	IF @pId	IS NULL OR @pId = 0 RETURN;

	SET NOCOUNT ON;

	DECLARE @ref_backup_id Int = 0,
		@backup_id Int = 0,
		@status Nvarchar(1) = '1',
		@type Nvarchar(1) = '',
		@stt Int,
		@level Hierarchyid,
		@group_level Int,
		@backup_path Nvarchar(512),
		@sql Nvarchar(MAX) = '',
		@paramDefinition Nvarchar(MAX);


	-- Setup database before restoring
	SET @sql = 'USE [master]; ALTER DATABASE ' + @db + ' SET SINGLE_USER WITH ROLLBACK IMMEDIATE; CHECKPOINT;'
	EXEC(@sql)


	-- 
	SET @sql = N'
	USE ' + @db + '
	SELECT TOP 1
		@ref_backup_id = ref_backup_id,
		@backup_id = id,
		@type = [type],
		@status = [status],
		@stt = stt,
		@level = [level]
	FROM [dbo].[sysBackupHistory]
	WHERE id = @pId
	'
	SET @paramDefinition = N'
		@pId Int,
		@ref_backup_id Int OUTPUT,
		@backup_id Int OUTPUT,
		@type Nvarchar(1) OUTPUT,
		@status Nvarchar(1) OUTPUT,
		@stt Int OUTPUT,
		@level Hierarchyid OUTPUT
	'
	EXEC sp_executesql
		@sql,
		@paramDefinition,
		@pId = @pId,
		@ref_backup_id = @ref_backup_id OUTPUT,
		@backup_id = @backup_id OUTPUT,
		@type = @type OUTPUT,
		@status = @status OUTPUT,
		@stt = @stt OUTPUT,
		@level = @level OUTPUT




	-- A. Validate backup information
	IF ISNULL(@backup_id, 0) = 0
	BEGIN
		SET @pRet = 1;
		GOTO EndSection;
	END

	IF @status = '2'
	BEGIN
		SET @pRet = 2;
		GOTO EndSection;
	END

	IF @type NOT IN ('D', 'I', 'L')
	BEGIN
		SET @pRet = 3;
		GOTO EndSection;
	END



	-- B. Validate backup chain
	Declare @last_full_backup Int = 0,
		@ref_full_backup Int = 0;

	SET @sql = N'
	USE ' + @db + '
	SELECT TOP 1 
		@last_full_backup = id
	FROM [dbo].[sysBackupHistory]
	WHERE [type] = ''D''
		AND [status] = ''1''
		AND recovery_backup = 0
	ORDER BY [timestamp] DESC
	'
	SET @paramDefinition = N'
		@last_full_backup Int OUTPUT
	'
	EXEC sp_executesql
		@sql,
		@paramDefinition,
		@last_full_backup = @last_full_backup OUTPUT

	SET @sql = N'
	USE ' + @db + '
	SELECT TOP 1
		@ref_full_backup = id
	FROM [dbo].[sysBackupHistory]
	WHERE group_level = 1
		AND [level] = @level.GetAncestor(
			CASE @type
				WHEN ''D'' THEN 0
				WHEN ''I'' THEN 1
				WHEN ''L'' THEN 2
			END
		)
	'
	SET @paramDefinition = N'
		@ref_full_backup Int OUTPUT,
		@level Hierarchyid,
		@type Nvarchar(1)
	'
	EXEC sp_executesql
		@sql,
		@paramDefinition,
		@level = @level,
		@type = @type,
		@ref_full_backup = @ref_full_backup OUTPUT

	IF @last_full_backup <> @ref_full_backup
	BEGIN
		SET @pRet = 4;
		GOTO EndSection;
	END



	-- C. Construct backup sequence
	IF OBJECT_ID('tempdb..#backup_list') IS NOT NULL 
		DROP TABLE #backup_list;
	IF OBJECT_ID('tempdb..#sequence') IS NOT NULL 
		DROP TABLE #sequence;
	CREATE TABLE #backup_list([level] Hierarchyid)
	CREATE TABLE #sequence ([order] Int, stt Int, [location] Nvarchar(255), [type] Nvarchar(1), final Bit);

	-- 1. Get all ancestors
	WITH CTE_Ancestors AS (
		SELECT 
			@level AS [level],
			@group_level AS group_level

		UNION ALL

		SELECT
			[level].GetAncestor(1),
			group_level - 1
		FROM CTE_Ancestors
		WHERE group_level - 1 > 0
	)
	INSERT INTO #backup_list([level])
	SELECT [level]
	FROM CTE_Ancestors

	-- 2. Get all log sequences
	IF @type = 'L'
	BEGIN
		SET @sql = N'
		USE ' + @db + '
		INSERT INTO #backup_list([level])
		SELECT [level]
		FROM [dbo].[sysBackupHistory]
		WHERE group_level = 3 AND [level].IsDescendantOf(@level.GetAncestor(1)) = 1 AND stt <= @stt
		'
		SET @paramDefinition = N'
			@level Hierarchyid,
			@stt Int
		'
		EXEC sp_executesql
			@sql,
			@paramDefinition,
			@level = @level,
			@stt = @stt
	END

	-- 3. Build sequences
	SET @sql = N'
	USE ' + @db + '
	INSERT INTO #sequence ([order], stt, [location], [type], final)
	SELECT group_level, stt, [location], [type], CASE id WHEN @backup_id THEN 1 ELSE 0 END
	FROM [dbo].[sysBackupHistory]
	WHERE [level] IN (SELECT [level] FROM #backup_list)
		AND [status] = ''1''
	'
	SET @paramDefinition = N'
		@backup_id Int
	'
	EXEC sp_executesql
		@sql,
		@paramDefinition,
		@backup_id = @backup_id

	-- 4. Check if sequences break caused by status = '2' Failed
	IF NOT EXISTS (SELECT * FROM #sequence WHERE [type] = 'D')
	BEGIN
		SET @pRet = 5;
		GOTO EndSection;
	END

	IF @type IN ('I', 'L')
	BEGIN
		IF NOT EXISTS (SELECT * FROM #sequence WHERE [type] = 'I')
		BEGIN
			SET @pRet = 6;
			GOTO EndSection;
		END
	END

	IF @type = 'L'
	BEGIN
		IF NOT EXISTS (SELECT * FROM #sequence WHERE [type] = 'L')
		BEGIN
			SET @pRet = 7;
			GOTO EndSection;
		END
	END



	-- D. Create a recovery backup
	DECLARE @recovery_ret Int,
		@recovery_id Int

	SET @sql = N'
	USE ' + @db + '
	EXEC [dbo].[asFullBackup] @pIs_recovery = 1, @pRet = @recovery_ret OUTPUT, @pRecovery_id = @recovery_id OUTPUT
	';
	SET @paramDefinition = N'
		@recovery_ret Int OUTPUT, 
		@recovery_id Int OUTPUT
	';
	EXEC sp_executesql 
			@sql,
			@paramDefinition,
			@recovery_ret = @recovery_ret OUTPUT,
			@recovery_id = @recovery_id OUTPUT
	IF @recovery_ret <> 0 OR ISNULL(@recovery_id, 0) = 0
	BEGIN
		SET @pRet = 8;
		GOTO EndSection;
	END



	-- E. Restore backup in sequences (restoration process perfomed sequentially from full to differential to log backup)
	-- If failed, it will be restore back to last recovery backup
	BEGIN TRY
		DECLARE @cLocation Nvarchar(255),
			@cType Nvarchar(1),
			@cFinal Bit
		DECLARE csSequence CURSOR LOCAL FAST_FORWARD FOR 
			SELECT [location], [type], final FROM #sequence ORDER BY [order] ASC, stt ASC

		OPEN csSequence
		FETCH NEXT FROM csSequence INTO @cLocation, @cType, @cFinal

		WHILE @@FETCH_STATUS = 0
		BEGIN
			RESTORE DATABASE [AdventureWorks2025] FROM DISK = 'D:\Projects\SQL-Projects\Backup\Differential\AdventureWorks2025_DifferentialBackup_3.bak' WITH REPLACE, RECOVERY

			-- Use NORECOVERY when restoring a sequence of backups to persist in "restoring" state, final backup is defined with RECOVERY (to bring db back to online for using)
			--IF @cType = 'D' SET @sql = 'USE [master]; RESTORE DATABASE @db FROM DISK = ''' + @cLocation + '''';
			--ELSE IF @cType = 'I' SET @sql = 'USE [master]; RESTORE DATABASE @db FROM DISK = ''' + @cLocation + '''';
			--ELSE IF @cType = 'L' SET @sql = 'USE [master]; RESTORE LOG @db FROM DISK = ''' + @cLocation + '''';

			--IF @cFinal = 1 SET @sql = @sql + ' WITH REPLACE, RECOVERY';
			--ELSE SET @sql = @sql + ' WITH REPLACE, NORECOVERY';

			--SET @paramDefinition = N'@db Nvarchar(128)'
			--EXEC sp_executesql 
			--	@sql,
			--	@paramDefinition,
			--	@db = @db

			FETCH NEXT FROM csSequence INTO @cLocation, @cType, @cFinal
		END

		CLOSE csSequence
		DEALLOCATE csSequence
	END TRY
	BEGIN CATCH
		-- Roll back to recovery backup
		DECLARE @recovery_path Nvarchar(255);

		SET @sql = N'
		USE ' + @db + '
		SELECT TOP 1 @recovery_path = [location]
		FROM [dbo].[sysBackupHistory] 
		WHERE id = @recovery_id
		'
		SET @paramDefinition = N'
			@recovery_path Nvarchar(255) OUTPUT, 
			@recovery_id Int
		';
		EXEC sp_executesql 
				@sql,
				@paramDefinition,
				@recovery_path = @recovery_path OUTPUT,
				@recovery_id = @recovery_id

		SET @sql = 'USE [master]; RESTORE DATABASE @db FROM DISK = @backup_path WITH REPLACE, RECOVERY';
		SET @paramDefinition = N'@db Nvarchar(128), @backup_path Nvarchar(512)';
		EXEC sp_executesql 
				@sql,
				@paramDefinition,
				@db = @db,
				@backup_path = @recovery_path

		SET @pRet = 9;
	END CATCH


	EndSection:

	-- F. Done
	IF OBJECT_ID('tempdb..#recovery') IS NOT NULL 
		DROP TABLE #recovery;
	IF OBJECT_ID('tempdb..#backup_list') IS NOT NULL 
		DROP TABLE #backup_list;
	IF OBJECT_ID('tempdb..#sequence') IS NOT NULL 
		DROP TABLE #sequence;

	SET @sql = 'USE [master]; ALTER DATABASE ' + @db + ' SET MULTI_USER;'
	EXEC(@sql)

	IF @pRet = 0 SET @pRet = @@ERROR;

	SET NOCOUNT OFF;