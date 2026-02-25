

-- TEMPDB SYSTEM DATABASE
-- 1. Purpose:
--	Tempdb is a shared global resource used to store temporary data, including:
--		+ User objects: temporary tables and indexes, temporary stored procedures, large variables, table variables, results of table-valued functions, cursors.
--		+ Internal objects: work tables for spool operations, hash join/hash aggregation work files, intermediate sort results for GROUP BY, ORDER BY, UNION queries, and index build/maintenance operations (e.g., SORT_IN_TEMPDB).
--		+ Version stores: row versions generated during data modification when using row versioning-based isolation levels (e.g., READ COMMITTED SNAPSHOT or SNAPSHOT).
-- 2. File structure:
--	Tempdb consists of:
--		+ Primary data file: tempdev (tempdb.mdf).
--		+ Secondary data files: tempdb_mssql_#.ndf (temp1, temp2, etc.).
--		+ Log file: templog (templog.ldf).
--	By default, SQL Server creates tempdb with a single data file.
-- 3. File contents:
--	Each data file contains metadata pages and data pages.
--	Metadata tracks allocation and usage of space/pages.
-- 4. Concurrency:
--	Tempdb uses latch queues on each data file to serialize concurrent access.
--	Excessive contention on these latches leads to "tempdb allocation contention" or "page latch waits".
-- 5. Detection:
--	Use DMVs such as sys.dm_os_waiting_tasks and sys.dm_os_wait_stats to identify waiting threads and reasons.
--	DBCC SQLPERF can reset wait statistics for monitoring.
-- 6. Mitigation strategies:
--		+ Add multiple files to increase the number of latch queues.
--			- Recommended: start with one file per logical processor up to 8, then add more only if necessary.
--			- Caution: too many files can add overhead.
--		+ Preallocate data files to their expected maximum size, or configure larger growth increments.
--			- Ensure all files have the same initial size and growth settings.
--		+ Enable "Instant File Initialization" to skip zeroing out new allocations.
--			- Caution: may expose residual data; use with care.
--		+ Enable "memory-optimized tempdb metadata" (SQL Server 2019+).
--			- Caution: increase memory usage.
--		+ Use table variables instead of temp table where appropriate (to avoid writing to metadata files), or optimze queries to reduce tempdb usage.
--		+ Place tempdb on seperate physical storage from other system databases to reduce I/O contention.





-- TEMPDB PRACTICE
-- CHECK CURRENT SIZE AND GROWTH VALUE OF TEMPDB DATA FILES
SELECT 
	name AS [file name],
	type_desc AS [file type],
	ISNULL(RTRIM(CAST(size * 8.0 / 1024 AS CHAR)) + ' MB', '') AS [size],
	CASE max_size
		WHEN -1 THEN 'Unlimited'
		ELSE ISNULL(RTRIM(CAST(max_size * 8.0 / 1024 AS CHAR)) + ' MB', '')
	END AS [max size],
	IIF(growth = 0, 'False', 'True') AS [is auto growth],
	CASE
		WHEN growth = 0 THEN '0 MB'
		WHEN growth > 0 AND is_percent_growth = 0 THEN ISNULL(RTRIM(CAST(growth * 8.0 / 1024 AS CHAR)) + ' MB', '')
		WHEN growth > 0 AND is_percent_growth = 1 THEN ISNULL(RTRIM(CAST(growth AS CHAR)) + '%', '')
	END AS [growth value]
FROM tempdb.sys.database_files
GO;


