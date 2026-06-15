CREATE OR ALTER PROCEDURE [dbo].[asRestoreBackup]
	@pId Int,
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
		@db Nvarchar(128) = QUOTENAME(DB_NAME()),
		@paramDefinition Nvarchar(MAX);



	-- Prepaing database for restoring
	SET @sql = 'USE [master]; ALTER DATABASE ' + @db + ' SET SINGLE_USER WITH ROLLBACK IMMEDIATE; CHECKPOINT;'
	EXEC(@sql)



	SELECT TOP 1
		@ref_backup_id = ref_backup_id,
		@backup_id = id,
		@type = [type],
		@status = [status],
		@stt = stt,
		@level = [level]
	FROM [dbo].[sysBackupHistory]
	WHERE id = @pId



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

	SELECT TOP 1 
		@last_full_backup = id
	FROM [dbo].[sysBackupHistory]
	WHERE [type] = 'D'
		AND [status] = '1'
		AND recovery_backup = 0
	ORDER BY [timestamp] DESC

	SELECT TOP 1
		@ref_full_backup = id
	FROM [dbo].[sysBackupHistory]
	WHERE group_level = 1
		AND [level] = @level.GetAncestor(
			CASE @type
				WHEN 'D' THEN 0
				WHEN 'I' THEN 1
				WHEN 'L' THEN 2
			END
		)

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
		INSERT INTO #backup_list([level])
		SELECT [level]
		FROM [dbo].[sysBackupHistory]
		WHERE group_level = 3 AND [level].IsDescendantOf(@level.GetAncestor(1)) = 1
	END

	-- 3. Build sequences
	INSERT INTO #sequence ([order], stt, [location], [type], final)
	SELECT group_level, stt, [location], [type], CASE id WHEN @backup_id THEN 1 ELSE 0 END
	FROM [dbo].[sysBackupHistory]
	WHERE [level] IN (SELECT [level] FROM #backup_list)
		AND [status] = '1'
		AND stt < @stt

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

	IF OBJECT_ID('tempdb..#recovery') IS NOT NULL 
		DROP TABLE #recovery;
	CREATE TABLE #recovery(id Int);

	INSERT INTO #recovery(id)
	EXEC [dbo].[asFullBackup] 1, @recovery_ret

	SELECT TOP 1 @recovery_id = id FROM #recovery

	IF @recovery_ret <> 0 OR ISNULL(@recovery_id, 0) = 0 OR NOT EXISTS (SELECT * FROM [dbo].[sysBackupHistory] WHERE id = @recovery_id AND [status] = '1')
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
			-- Use NORECOVERY when restoring a sequence of backups to persist in "restoring" state, final backup is defined with RECOVERY (to bring db back to online for using)
			IF @cType = 'D' SET @sql = 'USE [master]; RESTORE DATABASE @db FROM DISK = ''@backup_path''';
			ELSE IF @cType = 'I' SET @sql = 'USE [master]; RESTORE DATABASE @db FROM DISK = ''@backup_path''';
			ELSE IF @cType = 'L' SET @sql = 'USE [master]; RESTORE LOG @db FROM DISK = ''@backup_path''';

			IF @cFinal = 1 SET @sql = @sql + ' WITH RECOVERY';
			ELSE SET @sql = @sql + '  WITH NORECOVERY';
		
			SET @paramDefinition = N'@db Nvarchar(128), @backup_path Nvarchar(512)'
			EXEC sp_executesql 
				@sql,
				@paramDefinition,
				@db = @db,
				@backup_path = @cLocation

			FETCH NEXT FROM csSequence INTO @cLocation, @cType, @cFinal
		END

		CLOSE csSequence
		DEALLOCATE csSequence
	END TRY
	BEGIN CATCH
		-- Roll back to recovery backup
		SET @pRet = @@ERROR;

		DECLARE @recovery_path Nvarchar(255) = (
			SELECT TOP 1 [location]
			FROM [dbo].[sysBackupHistory] 
			WHERE id = @recovery_id
		)

		SET @sql = 'USE [master]; RESTORE DATABASE @db FROM DISK = ''@backup_path'' WITH RECOVERY';
		SET @paramDefinition = N'@db Nvarchar(128), @backup_path Nvarchar(512)';
		EXEC sp_executesql 
				@sql,
				@paramDefinition,
				@db = @db,
				@backup_path = @recovery_path
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

	SET NOCOUNT OFF;