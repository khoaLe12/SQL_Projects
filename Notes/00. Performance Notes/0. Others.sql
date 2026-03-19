-- EXPLORING THE DATABASES
USE AdventureWorks2025;
GO



-- List all databases of an instance
-- database_id: 1_master, 2_tempdb, 3_model, 4_msdb, 5+_[user databases]
select * from sys.databases;
GO






-- View the total number of rows of tables, 
select 
	SCHEMA_NAME(t.schema_id) AS [schema],
	OBJECT_NAME(t.object_id) AS [table],
	p.partition_id,
	p.index_id,
	p.rows
from sys.tables t
join sys.partitions p on t.object_id = p.object_id
where index_id IN (0, 1)
order by [schema], [table];
GO







-- List data pages per table
select
	db_file.name AS [db name],
	db_file.physical_name AS [physical location],
	SCHEMA_NAME(t.schema_id) AS [schema name],
	t.object_id AS [table_id],
	t.name AS [table name],
	p.partition_id AS [partition id],
	p.rows AS [rows of partition],
	CASE 
		WHEN p.index_id	= 0 THEN 'Heap'
		WHEN p.index_id	= 1 THEN 'Clustered Index'
		WHEN p.index_id	>= 256000 THEN 'XML'
		ELSE 'Nonclustered index'
	END AS [index type],
	a.type_desc AS [allocation type desc],
	a.allocation_unit_id AS [allocation id],
	page_alloc.[file id],
	page_alloc.[page type],
	page_alloc.[page ids],
	page_alloc.[number of pages]
from sys.master_files db_file
cross join sys.tables t
join sys.partitions p ON t.object_id = p.object_id
join sys.allocation_units a 
	ON a.container_id = 
		CASE
			WHEN p.index_id < 256 THEN p.hobt_id
			ELSE p.partition_id
		END
cross apply (
	SELECT 
		file_id AS [file id],
		page_type_desc AS [page type],
		Count(*) AS [number of pages],
		STRING_AGG(CAST(allocated_page_page_id AS VARCHAR(MAX)), ', ') WITHIN GROUP (ORDER BY allocated_page_page_id ASC) AS [page ids] 
	FROM sys.dm_db_database_page_allocations(db_file.database_id, t.object_id, p.index_id, NULL, 'DETAILED')
	WHERE allocation_unit_id = a.allocation_unit_id
	GROUP BY allocation_unit_id, page_type_desc
) AS page_alloc
where db_file.database_id = DB_ID()
	and db_file.type = 0
order by [db name], [schema name], [table name], [index type], [allocation type desc];
GO







-- View detailed information of a data page
select * from sys.dm_db_page_info(5, 1, 12537, 'DETAILED');
GO






-- View the definition of a stored procedure
EXEC sp_helptext N'AdventureWorks2025.dbo.uspLogError'
;
SELECT OBJECT_DEFINITION(OBJECT_ID(N'AdventureWorks2025.dbo.uspLogError'))
;
SELECT [definition]
FROM sys.sql_modules
WHERE object_id = OBJECT_ID(N'dbo.uspLogError');






-- View the dependencies of a stored procedure
-- Display the objects that depend on a procedure
SELECT referencing_schema_name, referencing_entity_name, referencing_id, referencing_class_desc, is_caller_dependent
FROM sys.dm_sql_referencing_entities('dbo.uspGetBillOfMaterials', 'OBJECT')
GO
-- Display the objects a procedure depends on
SELECT referenced_schema_name, referenced_entity_name,  
referenced_minor_name,referenced_minor_id, referenced_class_desc,  
is_caller_dependent, is_ambiguous  
FROM sys.dm_sql_referenced_entities ('Purchasing.uspVendorAllInfo', 'OBJECT');  
GO
-- Using sys.sql_expression_dependencies
SELECT
	OBJECT_SCHEMA_NAME(referencing_id) AS referencing_schema_name,
	OBJECT_NAME(referencing_id) AS referencing_entity_name,
	o.type_desc AS referencing_description,
	COALESCE(COL_NAME(referencing_id, referencing_minor_id), '(n/a)') AS referenced_column_name,
	is_caller_dependent AS sed
FROM sys.sql_expression_dependencies AS sed
INNER JOIN sys.objects AS o ON sed.referencing_id = o.object_id
WHERE referenced_id = OBJECT_ID('Purchasing.uspVendorAllInfo')
;
SELECT OBJECT_NAME(referencing_id) AS referencing_entity_name,   
    o.type_desc AS referencing_description,
    COALESCE(COL_NAME(referencing_id, referencing_minor_id), '(n/a)') AS referencing_minor_id,   
    referencing_class_desc, referenced_class_desc,  
    referenced_server_name, referenced_database_name, referenced_schema_name,  
    referenced_entity_name,   
    COALESCE(COL_NAME(referenced_id, referenced_minor_id), '(n/a)') AS referenced_column_name,  
    is_caller_dependent, is_ambiguous  
FROM sys.sql_expression_dependencies AS sed  
INNER JOIN sys.objects AS o ON sed.referencing_id = o.object_id  
WHERE referencing_id = OBJECT_ID(N'Purchasing.uspVendorAllInfo'); 







-- View table/index definition
EXEC sp_help 'Production.Product';
EXEC sp_helpindex 'Production.Product';





-- CONTENT
-- A request is also called a batch and may contain one ore more queries.
-- A session may have multiple requests active at the same time.
-- Each query in the request may start multiple threads (tasks), if a parallel execution plan is used.
if object_id('tempdb..#temp') is not null
	drop table #temp
select * INTO #temp from dbo.ArCdKh 
GO

SELECT
	p.spid,
	p.dbid,
	p.hostname,
	p.status AS [process status],
	s.status AS [session status],
	r.status AS [request status],
	(
		SELECT SUBSTRING(
			dest.text,
			(r.statement_start_offset / 2) + 1,
			((CASE r.statement_end_offset
				WHEN -1 THEN DATALENGTH(dest.text)
				ELSE r.statement_end_offset
			END - r.statement_start_offset) / 2) + 1
		)
		FOR XML PATH (''), TYPE
	) AS [request sql text],
	(SELECT destp.text FOR XML PATH (''), TYPE) AS [process sql text]
FROM sys.sysprocesses p
LEFT JOIN sys.dm_exec_sessions s ON s.host_process_id = p.hostprocess
LEFT JOIN sys.dm_exec_requests r ON r.session_id = s.session_id
OUTER APPLY sys.dm_exec_sql_text(r.sql_handle) AS dest
OUTER APPLY sys.dm_exec_sql_text(p.sql_handle) AS destp
WHERE p.spid = @@SPID
GO

if object_id('tempdb..#temp') is not null
	drop table #temp
GO
select * INTO #temp from dbo.ArCdKh 
GO