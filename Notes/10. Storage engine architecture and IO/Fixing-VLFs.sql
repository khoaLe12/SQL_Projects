
-- Author: microsoft/tigertoolbox
-- Source: https://github.com/Microsoft/tigertoolbox/tree/master/Fixing-VLFs

-- Generate the sql statements to preemptively fix VLF issues in all DBs within the server, based on the transaction log current size.

SET NOCOUNT ON;

DECLARE @query Varchar(1000), @dbname Varchar(255), @count Int, @usedlogsize Bigint, @logsize Bigint
DECLARE @sqlcmd Nvarchar(1000), @sqlparam Nvarchar(100), @filename Varchar(255), @i Int, @recmodel Nvarchar(128)
DECLARE @potsize Int, @n_iter Int, @n_iter_final Int, @initgrow Int, @n_init_iter Int, @bckpath Nvarchar(255)
DECLARE @majorver Smallint, @minorver Smallint, @build Smallint

CREATE TABLE #loginfo (dbname Varchar(100), num_of_rows Int, used_logsize_MB Decimal(20, 1))

DECLARE @tblvlf TABLE (
	dbname Varchar(100),
	Actual_log_size_MB Decimal(20, 1),
	Potential_log_size_MB Decimal(20, 1),
	Actual_VLFs Int,
	Potential_VLFs Int,
	Growth_iterations Int,
	Log_Initial_size_MB Decimal(20, 1),
	File_autogrow_MB Decimal(20, 1)
)


