-- TABLE OF CONTENT
-- 1A: TYPES OF INDEX
-- 1B: PHASES OF INDEX BUILDING
-- 1C: INDEX OPTIONS
-- 2A: SUMMARY ALL
-- 3A: HEAP TABLE
-- 3B: CLUSTERED INDEX
-- 3C: NONCLUSTERED INDEX
-- 3D: UNIQUE INDEX
-- 3E: FILTERED INDEX
-- 3F: WITH INCLUDED COLUMNS
-- 3G: INDEX ON COMPUTED COLUMNS


USE SQLTestDB;
GO



-- LIST ALL INDEXES OF A SPECIFIC TABLE
EXEC sp_helpindex 'dbo.Table_primarykey'




-- 1A: TYPES OF INDEX
-- 1. Hash index: build a hash table in memory provide an effective way to access data through hash value
-- 2. Memory-optimized Nonclutered index: 
-- 3. Clustered index: sorts and stores the data physically in order based on the clustered index key.
-- 4. Nonclustered index: sorts the data logically based on the non-clustered index key
-- 5. Unique index: Ensure no duplicate values
-- 6. Columnstore index: Compress and store data using column-based data storage, best use case for bulk load and read-only queries
-- 7. Filtered index: An optimized nonclustered index, could improve query performance, reduce index storage costs and index maintenance costs
-- 8. Spatial index: Perform certain operations more efficiently on spatial objects
-- 9: Full-text index: Token-based functional index that is built and maitained by Microsoft Full-Text Engine
-- 10: Index with included columns: A nonclustered index that is extended to include nonkey columns, help to avoid the lookup operations
-- 11: Index on computed columns: An index on a column that is derived from the value of one or more other columns




-- 1B: PHASES OF INDEX BUILDING
-- Phase 1: Data scan and "sort run" generation
--	1. SQL Server scans the base table's data pages to retrieve key values, and build leaf rows (also called entries) from them.
--		+ For a clustered index, the leaf rows are the actual data rows of the table.
--		+ For a nonclustered index, the leaf rows consist of key values plus any included columns.
--	2. Retrieved entries are placed into internal sort buffers until the buffers are full.
--	3. When a buffer fills, its content are sorted and written to disk as an intermediate "sort run".
--	4. This process repeats untill all rows of the base table have been processed into sort runs.
-- Phas 2: Merge and index tree construction
--	1. SQL Server reads the first page from each "sort run".
--	2. It repeatedly selects the lowest key among all active pages and writes that entry to the new index leaf page.
--		+ As leaf pages are filled, upper levels of the B-Tree are built simultaneously.
--	3. When a page in a "sort run" is exhausted, SQL Server advances to the next page in that run.
--	4. When all pages in a "sort run" are processed, the run's storage is freed.
--	5. The merge continues untill all sort runs are consumed and the complete index structure is built.