-- MONIOR TEMPDB FILE SPACE USAGE
SELECT 
	ISNULL(RTRIM(CAST(SUM(total_page_count) * 8.0 / 1024 AS CHAR)) + ' MB', '') AS [reserved space],
	ISNULL(RTRIM(CAST(SUM(allocated_extent_page_count) * 8.0 / 1024 AS CHAR)) + ' MB', '') AS [allocated space],
	ISNULL(RTRIM(CAST(SUM(unallocated_extent_page_count) * 8.0 / 1024 AS CHAR)) + ' MB', '') AS [unallocated space],
	ISNULL(RTRIM(CAST(SUM(version_store_reserved_page_count) * 8.0 / 1024 AS CHAR)) + ' MB', '') AS [version store used],
	ISNULL(RTRIM(CAST(SUM(internal_object_reserved_page_count) * 8.0 / 1024 AS CHAR)) + ' MB', '') AS [internal object used],
	ISNULL(RTRIM(CAST(SUM(user_object_reserved_page_count) * 8.0 / 1024 AS CHAR)) + ' MB', '') AS [user object used],
	ISNULL(RTRIM(CAST(SUM(mixed_extent_page_count) * 8.0 / 1024 AS CHAR)) + ' MB', '') AS [mixed extent used]
FROM tempdb.sys.dm_db_file_space_usage
GO;


-- MONITOR TEMPDB FILE SPACE USAGE OF SESSIONS/REQUESTS (WITH SOME DETAILS OF REQUEST)
SELECT 
	u.session_id,
	ISNULL(RTRIM(CAST(u.user_objects_alloc_page_count * 8.0 / 1024 AS CHAR)) + ' MB', '') AS [user objects allocation],
	ISNULL(RTRIM(CAST(u.user_objects_dealloc_page_count * 8.0 / 1024 AS CHAR)) + ' MB', '') AS [user objects deallocation],
	ISNULL(RTRIM(CAST(u.internal_objects_alloc_page_count * 8.0 / 1024 AS CHAR)) + ' MB', '') AS [internal objects allocation],
	ISNULL(RTRIM(CAST(u.internal_objects_dealloc_page_count * 8.0 / 1024 AS CHAR)) + ' MB', '') AS [internal objects deallocation],
	ISNULL(RTRIM(CAST(u.user_objects_deferred_dealloc_page_count * 8.0 / 1024 AS CHAR)) + ' MB', '') AS [user objects deferred deallocation],
	NULL AS [session infomration],
	s.host_name AS [host name],
	s.host_process_id AS [process id],
	CASE s.is_user_process 
		WHEN 0 THEN 'False'
		WHEN 1 THEN 'True'
		ELSE ''
	END AS [user process],
	s.login_time AS [login time],
	s.login_name AS [login name],
	s.original_login_name AS [origin name],
	s.status AS [status],
	ISNULL(FORMAT(s.last_request_end_time, 'dd-MM-yyyy HH:mm:ss'), 'Undefined') + ' - ' + ISNULL(FORMAT(s.last_request_end_time, 'dd-MM-yyyy HH:mm:ss'), 'Current') AS [last request],
	s.open_transaction_count AS [open transaction count]