-- Get backup's folder path of each database
SELECT TOP 1 @bckpath = 
	REVERSE(RIGHT(REVERSE(physical_device_name), LEN(physical_device_name)-CHARINDEX('\', REVERSE(physical_device_name), 0))) 
	FROM msdb.dbo.backupmediafamily WHERE device_type = 2


-- Extract major, minor version and build infor
SELECT @majorver = (@@microsoftversion / 0x1000000) & 0xff, @minorver = (@@microsoftversion / 0x10000) & 0xff, @build = @@microsoftversion & 0xffff


-- Iterate through databases to retrieve each database LVFs information
--DECLARE csr CURSOR FAST_FORWARD FOR SELECT name FROM master..sysdatabases WHERE dbid > 4 AND DATABASEPROPERTYEX(name,'status') = 'ONLINE' AND DATABASEPROPERTYEX(name,'Updateability') = 'READ_WRITE' AND name <> 'tempdb' AND name <> 'ReportServerTempDB'
DECLARE csr CURSOR FAST_FORWARD FOR SELECT name FROM master.sys.databases WHERE is_read_only = 0 AND state = 0 AND database_id <> 2;
OPEN csr
FETCH NEXT FROM csr INTO @dbname
WHILE (@@FETCH_STATUS <> -1)
BEGIN
	CREATE TABLE #log_info (recoveryunitid int NULL,
	fileid tinyint,
	file_size bigint,
	start_offset bigint,
	FSeqNo int,
	[status] tinyint,
	parity tinyint,
	create_lsn numeric(25,0))

	SET @query = 'DBCC LOGINFO (' + '''' + @dbname + ''') WITH NO_INFOMSGS'
	IF @majorver < 11
	BEGIN
		INSERT INTO #log_info (fileid, file_size, start_offset, FSeqNo, [status], parity, create_lsn)
		EXEC (@query)
	END
	ELSE
	BEGIN
		INSERT INTO #log_info (recoveryunitid, fileid, file_size, start_offset, FSeqNo, [status], parity, create_lsn)
		EXEC (@query)
	END

	-- Calculate count and total size of VLFs for each database
	SET @count = @@ROWCOUNT
	SET @usedlogsize = (SELECT (MIN(l.start_offset) + SUM(CASE WHEN l.status <> 0 THEN l.file_size ELSE 0 END))/1024.00/1024.00 FROM #log_info l)
	DROP TABLE #log_info;
	INSERT #loginfo
	VALUES(@dbname, @count, @usedlogsize);
	FETCH NEXT FROM csr INTO @dbname
END
CLOSE csr
DEALLOCATE csr


PRINT '/* Generated on ' + CONVERT (VARCHAR, GETDATE()) + ' in ' + @@SERVERNAME + ' */' + CHAR(10)


-- Iterate through each database to get its log files information (a db can have one or more log files)
DECLARE cshrk CURSOR FAST_FORWARD FOR SELECT dbname, num_of_rows FROM #loginfo 
WHERE num_of_rows >= 50 --My rule of thumb is 50 VLFs. Your mileage may vary.
ORDER BY dbname
OPEN cshrk
FETCH NEXT FROM cshrk INTO @dbname, @count
WHILE (@@FETCH_STATUS <> -1)
BEGIN

	-- Query [db_name].dbo.sysfiles (64 & status = 64) to get name and size (number of pages) of log files of each database
	SET @sqlcmd = 'SELECT @nameout = name, @logsizeout = (CAST(size AS BIGINT)*8)/1024 FROM [' + @dbname + '].dbo.sysfiles WHERE (64 & status) = 64'
	SET @sqlparam = '@nameout NVARCHAR(100) OUTPUT, @logsizeout bigint OUTPUT'
	EXEC sp_executesql @sqlcmd, @sqlparam, @nameout = @filename OUTPUT, @logsizeout = @logsize OUTPUT;


	-- Try to shrink the log files to see if it works
	PRINT '---------------------------------------------------------------------------------------------------------- '
	PRINT CHAR(13) + 'USE ' + QUOTENAME(@dbname) + ';'
	PRINT 'DBCC SHRINKFILE (N''' + @filename + ''', 1, TRUNCATEONLY);'
	PRINT '--'
	PRINT '-- CHECK: if the tlog file has shrunk with the following query:'
	PRINT 'SELECT name, (size*8)/1024 AS log_MB FROM [' + @dbname + '].dbo.sysfiles WHERE (64 & status) = 64'
	PRINT '--'

	-- If not, try this approach for SIMPLE recovery model and other models
	SET @recmodel = CONVERT(NVARCHAR, DATABASEPROPERTYEX(@dbname,'Recovery'))
	IF @recmodel <> 'SIMPLE' 
		AND SERVERPROPERTY('EngineEdition') <> 8 -- This cannot be applied on Managed Instance
	BEGIN
		PRINT '-- If the log has not shrunk, you must backup the transaction log next.'
		PRINT '-- Repeat the backup and shrink process alternatively until you get the desired log size (about 1MB).'
		PRINT '--'
		PRINT '-- METHOD: Backup -> Shrink (repeat the backup and shrink process until the log has shrunk):'
		PRINT '--'
		PRINT '-- Create example logical backup device.' 
		PRINT 'USE master;' + CHAR(13) + 'EXEC sp_addumpdevice ''disk'', ''BckLog'', ''' + @bckpath + '\example_bck.trn'';'
		PRINT 'USE ' + QUOTENAME(@dbname) + ';'
		PRINT '-- Backup Log'
		PRINT 'BACKUP LOG ' + QUOTENAME(@dbname) + ' TO BckLog;'
		PRINT '-- Shrink'
		PRINT 'DBCC SHRINKFILE (N''' + @filename + ''', 1);'
		PRINT '--'
		PRINT '-- METHOD: Alter recovery model -> Shrink:'
		PRINT '-- NOTE: Because the database is in ' + @recmodel + ' recovery model, one alternative is to set it to SIMPLE to truncate the log, shrink it, and reset it to ' + @recmodel + '.'
		PRINT '-- NOTE2: This method of setting the recovery model to SIMPLE and back again WILL BREAK log chaining, and thus any log shipping or mirroring.'
		PRINT 'USE [master]; ' + CHAR(13) + 'ALTER DATABASE ' + QUOTENAME(@dbname) + ' SET RECOVERY SIMPLE;'
		PRINT 'USE ' + QUOTENAME(@dbname) + ';' + CHAR(13) + 'DBCC SHRINKFILE (N''' + @filename + ''', 1);'
		PRINT 'USE [master]; ' + CHAR(13) + 'ALTER DATABASE ' + QUOTENAME(@dbname) + ' SET RECOVERY ' + @recmodel + ';'
		PRINT '--'
		PRINT '-- CHECK: if the tlog file has shrunk with the following query:'
		PRINT 'SELECT name, (size*8)/1024 AS log_MB FROM [' + @dbname + '].dbo.sysfiles WHERE (64 & status) = 64'
	END
	ELSE 
	BEGIN
		PRINT '-- If not, then proceed to the next step (it may be necessary to execute multiple times):'
		PRINT 'DBCC SHRINKFILE (N''' + @filename + ''', 1);'
		PRINT '-- CHECK: if the tlog file has shrunk with the following query:'
		PRINT 'SELECT name, (size*8)/1024 AS log_MB FROM [' + @dbname + '].dbo.sysfiles WHERE (64 & status) = 64'
	END


	-- ==================================================================
	-- ESTIMATE POTENTIAL LOG SIZE AND INITIAL SIZE
	-- ==================================================================

	-- We are growing in MB instead of GB because of known issue prior to SQL 2012.
	IF @majorver >= 11
	BEGIN
		SET @n_iter = (
			SELECT CASE 
				WHEN @logsize <= 64 THEN 1
				WHEN @logsize > 64 AND @logsize < 256 THEN ROUND(CONVERT(FLOAT, ROUND(@logsize, -2))/256, 0)
				WHEN @logsize >= 256 AND @logsize < 1024 THEN ROUND(CONVERT(FLOAT, ROUND(@logsize, -2))/512, 0)
				WHEN @logsize >= 1024 AND @logsize < 4096 THEN ROUND(CONVERT(FLOAT, ROUND(@logsize, -2))/1024, 0)
				WHEN @logsize >= 4096 AND @logsize < 8192 THEN ROUND(CONVERT(FLOAT, ROUND(@logsize, -2))/2048, 0)
				WHEN @logsize >= 8192 AND @logsize < 16384 THEN ROUND(CONVERT(FLOAT, ROUND(@logsize, -2))/4096, 0)
				WHEN @logsize >= 16384 THEN ROUND(CONVERT(FLOAT, ROUND(@logsize, -2))/8192, 0)
			END
		)
		SET @potsize = (
			SELECT CASE 
				WHEN @logsize <= 64 THEN 1*64
				WHEN @logsize > 64 AND @logsize < 256 THEN ROUND(CONVERT(FLOAT, ROUND(@logsize, -2))/256, 0)*256
				WHEN @logsize >= 256 AND @logsize < 1024 THEN ROUND(CONVERT(FLOAT, ROUND(@logsize, -2))/512, 0)*512
				WHEN @logsize >= 1024 AND @logsize < 4096 THEN ROUND(CONVERT(FLOAT, ROUND(@logsize, -2))/1024, 0)*1024
				WHEN @logsize >= 4096 AND @logsize < 8192 THEN ROUND(CONVERT(FLOAT, ROUND(@logsize, -2))/2048, 0)*2048
				WHEN @logsize >= 8192 AND @logsize < 16384 THEN ROUND(CONVERT(FLOAT, ROUND(@logsize, -2))/4096, 0)*4096
				WHEN @logsize >= 16384 THEN ROUND(CONVERT(FLOAT, ROUND(@logsize, -2))/8192, 0)*8192
			END
		)
	END
	ELSE
	BEGIN
		SET @n_iter = (
			SELECT CASE 
				WHEN @logsize <= 64 THEN 1
				WHEN @logsize > 64 AND @logsize < 256 THEN ROUND(CONVERT(FLOAT, ROUND(@logsize, -2))/256, 0)
				WHEN @logsize >= 256 AND @logsize < 1024 THEN ROUND(CONVERT(FLOAT, ROUND(@logsize, -2))/512, 0)
				WHEN @logsize >= 1024 AND @logsize < 4096 THEN ROUND(CONVERT(FLOAT, ROUND(@logsize, -2))/1024, 0)
				WHEN @logsize >= 4096 AND @logsize < 8192 THEN ROUND(CONVERT(FLOAT, ROUND(@logsize, -2))/2048, 0)
				WHEN @logsize >= 8192 AND @logsize < 16384 THEN ROUND(CONVERT(FLOAT, ROUND(@logsize, -2))/4000, 0)
				WHEN @logsize >= 16384 THEN ROUND(CONVERT(FLOAT, ROUND(@logsize, -2))/8000, 0)
			END
		)
		SET @potsize = (
			SELECT CASE 
				WHEN @logsize <= 64 THEN 1*64
				WHEN @logsize > 64 AND @logsize < 256 THEN ROUND(CONVERT(FLOAT, ROUND(@logsize, -2))/256, 0)*256
				WHEN @logsize >= 256 AND @logsize < 1024 THEN ROUND(CONVERT(FLOAT, ROUND(@logsize, -2))/512, 0)*512
				WHEN @logsize >= 1024 AND @logsize < 4096 THEN ROUND(CONVERT(FLOAT, ROUND(@logsize, -2))/1024, 0)*1024
				WHEN @logsize >= 4096 AND @logsize < 8192 THEN ROUND(CONVERT(FLOAT, ROUND(@logsize, -2))/2048, 0)*2048
				WHEN @logsize >= 8192 AND @logsize < 16384 THEN ROUND(CONVERT(FLOAT, ROUND(@logsize, -2))/4000, 0)*4000
				WHEN @logsize >= 16384 THEN ROUND(CONVERT(FLOAT, ROUND(@logsize, -2))/8000, 0)*8000
			END
		)
	END

	-- If the proposed log size is smaller than current log, and also smaller than 4GB,
	-- and there is less than 512MB of diff between the current size and proposed size, add 1 grow.
	SET @n_iter_final = @n_iter
	IF @logsize > @potsize AND @potsize <= 4096 AND ABS(@logsize - @potsize) < 512
	BEGIN
		SET @n_iter_final = @n_iter + 1
	END

	-- If the proposed log size is larger than current log, and also larger than 50GB, 
	-- and there is less than 1GB of diff between the current size and proposed size, take 1 grow.
	ELSE IF @logsize < @potsize AND @potsize <= 51200 AND ABS(@logsize - @potsize) < 1024
	BEGIN
		SET @n_iter_final = @n_iter - 1
	END

	IF @potsize = 0 
	BEGIN 
		SET @potsize = 64 
	END
	IF @n_iter = 0 
	BEGIN 
		SET @n_iter = 1
	END

	SET @potsize = (
		SELECT CASE 
			WHEN @n_iter < @n_iter_final THEN @potsize + (@potsize/@n_iter) 
			WHEN @n_iter > @n_iter_final THEN @potsize - (@potsize/@n_iter) 
			ELSE @potsize 
		END
	)

	SET @n_init_iter = @n_iter_final
	IF @potsize >= 8192
	BEGIN
		SET @initgrow = @potsize/@n_iter_final
	END
	ELSE IF @potsize >= 64 AND @potsize <= 512
	BEGIN
		SET @n_init_iter = 1
		SET @initgrow = 512
	END
	ELSE IF @potsize > 512 AND @potsize <= 1024
	BEGIN
		SET @n_init_iter = 1
		SET @initgrow = 1023
	END
	ELSE IF @potsize > 1024 AND @potsize < 8192
	BEGIN
		SET @n_init_iter = 1
		SET @initgrow = @potsize
	END

	INSERT INTO @tblvlf (
		dbname,
		Actual_log_size_MB,
		Potential_log_size_MB,
		Actual_VLFs,
		Potential_VLFs,
		Growth_iterations,
		Log_Initial_size_MB,
		File_autogrow_MB
	)
	SELECT 
		@dbname, 
		@logsize, 
		@potsize, 
		@count, 
		CASE 
			WHEN @potsize <= 64 THEN (@potsize/(@potsize/@n_init_iter))*4
			WHEN @potsize > 64 AND @potsize < 1024 THEN (@potsize/(@potsize/@n_init_iter))*8
			WHEN @potsize >= 1024 THEN (@potsize/(@potsize/@n_init_iter))*16
		END, 
		@n_init_iter,
		@initgrow, 
		CASE 
			WHEN (@potsize/@n_iter_final) <= 1024 THEN (@potsize/@n_iter_final) 
			ELSE 1024 
		END

		SET @i = 0
		WHILE @i <= @n_init_iter
		BEGIN
			IF @i = 1
			BEGIN
				-- Log Autogrow should not be above 1GB
				PRINT CHAR(13) + '-- Now for the log file growth:'
				PRINT 'ALTER DATABASE [' + @dbname + '] MODIFY FILE ( NAME = N''' + @filename + ''', SIZE = ' + CONVERT(VARCHAR, @initgrow) + 'MB , FILEGROWTH = ' + CASE WHEN (@potsize/@n_iter_final) <= 1024 THEN CONVERT(VARCHAR, (@potsize/@n_iter_final)) ELSE '1024' END + 'MB );'
			END
			IF @i > 1
			BEGIN
				PRINT 'ALTER DATABASE [' + @dbname + '] MODIFY FILE ( NAME = N''' + @filename + ''', SIZE = ' + CONVERT(VARCHAR, @initgrow*@i)+ 'MB );'
			END		
			SET @i = @i + 1
			CONTINUE
		END
		FETCH NEXT FROM cshrk INTO @dbname, @count
END

CLOSE cshrk
DEALLOCATE cshrk;

DROP TABLE #loginfo;

SELECT dbname AS [Database_Name], Actual_log_size_MB, Potential_log_size_MB, Actual_VLFs, 
	Potential_VLFs, Growth_iterations, Log_Initial_size_MB, File_autogrow_MB
FROM @tblvlf;
GO