-- 1C: INDEX OPTIONS
-- ================================================================================================================================================================
-- FILLFACTOR: (VALUE OF 70 MEANS 70% OF TAKEN SPACE AND 30% OF FREE SPACE (REMAINDER))
-- 1. Determine the percentage of space on each leaf-level page to be filled, reserving the remainder on each page as free space for future growth
-- 2. The empty space is reserved at the end of each page -> increase size of page -> minimize page splits caused by extra length added/updated
-- 3. If data is always added to the end of the table (sequential insert/increasing key), the fill factor of 100 (0 is as same as 100) or small of remainder is recommended, since adding new row wont cause page split
-- 4. Lower fill factor -> require more space, increase number of pages -> decrease read performance since more pages needed to read
-- 5. Can only be used with CREATE INDEX or ALTER INDEX REBUILD WITH
-- ================================================================================================================================================================
-- PAD_INDEX
-- 1. Set ON to apply FILLFACTOR to the non-leaf index pages
-- 2. Used with option FILLFACTOR
-- ================================================================================================================================================================
-- DROP_EXISTING
-- 1. Set ON to drop existing index then create/rebuild index
-- 2. Used with ALTER INDEX statement
-- ================================================================================================================================================================
-- STATISTICS_NORECOMPUTE
-- 1. Set ON to turn off automatic statistics update
-- ================================================================================================================================================================
-- IGNORE_DUP_KEY
-- 1. Set ON to ignore duplicate keys. SET OFF to not allow duplicate keys, if there is duplication -> insert operation fails, data is rolled back
-- 2. Can not be set to ON for primary key constraint, unique constraint, view, nonunique indexes, XML indexes, spatial indexes, and filtered indexes
-- ================================================================================================================================================================
-- ONLINE
-- 1. Set ON to prevent long-term table locks during building index
-- 2. Only available on Enterprise edition of SQL Server or Azure SQL Edge
-- ================================================================================================================================================================
-- ALLOW_PAGE_LOCKS & ALLOW_ROW_LOCKS
-- 1. Control SQL Server Database Engine to use page-level locks, row-level lock or not
-- 2. There are 3 locking strategies: row-level lock, page-level lock, table-level lock
-- 3. The rate of blocking/deadlocks occurrences in descending order: table-level -> page-level -> row-level
-- 4. The level of data consistency in descending order: table-level, page-level, row-level
-- 5. Best pratice: keep these options as default (ON) so SQL Server can have more options of locking strategy
-- 6. Modify it with careful consideration, through monitoring and clear evidance
-- ================================================================================================================================================================
-- SORT_IN_TEMPDB
-- 1. Used to direct the SQL Server to use tempdb to store the intermediate sort results or not
-- 2. This options increases the amount of disk space used, but could potentially reduce time to create or rebuild index
-- 3. Could configure "index create memory" option to tell SQL Server use memory instead of disk help reduce I/O cost (see "Server configuration: index create memory"), work for both ON and OFF
-- 4. SET to OFF by default:
--	+ The sort runs are stored in the same location of base table's file group
--	+ During the index building, SQL server has to change between disk read and disk write, and move the disk heads between sort runs area and data page area, and index page area
-- 5. SET to ON:
--	+ The sort runs are stored in other set of disks, help to seperate the process of disk read/write between sort runs and base table's data files
--	+ The disk reads of data page generally continue more serially, also the disk writes to tempdb are generally serial, as do the writes of final index
-- ================================================================================================================================================================
-- MAXDOP
-- 1. Specify the max degree of parallelism when CREATE/ALTER/FROP an index
-- 2. High value of MAXDOP could be resource intensive (more CPUs and memory used)
-- ================================================================================================================================================================
-- COMPRESS_ALL_ROW_GROUPS
-- 1. Used for Reorganizing a columnstore index
-- 2. It force all open delta groups into compressed columnstore format
-- 3. A replacement approach for resource-intensive index rebuild





-- 2A: SUMMARY ALL
DROP TABLE IF EXISTS sc2.table_summary
CREATE TABLE sc2.table_summary (
	id Nvarchar(50) NOT NULL DEFAULT '',
	[name] Nvarchar(20) NOT NULL DEFAULT '',
	[age] Int NOT NULL DEFAULT 0,
	[Address] Nvarchar(100) NOT NULL DEFAULT '',
	[country] Nvarchar(50) NOT NULL DEFAULT '',
	CONSTRAINT PK_table_summary PRIMARY KEY (id)
)

-- Filterd unique nonclustered index1 with included columns
DROP INDEX IF EXISTS Idx_table_summary_name_vn ON sc2.table_summary
CREATE UNIQUE NONCLUSTERED INDEX Idx_table_summary_name_vn ON sc2.table_summary([name])
INCLUDE ([Address], [country])
WHERE [country] = 'Vietnam'
-- ===================================================================================================

-- Filterd unique nonclustered index2 with included columns
DROP INDEX IF EXISTS Idx_table_summary_name_us ON sc2.table_summary
CREATE UNIQUE NONCLUSTERED INDEX Idx_table_summary_name_us ON sc2.table_summary([name])
INCLUDE ([Address], [country])
WHERE [country] = 'USA'
-- ===================================================================================================

-- index with some options
DROP INDEX IF EXISTS Idx_table_summary_name_country ON sc2.table_summary
CREATE UNIQUE NONCLUSTERED INDEX Idx_table_summary_name_country ON sc2.table_summary([name], [country])
WITH (
	FILLFACTOR = 80,
	PAD_INDEX = ON
)
;
ALTER INDEX Idx_table_summary_name_country ON sc2.table_summary
REBUILD WITH (
	FILLFACTOR = 80,
	PAD_INDEX = ON,
	STATISTICS_NORECOMPUTE = ON,
	IGNORE_DUP_KEY = ON,
	IGNORE_DUP_KEY = ON,
	ALLOW_PAGE_LOCKS = ON,
	ALLOW_ROW_LOCKS = ON,
	SORT_IN_TEMPDB = ON,
	DATA_COMPRESSION = PAGE, -- ROW
	MAXDOP = 8,
	COMPRESS_ALL_ROW_GROUPS = ON
	-- ONLINE = ON -- only available on Enterprise edition of SQL Server or Azure SQL Edge
)
;
ALTER INDEX Idx_table_summary_name_country ON sc2.table_summary
REORGANIZE WITH (
	COMPRESS_ALL_ROW_GROUPS = ON
)
-- ===================================================================================================