FROM sys.dm_db_session_space_usage u
LEFT JOIN sys.dm_exec_sessions s ON s.session_id = u.session_id
GO
;
SELECT 
	u.session_id,
	u.request_id,
	ISNULL(RTRIM(CAST(u.user_objects_alloc_page_count * 8.0 / 1024 AS CHAR)) + ' MB', '') AS [user objects allocation],
	ISNULL(RTRIM(CAST(u.user_objects_dealloc_page_count * 8.0 / 1024 AS CHAR)) + ' MB', '') AS [user objects deallocation],
	ISNULL(RTRIM(CAST(u.internal_objects_alloc_page_count * 8.0 / 1024 AS CHAR)) + ' MB', '') AS [internal objects allocation],
	ISNULL(RTRIM(CAST(u.internal_objects_dealloc_page_count * 8.0 / 1024 AS CHAR)) + ' MB', '') AS [internal objects deallocation],
	r.status AS [request status],
	(
		SELECT SUBSTRING(
			dest.text,
			(r.statement_start_offset / 2) + 1,  -- start index of sql text of current executing statement in a query
			((CASE r.statement_end_offset
				WHEN -1 THEN DATALENGTH(dest.text)
				ELSE r.statement_end_offset
			END - r.statement_start_offset) / 2) + 1
		)
		FOR XML PATH (''), TYPE
	) AS [sql text of a task in the request],
	(
		CASE 
			WHEN TRY_CAST(deqp.query_plan AS xml) IS NOT NULL 
				THEN TRY_CAST(deqp.query_plan AS xml)
			WHEN TRY_CAST(deqp.query_plan AS xml) IS NULL
				THEN (
					SELECT [processing-instruction(query_plan)] = 
						N'-- ' + NCHAR(13) + NCHAR(10) +
                        N'-- This is a huge query plan.' + NCHAR(13) + NCHAR(10) +
                        N'-- Remove the headers and footers, save it as a .sqlplan file, and re-open it.' + NCHAR(13) + NCHAR(10) +
						NCHAR(13) + NCHAR(10) +
						REPLACE(deqp.query_plan, N'<RelOp', NCHAR(13) + NCHAR(10) + N'<RelOp') +
						NCHAR(13) + NCHAR(10) COLLATE Latin1_General_Bin2
					FOR XML PATH(N''), TYPE
				)
		END
	) AS [query plan of a task in the request]
FROM sys.dm_db_task_space_usage u
LEFT JOIN sys.dm_exec_requests r ON r.session_id = u.session_id AND r.request_id = u.request_id
OUTER APPLY sys.dm_exec_sql_text(r.sql_handle) AS dest
OUTER APPLY sys.dm_exec_text_query_plan(r.plan_handle, r.statement_start_offset, r.statement_end_offset) AS deqp
GO


-- DETECT TEMPDB ALLOCATION CONTENTION
SELECT
	ws.session_id AS [session id],
	ws.wait_type AS [wait type],
	ws.waiting_tasks_count AS [waiting tasks count],
	ISNULL(RTRIM(CAST(ws.wait_time_ms / 1000.0 AS CHAR)) + 's', '') AS [wait time],
	ISNULL(RTRIM(CAST(ws.max_wait_time_ms / 1000.0 AS CHAR)) + 's', '') AS [max wait time],
	ISNULL(RTRIM(CAST(ws.signal_wait_time_ms / 1000.0 AS CHAR)) + 's', '') AS [signal wait time]
FROM sys.dm_exec_session_wait_stats ws
WHERE wait_type LIKE 'PAGELATCH%'
GO
;
SELECT 
	-- Task info
	wt.session_id AS [session id],
	r.request_id AS [request id],
	r.status AS [request status],
	(
		SELECT SUBSTRING(
			dest.text,
			(r.statement_start_offset / 2) + 1,  -- start index of sql text of current executing statement in a query
			((CASE r.statement_end_offset
				WHEN -1 THEN DATALENGTH(dest.text)
				ELSE r.statement_end_offset
			END - r.statement_start_offset) / 2) + 1
		)
		FOR XML PATH (''), TYPE
	) AS [sql text],
	ISNULL(r.parallel_worker_count, 0) AS [number of active parallel tasks],
	wt.waiting_task_address AS [task address],
	t.task_state AS [task status],
	wt.wait_type AS [wait type],
	ISNULL(RTRIM(CAST(wt.wait_duration_ms / 1000.0 AS CHAR)) + 's', '') AS [wait duration],
	wt.resource_description AS [resource description],
	t.task_local_storage AS [task local storage],

	-- Blocking request infor
	br.session_id AS [blocking session],
	br.request_id AS [blocking request],
	br.status AS [blocking request status],
	(
		SELECT SUBSTRING(
			dest_br.text,
			(br.statement_start_offset / 2) + 1,  -- start index of sql text of current executing statement in a query
			((CASE br.statement_end_offset
				WHEN -1 THEN DATALENGTH(dest_br.text)
				ELSE br.statement_end_offset
			END - br.statement_start_offset) / 2) + 1
		)
		FOR XML PATH (''), TYPE
	) AS [blocking request - sql text]
