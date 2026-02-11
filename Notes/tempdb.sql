



-- During a new SQL Server instance installation, by default SQL Setup adds as many tempdb data files as the number of logical processors or eight





-- OPTIMIZE TEMPDB PERFORMANCE IN SQL SERVER
-- B1: Check current size and growth parameters for tempdb's data files
SELECT 
	name AS file_name,
	type_desc AS file_type,
	size * 8.0 / 1024 AS size_mb,
	max_size,
	max_size * 8.0 / 1024 AS max_size_mb,
	CAST (IIF(growth = 0, 0, 1) AS BIT) AS is_autogrowth_enabled,
	CASE
		WHEN growth = 0 THEN growth
		WHEN growth > 0 AND is_percent_growth = 0 THEN growth * 8.0 / 1024
		WHEN growth > 0 AND is_percent_growth = 1 THEN growth
	END AS growth_increment_value,
	CASE
		WHEN growth = 0 THEN N'Autogrowth is disabled.'
		WHEN growth > 0 AND is_percent_growth = 0 THEN 'Megabytes'
		WHEN growth > 0 AND is_percent_growth = 1 THEN 'Percent'
	END AS growth_increment_value_unit
FROM tempdb.sys.database_files;


-- B2: Monitor tempdb usage
-- Ex1: Run this query to identify the appropriate initial size or growth of data files
SELECT 
	SUM(unallocated_extent_page_count) * 8.0 / 1024 AS tempdb_free_data_space_mb,
	SUM(version_store_reserved_page_count) * 8.0 / 1024 AS tempdb_version_store_space_mb,
	SUM(internal_object_reserved_page_count) * 8.0 / 1024 AS tempdb_internal_object_space_mb,
	SUM(user_object_reserved_page_count) * 8.0 / 1024 AS tempdb_user_object_space_mb
FROM tempdb.sys.dm_db_file_space_usage
-- Ex2: Monitor the space usage of #temp in a session to check whether if the query/procedure of that session overuse tempdb or not
-- get allocation and deallocation before
SELECT
    user_objects_alloc_page_count + internal_objects_alloc_page_count AS allocation_before,
    user_objects_dealloc_page_count + internal_objects_dealloc_page_count AS deallocation_before
FROM sys.dm_db_session_space_usage
WHERE session_id = @@SPID
GO
-- some kind of expensive tempdb usage
IF OBJECT_ID('tempdb..#temp') IS NOT NULL
	DROP TABLE #temp;
WITH CTE_Recursive AS (
	SELECT 
		'Val12222222222222' AS val1,
		'Val23333333333333' AS val2,
		'Val3444444444444444' AS val3,
		1 AS [iteration]
	UNION ALL
	SELECT 
		val1,
		val2,
		val3,
		[iteration] + 1
 	FROM CTE_Recursive
	WHERE [iteration] < 1000
)
SELECT *
INTO #temp
FROM CTE_Recursive
OPTION (MAXRECURSION 1000);
IF OBJECT_ID('tempdb..#temp') IS NOT NULL
	DROP TABLE #temp
GO
-- get allocation and deallocation after
SELECT
    user_objects_alloc_page_count + internal_objects_alloc_page_count AS allocation_after,
    user_objects_dealloc_page_count + internal_objects_dealloc_page_count AS deallocation_after
FROM sys.dm_db_session_space_usage
WHERE session_id = @@SPID
GO
-- Ex3: check the tempdb space allocated and deallocated by internal objects in each session (provide the view of current traffic)
SELECT 
	session_id,
	SUM(internal_objects_alloc_page_count) AS task_internal_objects_alloc_page_count,
    SUM(internal_objects_dealloc_page_count) AS task_internal_objects_dealloc_page_count
FROM sys.dm_db_task_space_usage
GROUP BY session_id;
-- Ex4: check the tempdb usage by internal and user objects for each sessiona and request
; WITH tempdb_space_usage
AS (
	SELECT 
		session_id,
		request_id,
		user_objects_alloc_page_count + internal_objects_alloc_page_count AS tempdb_allocations_page_count,
		user_objects_alloc_page_count + internal_objects_alloc_page_count - user_objects_dealloc_page_count - internal_objects_dealloc_page_count AS tempdb_current_page_count
	FROM sys.dm_db_task_space_usage
	UNION ALL
	SELECT
		session_id,
		NULL AS request_id,
		user_objects_alloc_page_count + internal_objects_alloc_page_count AS tempdb_allocations_page_count,
		user_objects_alloc_page_count + internal_objects_alloc_page_count - user_objects_dealloc_page_count - user_objects_deferred_dealloc_page_count - internal_objects_dealloc_page_count AS tempdb_current_page_count
	FROM sys.dm_db_session_space_usage
)
SELECT 
	session_id,
	COALESCE(request_id, 0) AS request_id,
	SUM(tempdb_allocations_page_count * 8) AS tempdb_allocations_kb,
	SUM(IIF (tempdb_current_page_count >= 0, tempdb_current_page_count, 0) * 8) AS tempdb_current_kb
FROM tempdb_space_usage
GROUP BY session_id, COALESCE(request_id, 0)
ORDER BY session_id, request_id;


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