-- Disable and enable index
ALTER INDEX Idx_table_summary_name_country ON sc2.table_summary DISABLE
;
ALTER INDEX Idx_table_summary_name_country ON sc2.table_summary REBUILD
;
CREATE INDEX Idx_table_summary_name_country ON sc2.table_summary([name], [country])
WITH (DROP_EXISTING = ON)
-- ===================================================================================================

-- See properties of all the indexes in a table
SELECT 
	i.name AS index_name,
	i.type_desc,
	i.is_unique,
	ds.type_desc AS filegroup_or_partition_schema,
	ds.name AS filegroup_or_partition_name,
	i.ignore_dup_key,
	i.is_primary_key,
	i.is_unique_constraint,
	i.fill_factor,
	i.is_padded,
	i.is_disabled,
	i.allow_row_locks,
	i.allow_page_locks,
	i.has_filter,
	i.filter_definition
FROM sys.indexes i
INNER JOIN sys.data_spaces AS ds ON i.data_space_id = ds.data_space_id
WHERE i.is_hypothetical = 0 AND i.index_id <> 0
	AND i.[object_id] = OBJECT_ID('sc2.table_summary')
-- ===================================================================================================














-- 3A: HEAP TABLE:
-- 1. A table without clustrered index -> The row is inserted with no order, and the data is retrieved from heap in order of data pages be default
-- 2. Use heap with non-clustered index to strengthen both read and write process
-- 3. Heap is not ideal if the data is frequently updated, it could cause fragmentation (forwarded record pointing) -> can incur additional I/O
-- 4. Each row of heap is identified by a reference of 8-byte row identifier (RID)
-- Create heap table using ddl and select statement
-- Check index types of all tables, index_id = 0 -> heap, index_id = 1 -> clustered index
DROP TABLE IF EXISTS sc2.Heap1
CREATE TABLE sc2.Heap1 (
	Value1 Nvarchar(10),
	Value2 Decimal(19, 4)
)
;
DROP TABLE IF EXISTS sc2.Heap2
SELECT * INTO sc2.Heap2 FROM dbo.SQLTest
;
SELECT 
	t.name AS 'Your TableName',
	s.name AS 'Your SchemaName',
	p.rows AS 'Number of Rows in Your Table',
	SUM(a.total_pages) * 8 AS 'Total Space of Your Table (KB)',
    SUM(a.used_pages) * 8 AS 'Used Space of Your Table (KB)',
    (SUM(a.total_pages) - SUM(a.used_pages)) * 8 AS 'Unused Space of Your Table (KB)',
    CASE 
        WHEN i.index_id = 0
            THEN 'Yes'
        ELSE 'No'
        END AS 'Is Your Table a Heap?'
FROM sys.tables t
INNER JOIN sys.indexes i ON t.object_id = i.object_id
INNER JOIN sys.partitions p ON t.object_id = p.object_id AND i.index_id = p.index_id
INNER JOIN sys.allocation_units a ON p.partition_id = a.container_id
LEFT JOIN sys.schemas s ON t.schema_id = s.schema_id
WHERE i.index_id <= 1
GROUP BY t.name,
	s.name,
	i.index_id,
	p.rows
ORDER BY 'Your TableName';









