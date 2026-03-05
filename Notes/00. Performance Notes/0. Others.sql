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