FROM sys.dm_os_waiting_tasks wt
INNER JOIN sys.dm_exec_sessions S ON s.session_id = wt.session_id AND s.is_user_process = 1
LEFT JOIN sys.dm_os_tasks t ON t.task_address = wt.waiting_task_address
LEFT JOIN sys.dm_exec_requests r On r.request_id = t.request_id AND r.session_id = t.session_id
OUTER APPLY sys.dm_exec_sql_text(r.sql_handle) AS dest
LEFT JOIN sys.dm_exec_requests br ON br.session_id = r.blocking_session_id
OUTER APPLY sys.dm_exec_sql_text(br.sql_handle) AS dest_br
WHERE wt.wait_type LIKE 'PAGELATCH%'
ORDER BY wt.session_id, t.request_id
GO



select CONVERT(xml, '<TASK_LOCAL_STORAGE><STORAGE_ENGINE><LATCH_TRACKING type="CountOnly"></LATCH class="BUFFER" count="1"></LATCH_TRACKING></STORAGE_ENGINE> </TASK_LOCAL_STORAGE>')



select 
	CONVERT(xml, dorb.record),
	dorb.record
FROM sys.dm_os_ring_buffers dorb



select * from sys.dm_exec_requests

select * FROM sys.dm_os_waiting_tasks wt

SELECT * FROM sys.dm_os_tasks order by session_id, request_id, task_address

select * from sys.dm_exec_sessions



-- B3: Add more tempdb data files (usually by the current numer of files multiply by 4) until the allocation contention decreases to acceptable levels
-- View all data files of tempdb
SELECT
	fg.name AS FilegroupName,
	mf.name AS LogicalFileName,
	mf.physical_name AS PhysicalFilePath,
	mf.size / 128 AS SizeInMB
FROM sys.filegroups fg
JOIN sys.master_files mf ON fg.data_space_id = mf.data_space_id
WHERE mf.database_id = DB_ID('tempdb');
-- Add 1 more data file
ALTER DATABASE tempdb ADD FILE
(
	NAME = temp5, -- Logical name
	FILENAME = 'C:\Program Files\Microsoft SQL Server\MSSQL14.MSSQL2017\MSSQL\DATA\tempdb_mssql_5.ndf'
) TO FILEGROUP [PRIMARY];



-- B4: Preallocate space for all tempdb files by setting the file size to a large value
ALTER DATABASE tempdb
MODIFY FILE (NAME = tempdev, SIZE = 128 MB);
ALTER DATABASE tempdb
MODIFY FILE (NAME = temp2, SIZE = 128 MB);
ALTER DATABASE tempdb
MODIFY FILE (NAME = temp3, SIZE = 128 MB);
ALTER DATABASE tempdb
MODIFY FILE (NAME = temp4, SIZE = 128 MB);
ALTER DATABASE tempdb
MODIFY FILE (NAME = temp5, SIZE = 128 MB);
-- To Decrease (shrink) the file size
DBCC SHRINKFILE (tempdev, 8);



-- B5: Check configuration
-- For SQL Server 2016 or later, keep the default behavior of tempdb
ALTER DATABASE tempdb SET MIXED_PAGE_ALLOCATION = OFF;
ALTER DATABASE YourDB SET AUTOGROW_ALL_FILES = ON;
-- For SQL Server 2014 or earlier, turn on TRACE FLAG 1117, 1118
DBCC TRACEON  (1117); DBCC TRACEON  (1118); -- This only turn on trace flags temporarily (search more for Enable permanently)