-- 3B: CLUSTERED INDEX
-- 1. A clustered table can only have exactly one clustered index, since the data rows can only be physically stored in only one order
-- 2. The table's data file contains additional page called index page
-- 3. The index pages of rowstore index store keys in a hierarchical structure called Balance Tree or B+ Tree 
-- 4. The index tree has 3 main parts are: root node, intermediate nodes and leaf nodes. Which the leaf node is the actual data pages that are referenced by index page of intermediate nodes
-- 5. Since the data rows are sorted by index keys, the intermediate nodes only have to reference to appropriate data pages by its page id instead of directly locating the data rows
-- 6. For each modification of the table data, the index tree could be redefined to maintain its balance property -> which could make INS/UPD/DEL be less effective if the tree is big
-- 7. The table is automatically created with a clustered index if it is defined with PRIMARY KEY
-- 8. Generally, searching the index is much faster than searching the table, since an index frequently contains very few columns per row and the rows are in sorted order
-- Create index using PRIMARY KEY CONSTRAINT, or with CREATE index statement
DROP TABLE IF EXISTS sc2.Table_primarykey
CREATE TABLE sc2.Table_primarykey (
	id Nvarchar(50) NOT NULL DEFAULT '',
	CONSTRAINT PK_Table_primarykey PRIMARY KEY (id)
)
;
DROP TABLE IF EXISTS Table_clusteredindex ON sc2.Table_clusteredindex
CREATE TABLE sc2.Table_clusteredindex (
	id Nvarchar(50) NOT NULL DEFAULT ''
)
;
DROP INDEX IF EXISTS Idx_Table_clusteredindex_id ON sc2.Table_clusteredindex
CREATE CLUSTERED INDEX Idx_Table_clusteredindex_id ON sc2.Table_clusteredindex(id)
WITH (ONLINE = ON) -- consider setting ONLINE to ON to prevent long-term table locks during building index











-- 3C: NONCLUSTERED INDEX (MOSTLY SAME AS CLUSTERED INDEX)
-- 1. A nonclustered table can have one or many nonclustered indexs, since the data rows can be logically sorted in many order
-- 2. In the balance tree, instead of having data page at the leaf node, it has additional index pages define row locators
-- 3. For heap table, the row locator contains RIDs point to the actual rows. For clustered table, it stores clustered keys point to data page instead
-- 3. Because the leaf nodes are replaced by additional index pages, the size of nonclustered index are slightly larger than clustered index
-- 4. The table automatically has a nonclustured index if it created with a UNIQUE constraint
-- Create index using UNIQUE CONSTRAINT, or with CREATE index statement
DROP TABLE IF EXISTS sc2.Table_uniquecol
CREATE TABLE Table_uniquecol (
	id Nvarchar(50) NOT NULL UNIQUE,
)
;
DROP TABLE IF EXISTS sc2.Table_nonclusteredindex
CREATE TABLE sc2.Table_nonclusteredindex (
	id Nvarchar(50)
)
;
DROP INDEX IF EXISTS Idx_Table_nonclusteredindex_id ON sc2.Table_nonclusteredinde
CREATE NONCLUSTERED INDEX Idx_Table_nonclusteredindex_id ON sc2.Table_nonclusteredindex(id)
WITH (ONLINE = OFF)










-- 3D: UNIQUE INDEX
-- 1. A unique index guarantees the index key cotains no duplicate values
-- 2. It has an option of ingnoring duplicate keys, if yes -> ignore duplicate keys, if no -> the entire insert operation fails and the data is rolled back
IF EXISTS (SELECT * FROM sys.indexes WHERE name = N'Idx_Table_clusteredindex_id' AND object_id = OBJECT_ID(N'sc2.Table_clusteredindex', N'U'))
	DROP INDEX Idx_Table_clusteredindex_id ON sc2.Table_clusteredindex
CREATE UNIQUE CLUSTERED INDEX Idx_Table_clusteredindex_id ON sc2.Table_clusteredindex(id)
WITH (IGNORE_DUP_KEY = ON)
;
IF EXISTS (SELECT * FROM sys.indexes WHERE name = 'Idx_Table_nonclusteredindex_id' AND OBJECT_ID = OBJECT_ID(N'sc2.Table_nonclusteredindex', N'U'))
	DROP INDEX Idx_Table_nonclusteredindex_id ON sc2.Table_nonclusteredindex
CREATE UNIQUE NONCLUSTERED INDEX Idx_Table_nonclusteredindex_id ON sc2.Table_nonclusteredindex(id)
WITH (IGNORE_DUP_KEY = OFF)










-- 3E: FILTERED INDEX (can't be aplied to PRIMARY KEY or UNIQUE CONSTRAINT, or with CLUSTERED INDEX)
-- 1. A filtered index is an optimized disk-based rowstore nonclustered index
-- 2. It uses a filter predicate to index a portion of rows in the table
-- 3. A well-designed filtered index can improve query performance and reduce index maintenance and storage cost
-- 4. It has more accurate statistics comparing to full-table statistics -> improve execution plan quality -> improve query performance
-- 5. It reduce the size of index tree, and is smaller than full-table index -> reduce the affected range of data modification -> reduce index maintenance costs and statistics update cost
-- 6. It has smaller size -> reduce disk storage
-- 7. Filtered index only support simple comparison operators and don't support LIKE operators
-- 8. The data conversion operators only be allowed on the right side of the comparison operator in the filter expression
-- 9. Computed column can't be reference in the filter definition
-- 10. Sometimes it may be a good pratice to crate multiple filtered nonclustered indexes instead of single nonclustered index
-- 11. Design consideration: 
-- + Create filtered index on subset of data that is frequently queried (if null values are not required on query condition -> indexed for NOT NULL values instead of both NULL and NOT NULL)
-- + Create filtered index for each state listed in a column represent progress of something
-- + Create filtered index base on categories of data
DROP TABLE IF EXISTS sc2.Table_filteredindex
CREATE TABLE sc2.Table_filteredindex (
	id Nvarchar(50) NOT NULL,
	[date] Smalldatetime NULL DEFAULT '',
	[value] Decimal(19,4) NOT NULL DEFAULT 0,
	[status] Nvarchar(1) NOT NULL DEFAULT '1' -- 1: waiting, 2: on progres, 3: finished
)
;
DROP INDEX IF EXISTS Idx_Table_filteredindex_value ON sc2.Table_filteredindex
DROP INDEX IF EXISTS Table_filteredindex_status1 ON sc2.Table_filteredindex
DROP INDEX IF EXISTS Table_filteredindex_status2 ON sc2.Table_filteredindex
DROP INDEX IF EXISTS Table_filteredindex_status3 ON sc2.Table_filteredindex
;
CREATE NONCLUSTERED INDEX Idx_Table_filteredindex_value
	ON sc2.Table_filteredindex([value])
	WHERE [date] IS NOT NULL;
CREATE NONCLUSTERED INDEX Table_filteredindex_status1
	ON sc2.Table_filteredindex([status])
	WHERE [date] IS NOT NULL AND [status] = '1';
CREATE NONCLUSTERED INDEX Table_filteredindex_status2
	ON sc2.Table_filteredindex([status])
	WHERE [date] IS NOT NULL AND [status] = '2';
CREATE NONCLUSTERED INDEX Table_filteredindex_status3
	ON sc2.Table_filteredindex([status])
	WHERE [date] IS NOT NULL AND [status] = '3';










-- 3F: WITH INCLUDED COLUMNS (can only applied with nonclustered index)
-- 1. An index can include nonkey columns that helps to cover more queries
-- 2. An index is called "covering index" if it includes all columns represented in the query
-- 3. With included nonkey columns, query optimizer can quickly locate columns value within index -> table lookup is not performed -> no data pages accessed ->  reduce disk I/O operations
-- 4. Including nonkey columns increases the size of index page
DROP TABLE IF EXISTS sc2.Table_nonkeycolumns
CREATE TABLE sc2.Table_nonkeycolumns (
	id Nvarchar(50) NOT NULL PRIMARY KEY,
	[name] Nvarchar(30) NOT NULL DEFAULT '',
	[value] Decimal(19,4) NOT NULL DEFAULT 0,
)
;
DROP INDEX IF EXISTS Idx_Table_nonkeycolumns_id ON sc2.Table_nonkeycolumns
;
CREATE NONCLUSTERED INDEX Idx_Table_nonkeycolumns_id
ON sc2.Table_nonkeycolumns(id)
INCLUDE ([name], [value])








-- 3G: INDEX ON COMPUTED COLUMNS
-- To create an index on a computed column, the column must meet several requirements:
-- 1. Ownership requirements: 
--		All functions referenced in the computed column expression must be owned by the same user as the table.
-- 3. Determinism requirements: 
--		The expression must be deterministic - it must always return the same result for the same input values.
--		Examples of nondeterministic functions:
--			+ GETDATE(), NEWID(), RAND() -> values change at different times or calls.
--			+ Aggregate functions (SUM, AVG, etc) -> result depend on data that can change.
--			+ CAST/CONVERT of string literals to date/time without explicit style codes -> results can vary by LANGUAGE/DATEFORMAT/REGION settings.
--		Recommendation: use CONVERT with explicit style codes to ensure deterministic behavior.
-- 4. Precision requirements: 
--		The expression must be precise. FLOAT and REAL data types are considered imprecise, so any computed column involving them cannot be indexed.
-- 5. SET options requirements: 
--		Certain SET options must be enabled at the connection level when creating or modifying indexes on computed columns:
--			+ SET NUMERIC_ROUNDABORT OFF
--			+ SET ANSI_NULLS ON
--			+ SET ANSI_PADDING ON
--			+ SET ANSI_WARNINGS ON
--			+ SET ARITHABORT ON
--			+ SET CONCAT_NULL_YIELDS_NULL ON
--			+ SET QUOTED_IDENTIFIER ON
--		These options ensure consistent evaluation of computed expressions.
DROP TABLE IF EXISTS sc2.Table_computedcolumn
CREATE TABLE sc2.Table_computedcolumn (
	Id Nvarchar(50) NOT NULL PRIMARY KEY,
	Val1 Int,
	Val2 Int,
	Val3 Float,
	valid_computed_column AS Val1 + Val2,
	nondeterministic_computed_column AS GETDATE(),
	nonprecise_computed_column1 AS Val3,
	nonprecise_computed_column2 AS
		CASE 
			WHEN Val3 > 0 THEN Val1
			ELSE Val2
		END,
	persisted_nonprecise_computed_column AS Val3 PERSISTED
)
;
DROP INDEX IF EXISTS Idx_Table_computedcolumn_valid ON sc2.Table_computedcolumn
CREATE NONCLUSTERED INDEX Idx_Table_computedcolumn_valid ON sc2.Table_computedcolumn(valid_computed_column)
;
DROP INDEX IF EXISTS Idx_Table_computedcolumn_valid_persisted ON sc2.Table_computedcolumn
CREATE NONCLUSTERED INDEX Idx_Table_computedcolumn_valid_persisted ON sc2.Table_computedcolumn(persisted_nonprecise_computed_column)
;
DROP INDEX IF EXISTS Idx_Table_computedcolumn_nondeterministic ON sc2.Table_computedcolumn
CREATE NONCLUSTERED INDEX Idx_Table_computedcolumn_nondeterministic ON sc2.Table_computedcolumn(nondeterministic_computed_column)
;
DROP INDEX IF EXISTS Idx_Table_computedcolumn_nonprecise1 ON sc2.Table_computedcolumn
CREATE NONCLUSTERED INDEX Idx_Table_computedcolumn_nonprecise1 ON sc2.Table_computedcolumn(nonprecise_computed_column1)
;
DROP INDEX IF EXISTS Idx_Table_computedcolumn_nonprecise2 ON sc2.Table_computedcolumn
CREATE NONCLUSTERED INDEX Idx_Table_computedcolumn_nonprecise2 ON sc2.Table_computedcolumn(nonprecise_computed_column2)






-- 4A: COLUMNSTORE INDEXES
-- 1. Columnstore index is a column-based data storage which physically store data in a column-wise format, and logically organized as a table with rows
-- 2. This structure effectively compress data up to 10 times smaller compared to uncompress one
-- 3. The index can gains up to 10 times the query performance, especially for big data
-- 4. It could intensively consume CPUs to decompress data when read
-- 5. A columnstore table
--	+ Is sliced into multiple rowgroups
--	+ Each rowgroup contains a list of compressed column segments
--	+ Each column segment represents a column of the table
-- 6. To reduce fragmentation, the columnstore index uses other clustured index called deltastore to temporarily store deleted rows
-- 7. To improve compression and performance, the index uses delta rowgroup/deltastore
--	+ Delta rowgroup is a clustered B-tree index used to store data in a rowstore structure
--	+ Deltastore is a group of delta rowgroups
--	+ The deltastore helps to load small of data before compress (when the data reach at least 102400 rows) and move it into the columnstore
--	+ Implement Rebuild/Reorganize to completely remove and move deltastore to columnstore
-- 8. The columnstore is ideal for data warehousing, real-time analytics workloads, or any workload that insert large volumnes of data with minimal updates/deletes (like IoT):
--	+ Significantly reduce data storage cost, reduce I/O cost
--	+ Reduce memory usage
--	+ Best practice if query often select a few columns, and require scanning large range of values
-- 9. Don't use clustured columnstore index when
--	+ The table requires VARCHAR(MAX), NVARCHAR(MAX) or VARBINARY(MAX) data types.
--	+ The table has less than one million rows per partition.
--	+ More than 10% of the operations on the table are updates and deletes
-- 10. Choose the appropriate data compression method
--	+ Use columnstore compression for best query performance
--	+ Use archive compression for best data compression









-- 5A: TUNE NONCLUSTERED INDEXES
-- 1.SQL Server provide missing index feature which give index suggestions.
-- 2. Index suggestions has some limitations: 
--	+ There are no tests or cost-benefit analysis againts suggestions.
--	+ The feature suggests only nonclustered disk-based rowstore indexes.
--	+ The suggestions do not specify an order for key columns.
-- 2. To view missing index suggestions, query the following DMV:
--	+ sys.dm_db_missing_index_group_stats: summary information, for example, the performance improvements gained from implementing the specific group of missing indexes.
--	+ sys.dm_db_missing_index_groups: information of groups of missing indexes.
--	+ sys.dm_db_missing_index_details: detailed information like table name, column names and column types to make up the missing index.
--	+ sys.dm_db_missing_index_columns: information about table columns that are missing an index.
SELECT 
	TOP 20
	CONVERT(varchar(30), GETDATE(), 126) AS runtime,
	CONVERT(decimal(28,1),
		migs.avg_total_system_cost * migs.avg_user_impact * (migs.user_seeks + migs.user_scans)
	) AS estimated_improvement,
	'CREATE INDEX missing_index_' +
		CONVERT(varchar, mig.index_group_handle) + '_' +
		CONVERT(varchar, mid.index_handle) + ' ON ' +
		mid.statement + ' (' + ISNULL(mid.equality_columns, '') +
		CASE
			WHEN mid.equality_columns IS NOT NULL
				AND mid.inequality_columns IS NOT NULL
				THEN ','
			ELSE ''
		END + ISNULL(mid.inequality_columns, '') + ')' +
		ISNULL(' INCLUDE (' + mid.included_columns + ')', '') AS create_index_statement
FROM sys.dm_db_missing_index_groups mig
JOIN sys.dm_db_missing_index_group_stats migs ON migs.group_handle = mig.index_group_handle
JOIN sys.dm_db_missing_index_details mid ON mid.index_handle = mig.index_handle
ORDER BY estimated_improvement DESC;
GO






-- 5B: INDEX MAINTENANCE
-- 1. Index fragmentation (only occurs on rowstore index):
--	+ Exists when logical ordering within the index does not macth the physical ordering of index pages (means index data are not sequentially stored).
--	+ Increasing as many data modifications performed, especially non-sequential insertion on full page causes page splits.
--	+ As more page splits occurs, more pages and gaps on pages increased, cause the index to become scattered (fragmented)
--	+ For full/range index scans, additional I/O is required as more pages to read
-- 2. Page density
--	+ Define how much space allocated on a page
--	+ If page density is low, more pages are created to store the same amount of data
--	+ With low page density, there are more pages to read, therefore the cost of I/O is higher
-- 3. In columnstore index, fragmentation is defined as the ratio of deleted rows to total rows
-- 4. Implement Index Reorganize and Rebuild operation to reduce index fragmentation and increase page density.
--	+ Reorganize rowstore index is physically reorder the leaf-level pages, and compacts index page to the fill factor of the index
--	+ Reorganize columnstore index forces deltastore rows goups into larger compressed row groups which reduce the number of groups, this cost CPU resource to compress data
--	+ Rebuild an index will drop and re-create the whole index tree, which cost more resource compared to Reorganize
--	+ Rebuild rowstore index removes fragmentation in all levels of index, rebuild can be performed on a single index, some indexes or on all indexes at once
--	+ Rebuild a columnstore index removed fragmenatation, and moves any deltastore rows into columnstore
--	+ Rebuild index also update statistics to the current state

-- MEASURE ROWSTORE INDEX FRAGMENTATION AND PAGE DENSITY
SELECT 
	'' AS [Rowstore index fragmentation],
	DB_NAME(ips.database_id) AS [database name],
	ISNULL(OBJECT_SCHEMA_NAME(ips.object_id, ips.database_id), '') + '.' + ISNULL(OBJECT_NAME(ips.object_id, ips.database_id), '') AS [table name],
	idx.name AS [index name],
	ips.index_type_desc AS [index type],
	ips.alloc_unit_type_desc AS [unit type],
	ips.page_count AS [page count],
	FORMAT(ips.avg_fragmentation_in_percent, '##0.###') + '%' AS [avg fragmentation percent],
	ISNULL(ips.fragment_count, 0) AS [fragment count],
	ISNULL(ips.avg_fragment_size_in_pages, 0) AS [avg fragment size],
	FORMAT(ips.avg_page_space_used_in_percent, '##0.###') + '%'  AS [page density]
FROM sys.dm_db_index_physical_stats(DB_ID('AdventureWorks2025'), NULL, NULL, NULL, 'DETAILED') ips
INNER JOIN sys.indexes idx ON idx.object_id = ips.object_id AND idx.index_id = ips.index_id
ORDER BY ips.avg_fragmentation_in_percent DESC
GO

-- MEASURE COLUMNSTORE INDEX FRAGMENTATION
WITH CTE_columnstore_row_group_partition AS (
	SELECT 
		object_id,
		index_id,
		partition_number,
		SUM(deleted_rows) AS partition_deleted_rows,
		SUM(total_rows) AS partition_total_rows
	FROM sys.dm_db_column_store_row_group_physical_stats
	WHERE state_desc = 'COMPRESSED'
	GROUP BY object_id, index_id, partition_number
),
CTE_columnstore_internal_partition AS (
	SELECT
		object_id,
		index_id,
		partition_number,
		SUM(rows) AS delete_buffer_rows
	FROM sys.internal_partitions
	WHERE internal_object_type_desc = 'COLUMN_STORE_DELETE_BUFFER'
	GROUP BY object_id, index_id, partition_number
)
SELECT 
	OBJECT_SCHEMA_NAME(i.object_id) AS schema_name,
	OBJECT_NAME(i.object_id) AS object_name,
	i.name AS index_name,
	i.type_desc AS index_type,
	crgp.partition_number,
	100 * (ISNULL(crgp.partition_deleted_rows + ISNULL(cip.delete_buffer_rows, 0), 0)) / NULLIF(crgp.partition_total_rows, 0) AS avg_fragmentation_in_percent
FROM sys.indexes i
INNER JOIN CTE_columnstore_row_group_partition AS crgp ON i.object_id = crgp.object_id AND i.index_id = crgp.index_id
LEFT OUTER JOIN CTE_columnstore_internal_partition AS cip ON i.object_id = cip.object_id AND i.index_id = cip.index_id AND crgp.partition_number = cip.partition_number
ORDER BY schema_name, object_name, index_name, partition_number, index_type
GO
;

-- REORGANIZE AN INDEX (if fragmentation <= 60%)
ALTER INDEX AK_Employee_NationalIDNumber
ON HumanResources.Employee
REORGANIZE

-- REBUILD AN INDEX (if fragmentation > 60%)
ALTER INDEX PK_WorkOrderRouting_WorkOrderID_ProductID_OperationSequence
ON Production.WorkOrderRouting
REBUILD

SELECT 
	DB_NAME(ips.database_id) AS [database name],
	ISNULL(OBJECT_SCHEMA_NAME(ips.object_id, ips.database_id), '') + '.' + ISNULL(OBJECT_NAME(ips.object_id, ips.database_id), '') AS [table name],
	ips.index_type_desc AS [index type],
	ips.alloc_unit_type_desc AS [unit type],
	ips.page_count AS [page count],
	FORMAT(ips.avg_fragmentation_in_percent, '##0.###') + '%' AS [avg fragmentation percent],
	ISNULL(ips.fragment_count, 0) AS [fragment count],
	ISNULL(ips.avg_fragment_size_in_pages, 0) AS [avg fragment size],
	FORMAT(ips.avg_page_space_used_in_percent, '##0.###') + '%'  AS [page density]
FROM sys.dm_db_index_physical_stats(DB_ID('AdventureWorks2025'), OBJECT_ID('Production.WorkOrderRouting'), NULL, NULL, 'LIMITED') ips
ORDER BY ips.avg_fragmentation_in_percent DESC
GO


-- 5C: HEAP MAINTENANCE
-- 1. Heap fragmentation
--	+ Increasing as many data modifications performed, especially update/delete operations could cause gaps on pages.
--	+ If the gap space is insufficient for new added data, it create index pointer to the new location of that data.
--	+ If a record is updated with larger size data that exceeds the allocated space, it also create a new index pointer.
--	+ Index pointer could reduce read performance since server has to traverse through pointer to get the real required data.