-- B6: If possible, use "instant file initialization" to improve performance of the growth operations for data files
-- This mechanism help to skip the process of zeroing the allocated memory 
-- This could make security risk since deleted area of files could be potentially accessible by an unauthorized principal
-- -> Make sure the "SE_MANAGE_VOLUME_NAME" privilege is granted to appropriate "Service SID" or "Database Engine service"
EXEC xp_cmdshell 'ntrights -u "sa" +r SeManageVolumePrivilege' -- This procedure run ntrights.exe to grant the privilege to account sa
-- Or follow the step of https://learn.microsoft.com/en-us/sql/relational-databases/databases/database-instant-file-initialization?view=sql-server-ver17#enable-instant-file-initialization



-- B7: Enabling Memory-optimized TempDB metadata (only available on Enterprise, Developer, or Evaluation edition)
-- This feature solves the problem of temporary object metedata contention inside tempdb
-- Or follow: https://www.microsoft.com/en-us/sql-server/blog/2022/07/21/improve-scalability-with-system-page-latch-concurrency-enhancements-in-sql-server-2022/
-- B7.1: Diagnostic query of temporary object metadata contention at executed time only (return the number of sessions contending for access to system table)
SELECT
	OBJECT_NAME(dpi.object_id, dpi.database_id) AS system_table_name,
	COUNT(DISTINCT (r.session_id)) AS session_count
FROM sys.dm_exec_requests AS r
CROSS APPLY sys.fn_PageResCracker(r.page_resource) AS prc
CROSS APPLY sys.dm_db_page_info(prc.db_id, prc.file_id, prc.page_id, 'LIMITED') AS dpi
WHERE dpi.database_id = 2 -- 0: resource, 1: master, 2: tempdb, 3: model, 4: msdb, 5+: user databases
	AND dpi.object_id IN (3, 9, 34, 40, 41, 54, 55, 60, 74, 75)
	AND UPPER(r.wait_type) LIKE N'PAGELATCH[_]%'
GROUP BY dpi.object_id, dpi.database_id
;
SELECT 
	er.session_id,
	er.wait_type,
	er.wait_resource,
	OBJECT_NAME(page_info.object_id, page_info.database_id) AS [object_name],
	er.blocking_session_id,
	er.command,
	SUBSTRING(st.text, (er.statement_start_offset/2) + 1, 
		((
			CASE er.statement_end_offset
				WHEN -1 THEN DATALENGTH(st.text)
				ELSE er.statement_end_offset
			END - er.statement_start_offset
		)/2) + 1) AS statement_text,
	page_info.database_id,
	page_info.file_id,
	page_info.page_id,
	page_info.object_id,
	page_info.index_id,
	page_info.page_type_desc
FROM sys.dm_exec_requests AS er
CROSS APPLY sys.dm_exec_sql_text(er.sql_handle) AS st
CROSS APPLY sys.fn_PageResCracker (er.page_resource) AS r
CROSS APPLY sys.dm_db_page_info(r.db_id, r.file_id, r.page_id, 'DETAILED') AS page_info
WHERE er.wait_type LIKE '%page%'
-- B7.2: Configure and use Memory-optimized TempDB metadata (if contentions are detected from above diagnostic query)
-- Enable/Disable Memory-optimized TempDB metadata
ALTER SERVER CONFIGURATION SET MEMORY_OPTIMIZED TEMPDB_METADATA = ON;
ALTER SERVER CONFIGURATION SET MEMORY_OPTIMIZED TEMPDB_METADATA = OFF;
-- Verify whether or not tempdb is memory-optimized
SELECT SERVERPROPERTY('IsTempdbMetadataMemoryOptimized');
-- Limit memory usage
CREATE RESOURCE POOL tempdb_resource_pool WITH (MAX_MEMORY_PERCENT = 20);
ALTER RESOURCE GOVERNOR RECONFIGURE;
ALTER SERVER CONFIGURATION SET MEMORY_OPTIMIZED TEMPDB_METADATA = ON (RESOURCE_POOL = 'tempdb_resource_pool')
-- Rmove memory usage limitation
ALTER SERVER CONFIGURATION SET MEMORY_OPTIMIZED TEMPDB_METADATA = ON;