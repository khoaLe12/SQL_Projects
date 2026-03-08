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
-- 3H: COLUMNSTORE INDEXES
-- 5A: TUNE NONCLUSTERED INDEXES
-- 5B: INDEX MAINTENANCE
-- 5C: HEAP MAINTENANCE


USE SQLTestDB;
GO



-- LIST ALL INDEXES OF A SPECIFIC TABLE
EXEC sp_helpindex 'dbo.Table_primarykey'





-- 1A: TYPES OF INDEX
-- 1. Hash index
--	+ Builds a hash table in memory for memory-optimized tables.
--	+ Provides fast access using hash values.
--	+ Best suited for point lookup and equality predicates.
-- 2. Memory-Optimized Nonclustered Index
--	+ In-memory index for memory-optimized tables.
--	+ Supports a wide range of queries.
--	+ Generally recommended over hash indexes.
-- 3. Clustered Index
--	+ Physically sorts and stores table data based on the clustered index key.
--	+ Each table can have only one clustered index.
-- 4. Nonclustered Index
--	+ Maintains a logical ordering of data based on the index key.
--	+ Stores pointers to the actual data rows.
-- 5. Unique Index
--	+ Ensures that no duplicate values exist in the indexed column(s).
--	+ Enforces uniqueness constraints.
-- 6. Columnstore Index
--	+ Store data in a compressed, column-based format.
--	+ Optimized for analytics, bulk loads, and read-heavy queries.
-- 7. Filtered Index
--	+ A specialized nonclustered index built on a subset of rows.
--	+ Improves query performance and reduces storage/maintenance costs.
-- 8. Spatial Index
--	+ Designed for spatial data types (geometry, geography).
--	+ Enables efficient spatial queries and operations.
-- 9. Full-Text Index
--	+ Token-based functional index managed by the Full-Text Engine.
--	+ Supports advanced text search capabilities (phrases, inflectional forms, synonyms).
-- 10. Index with included columns
--	+ A nonclustered index extended with non-key columns.
--	+ Helps avoid costly lookups by covering queries.
-- 11. Index on Computed Columns
--	+ Built on columns derived from expression or other columns.
--	+ Useful for indexing calculated values.





-- 1B: PHASES OF INDEX BUILDING
-- Phase 1: Data scan and "sort run" generation
--	1. SQL Server scans the base table's data pages to retrieve key values, and build leaf rows (also called entries) from them.
--		+ For a clustered index, the leaf rows are the actual data rows of the table.
--		+ For a nonclustered index, the leaf rows consist of key values plus any included columns.
--	2. Retrieved entries are placed into internal sort buffers until the buffers are full.
--	3. When a buffer fills, its content are sorted and written to disk as an intermediate "sort run".
--	4. This process repeats untill all rows of the base table have been processed into sort runs.
-- Phase 2: Merge and index tree construction
--	1. SQL Server reads the first page from each "sort run".
--	2. It repeatedly selects the lowest key among all active pages and writes that entry to the new index leaf page.
--		+ As leaf pages are filled, upper levels of the B-Tree are built simultaneously.
--	3. When a page in a "sort run" is exhausted, SQL Server advances to the next page in that run.
--	4. When all pages in a "sort run" are processed, the run's storage is freed.
--	5. The merge continues untill all sort runs are consumed and the complete index structure is built.





-- 1C: INDEX OPTIONS
-- ================================================================================================================================================================
-- FILLFACTOR:
-- 1. Specifies the percentage of space to fill on each leaf-level page, leaving the remainder as free space for future growth.
-- 2. Example: FILLFACTOR = 70 → 70% filled, 30% free.
-- 3. Reserved free space helps minimize page splits during inserts/updates.
-- 4. For sequential inserts (e.g, increasing keys), a fill factor of 100 (or 0, which is equivalent) is recommended since new rows won't cause page splits.
-- 5. Lower fill factors increase page count, which can reduce read performance.
-- 6. Applicable only with CREATE INDEX or ALTER INDEX ... REBUILD.
-- ================================================================================================================================================================
-- PAD_INDEX
-- 1. When set to ON, applies the FILLFACTOR setting to non-leaf index pages as well.
-- 2. Must be used together with FILLFACTOR.
-- ================================================================================================================================================================
-- DROP_EXISTING
-- 1. When set to ON, drops the existing index before creating or rebuilding it.
-- 2. Used with ALTER INDEX.
-- ================================================================================================================================================================
-- STATISTICS_NORECOMPUTE
-- 1. When set to ON, disable automatic statistics updates for the index.
-- 2. Useful when you want to manually controls statistics maitenance.
-- ================================================================================================================================================================
-- IGNORE_DUP_KEY
-- 1. When set to ON, duplicate key insert attempts are ignored (the row is discarded)
-- 2. When set to OFF, duplicate key inserts fail and the transaction is rolled back.
-- 3. Cannot be enabled for primary key constraints, unique constraints, views, non-unique indexes, XML indexes, spatial indexes, or filtered indexes.
-- ================================================================================================================================================================
-- ONLINE
-- 1. When set to ON, allows index operations without long-term table locks.
-- 2. Available only in Enterprise Edition or Azure SQL Edge
-- ================================================================================================================================================================
-- ALLOW_PAGE_LOCKS & ALLOW_ROW_LOCKS
-- 1. Control whether SQL Server can use page-level or row-level locks.
-- 2. Locking strategies: row-level, page-level, table-level.
-- 3. Blocking/dealock likelihood (highest → lowest): table-level → page-level → row-level.
-- 4. Data consistency (highest → lowest): table-level, page-level, row-level.
-- 5. Best pratice: keep defaults (ON) to allow SQL Server flexibility.
-- 6. Modify only with careful monitoring and evidence.
-- ================================================================================================================================================================
-- SORT_IN_TEMPDB
-- 1. Determines whether intermediate sort results are stored in tempdb during index creation/rebuild.
-- 2. This options increases the amount of disk space used, but could potentially reduce time to create or rebuild index
-- 3. Can be combined with the "index create memory" option to reduce I/O costs.
-- 4. SET to OFF by default:
--	+ The sort runs are stored in the same location of base table's file group
--	+ During the index building, SQL server has to change between disk read and disk write, and move the disk heads between sort runs area and data page area, and index page area
-- 5. SET to ON:
--	+ The sort runs are stored in other set of disks, help to seperate the process of disk read/write between sort runs and base table's data files
--	+ The disk reads of data page generally continue more serially, also the disk writes to tempdb are generally serial, as do the writes of final index
-- ================================================================================================================================================================
-- MAXDOP
-- 1. Specifies the maximum number of CPUs used for index operations (CREATE, ALTER, DROP, maintenance).
-- 2. Higher values can improve speed but may consume significant CPU and memory resources.
-- ================================================================================================================================================================
-- COMPRESS_ALL_ROW_GROUPS
-- 1. Used when reorganizing a columnstore index.
-- 2. Forces all open delta groups into compressed columnstore format.
-- 3. Provides a lighter alternative to full index rebuilds.





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
;
-- Filterd unique nonclustered index1 with included columns
DROP INDEX IF EXISTS Idx_table_summary_name_vn ON sc2.table_summary
CREATE UNIQUE NONCLUSTERED INDEX Idx_table_summary_name_vn ON sc2.table_summary([name])
INCLUDE ([Address], [country])
WHERE [country] = 'Vietnam'
;
-- Filterd unique nonclustered index2 with included columns
DROP INDEX IF EXISTS Idx_table_summary_name_us ON sc2.table_summary
CREATE UNIQUE NONCLUSTERED INDEX Idx_table_summary_name_us ON sc2.table_summary([name])
INCLUDE ([Address], [country])
WHERE [country] = 'USA'
;
-- Index with some options
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
;
-- Disable and enable index
ALTER INDEX Idx_table_summary_name_country ON sc2.table_summary DISABLE
ALTER INDEX Idx_table_summary_name_country ON sc2.table_summary REBUILD
CREATE INDEX Idx_table_summary_name_country ON sc2.table_summary([name], [country])
WITH (DROP_EXISTING = ON)
;
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





-- 3A: HEAP TABLE:
-- 1. A heap is a table without a clustered index.
--	+ Rows are inserted without any defined order.
--	+ By default, data is retrieved in the order of data pages, not by logical sequence.
-- 2. Heap can be combined with nonclustered indexes to improve both read and write performance.
-- 3. Heaps are not ideal for frequently updated data because updates can cause fragmentation.
--	+ Forwarded records (row relocation with pointers) may occur, leading to additional I/O overhead.
-- 4. Each row in a heap is identified by an 8-byte Row Identifier (RID), which points to the physical location of the row.

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
	CONCAT(s.name, '.', t.name) AS [table],
	p.rows AS [rows count],
	RTRIM(CAST(ISNULL(SUM(a.total_pages) * 8, 0) AS Char)) + ' KB' AS [total space],
    RTRIM(CAST(ISNULL(SUM(a.used_pages) * 8, 0) AS Char)) + ' KB' AS [used space],
    RTRIM(CAST(ISNULL((SUM(a.total_pages) - SUM(a.used_pages)) * 8, 0) AS Char)) + ' KB' AS [unused space],
    CASE 
        WHEN i.index_id = 0 THEN 'Yes'
        ELSE 'No'
   END AS [Is table a Heap?]
FROM sys.tables t
INNER JOIN sys.indexes i ON t.object_id = i.object_id
INNER JOIN sys.partitions p ON t.object_id = p.object_id AND i.index_id = p.index_id
INNER JOIN sys.allocation_units a ON p.partition_id = a.container_id
LEFT JOIN sys.schemas s ON t.schema_id = s.schema_id
WHERE i.index_id = 2 -- 0 → Heap, 1 → Clustered index, 2 → Nonclustered index
GROUP BY t.name,
	s.name,
	i.index_id,
	p.rows
ORDER BY [table];





-- 3B: CLUSTERED INDEX
-- 1. A table can have only one clustered index, because rows can be physically stored in only one order.
-- 2. The clustered index organizes data pages and index pages into B+ Tree structure.
-- 3. The B+ Tree has three main components:
--	+ Root node
--	+ Intermediate (non-leaf) nodes
--	+ Leaf nodes (which are actual data pages)
-- 4. Leaf nodes contain the table's data rows, while intermediate nodes store index keys and pointers (page IDs) to lower-level pages.
-- 5. Because rows are sorted by the clustered index key, intermediate nodes only need to reference the correct data pages rather than individual rows.
-- 6. When data is inserted, updated, or deleted, the index tree may be rebalanced to maintain efficiency. On large trees, this can make modifications slower compared to a heap table.
-- 7. By default, if a PRIMARY KEY is defined on a table, SQL Server automatically creates a clustered index on that column (unless specified otherwise).
-- 8. Searching via the clustered index is generally faster than scanning the entire table, since the index is ordered and usually narrower than the full row.
-- 9. Clustered indexes can be created either through a PRIMARY KEY constraints or explicitly with a CREATE CLUSTERED INDEX statement.

-- Example: Clustered index created via PRIMARY KEY
DROP TABLE IF EXISTS sc2.Table_primarykey
CREATE TABLE sc2.Table_primarykey (
	id Nvarchar(50) NOT NULL DEFAULT '',
	CONSTRAINT PK_Table_primarykey PRIMARY KEY (id)
);

-- Example: Clustered index created explicitly
DROP TABLE IF EXISTS sc2.Table_clusteredindex
CREATE TABLE sc2.Table_clusteredindex (
	id Nvarchar(50) NOT NULL DEFAULT ''
);

DROP INDEX IF EXISTS Idx_Table_clusteredindex_id ON sc2.Table_clusteredindex
CREATE CLUSTERED INDEX Idx_Table_clusteredindex_id ON sc2.Table_clusteredindex(id)





-- 3C: NONCLUSTERED INDEX
-- 1. A table can have multiple nonclustered indexes, because rows can be logically organized in many different orders.
-- 2. A nonclustered index also use a B+ Tree structure. Howerver, at the leaf level it does not contain the actual data rows.
-- 3. Instead, leaf nodes contain row locators:
--	+ On a heap table (no clustered index), the locator is a Row ID (RID) pointing directly to the physical row.
--	+ On a clustered table, the locator is the clustered index key, which is used to find the actual row in the clustered index.
-- 4. Because leaf nodes store locators rather than data rows, nonclustered indexes are typically larger than clustered indexes.
-- 5. A UNIQUE constraint automatically creates a nonclustered index (unless a clustered index is explicitly specified).
-- 6. Nonclustered indexes can be created either via a UNIQUE constraints or explicitly with a CREATE NONCLUSTERED INDEX statement.

-- Example: Nonclustered index created via UNIQUE constraint
DROP TABLE IF EXISTS sc2.Table_uniquecol
CREATE TABLE Table_uniquecol (
	id Nvarchar(50) NOT NULL UNIQUE, -- creates nonclustered index by default
);

-- Example: Explicit nonclustered index
DROP TABLE IF EXISTS sc2.Table_nonclusteredindex
CREATE TABLE sc2.Table_nonclusteredindex (
	id Nvarchar(50)
);

DROP INDEX IF EXISTS Idx_Table_nonclusteredindex_id ON sc2.Table_nonclusteredinde
CREATE NONCLUSTERED INDEX Idx_Table_nonclusteredindex_id ON sc2.Table_nonclusteredindex(id)





-- 3D: UNIQUE INDEX
-- 1. A unique index enforces uniqueness: the index key cannot contain duplicate values.
-- 2. The IGNORE_DUP_KEY option controls behavior when duplicate keys are inserted:
--	+ ON → Duplicate rows are ignored; the insert continues for non-duplicates.
--	+ OFF → The entire insert operation fails and is rolled back if duplicates exist.
-- 3. Unique indexes can be clustered or nonclustered, depending on how they are defined.

-- Example: unique clustered index with IGNORE_DUP_KEY = ON/OFF
IF EXISTS (SELECT * FROM sys.indexes WHERE name = N'Idx_Table_clusteredindex_id' AND object_id = OBJECT_ID(N'sc2.Table_clusteredindex', N'U'))
	DROP INDEX Idx_Table_clusteredindex_id ON sc2.Table_clusteredindex
CREATE UNIQUE CLUSTERED INDEX Idx_Table_clusteredindex_id ON sc2.Table_clusteredindex(id)
WITH (IGNORE_DUP_KEY = ON)
;
IF EXISTS (SELECT * FROM sys.indexes WHERE name = 'Idx_Table_nonclusteredindex_id' AND OBJECT_ID = OBJECT_ID(N'sc2.Table_nonclusteredindex', N'U'))
	DROP INDEX Idx_Table_nonclusteredindex_id ON sc2.Table_nonclusteredindex
CREATE UNIQUE NONCLUSTERED INDEX Idx_Table_nonclusteredindex_id ON sc2.Table_nonclusteredindex(id)
WITH (IGNORE_DUP_KEY = OFF)





-- 3E: FILTERED INDEX
-- (Note: Cannot be applied to PRIMARY KEY, UNIQUE constraints, or clustered index)
-- 1. A filtered index is a disk-based, rowstore nonclustered index.
-- 2. It uses a filter predicate to index only a subset of rows in the table.
-- 3. A well-designed filtered index can improve query performance while reducing maintenance and storage costs.
-- 4. Filtered indexes provide more accurate statistics for the subset of data, which can improve execution plans and query performance.
-- 5. Because they cover fewer rows, filtered index are smaller than full-table indexes, reducing the impact of data modifications and lowering maintenance overhead.
-- 6. Their smaller size also reduces disk storage requirements.
-- 7. Filtered indexes support only simple comparison operators; they do not support LIKE.
-- 8. Data conversion functions are only allowed on the right-hand side of the comparison operator in the filter expression.
-- 9. Computed columns cannot be referenced in the filtered definition.
-- 10. In some cases, it may be beneficial to create multiple filtered nonclustered indexes for different states of data rather than a single full nonclustered index.
-- 11. Design considerations:
--	+ Use filtered indexes on subsets of data frequently queried (e.g., NOT NULL vlaues).
--	+ Create filtered indexes for specific states in a status column (e.g., workflow stages).
--	+ Create filtered indexes based on categories of data.

-- Example table
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





-- 3F: WITH INCLUDED COLUMNS (applies only to nonclustered indexes)
-- 1. A nonclustered index can include nonkey columns to cover more queries.
-- 2. An index is called a "covering index" if it contains all columns needed by a query.
-- 3. By including nonkey columns, the query optimizer can retrieve values directly from the index that:
--	+ No table lookup is required.
--	+ Data pages are not accessed.
--	+ So disk I/O operations are reduced.
-- 4. Including nonkey columns increases the size of the index pages, so design carefully.

-- Example table
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
-- 2. Determinism requirements: 
--		The expression must be deterministic - it must always return the same result for the same input values.
--		Examples of nondeterministic functions:
--			+ GETDATE(), NEWID(), RAND() -> values change at different times or calls.
--			+ Aggregate functions (SUM, AVG, etc) -> results depend on data that can change.
--			+ CAST/CONVERT of string literals to date/time without explicit style codes -> results can vary by LANGUAGE/DATEFORMAT/REGION settings.
--		Recommendation: use CONVERT with explicit style codes to ensure deterministic behavior.
-- 3. Precision requirements: 
--		The expression must be precise. FLOAT and REAL data types are considered imprecise, so any computed column involving them cannot be indexed.
-- 4. SET options requirements: 
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





-- 3H: COLUMNSTORE INDEXES
-- 1. Columnstore indexes store data in a coumn-wise format (physically column-based, logically row-organized).
--	+ Achieve compression up to 10x compared to uncompressed storage.
--	+ Benefit from compressing column data rather than row data, enabling high compression rates.
--	+ 

-- 1. Columnstore index is a column-based data storage which physically store data in a column-wise format, and logically organized as a table with rows
--	+ Effectively compress data up to 10 times smaller compared to uncompress one
--	+ Benefit from compress column data instead of row data, achieving high compression rate
--	+ Can achieve up to 10 times the query performance, especially for quering large range of values
--	+ Significantly reduce data storage cost -> reduce I/O cost, but could intensively consume CPUs to decompress data when read
-- 2. The structure of a columnstore table
--	+ A table is sliced into multiple rowgroups
--	+ Each rowgroup contains a list of compressed column segments which each segement represents a column of the table
--	+ Each column segment is stored in a seperate LoB page as data page
--	+ The data page consists of 2 parts are Dictionary and Data Stream
-- 3. To reduce fragmentation, the columnstore index uses other clustured index called deltastore to temporarily identify deleted rows
--	+ If the number of deleted rows is large enough, Reorganize index to actual delete rows from compressed rows group, and completely remove deltastore, which increased index quality
-- 4. To improve compression and performance, the index uses delta rowgroup/deltastore
--	+ Delta rowgroup is a clustered B-tree index used to store data in a rowstore structure
--	+ Deltastore is a group of delta rowgroups
--	+ The deltastore helps to load small of data before compress (when the data reach at least 102,400 rows) and move it into the columnstore
--	+ Implement Rebuild/Reorganize to completely remove and move deltastore to columnstore
--	+ Its ideal to do bulk insert to minimize delta rowgroups (the best size is between 102,400 and 1,048,576)
-- 5. The columnstore is ideal for data warehousing, real-time analytics workloads, or any workload that insert large volumnes of data with minimal updates/deletes (like IoT) as:
--	+ Significantly reduce data storage cost
--	+ Reduce memory usage since a small of data is loaded
--	+ Best practice if query often select a few columns, and require scanning large range of values
-- 6. Choose the appropriate data compression method
--	+ Use columnstore compression for best query performance
--	+ Use archive compression for best data compression
-- 7. Don't use clustured columnstore index when
--	+ The table requires VARCHAR(MAX), NVARCHAR(MAX) or VARBINARY(MAX) data types.
--	+ The table has less than one million rows per partition.
--	+ More than 10% of the operations on the table are updates and deletes
-- 8. Columnstore performance
--	+ Column elimination occurs when a query target only some columns, the server will skip reading other columns
--	+ Rowstore elimination occurs when a query only focus on a specific range of values of a column which represent the nature order (like column "Order date") over time
--		++ To determine which rows to be eliminated, the index uses metadata consists of maximum and minimum value of each column segement, to identify the range value of that column

-- Define columnstore index
CREATE TABLE ColumnStoreTable (
	id Nvarchar(50),
	name Nvarchar(20),
	value Int
)
CREATE CLUSTERED COLUMNSTORE INDEX Idx_ColumnStoreIndex ON ColumnStoreTable WITH (MAXDOP = 1);

-- Prepare for bulk insert
WITH CTE_LargeData AS (
	SELECT 
		NEWID() AS id,
		CAST('Name 1' AS Nvarchar) AS name,
		1 AS value
	UNION ALL
	SELECT
		NEWID(),
		CAST('Name ' + RTRIM(CAST((value + 1) AS Char)) AS Nvarchar),
		value + 1
	FROM CTE_LargeData
	WHERE value <= 1048577
)
SELECT * INTO ##temp FROM CTE_LargeData
OPTION (MAXRECURSION 0)
-- ! This require enabling xp_cmdshell, and configuring SQL Server protocol to use SSL/TLS certificate from trusted authorities, and set encryption requirement to be obligatory
EXEC sys.xp_cmdshell 'bcp "SELECT * FROM ##temp" queryout "D:\Projects\SQL-Projects\Notes\ColumnStoreTable1.csv" -c -t, -r\n -S localhost\SQLEXPRESS -U sa -P Khoa@153426';
EXEC sys.xp_cmdshell 'bcp "SELECT TOP 102000 * FROM ##temp" queryout "D:\Projects\SQL-Projects\Notes\ColumnStoreTable2.csv" -c -t, -r\n -S localhost\SQLEXPRESS -U sa -P Khoa@153426';

-- Bulk insert 1,048,578 records
BULK INSERT ColumnStoreTable
FROM 'D:\Projects\SQL-Projects\Notes\ColumnStoreTable1.csv'
WITH (
	FIRSTROW = 1,
	FIELDTERMINATOR = ',',
	ROWTERMINATOR = '\n',
	TABLOCK
);

-- Bulk insert 102,000 records
BULK INSERT ColumnStoreTable
FROM 'D:\Projects\SQL-Projects\Notes\ColumnStoreTable2.csv'
WITH (
	FIRSTROW = 1,
	FIELDTERMINATOR = ',',
	ROWTERMINATOR = '\n',
	TABLOCK
);

-- Inspect rowgroups and deltastore
SELECT 
	CONCAT(OBJECT_SCHEMA_NAME(cs.[object_id], DB_ID()), '.', OBJECT_NAME(cs.[object_id])) AS [table],
	i.name AS [index],
	cs.partition_number AS [partition],
	cs.row_group_id AS [rowgroups],
	cs.delta_store_hobt_id AS [delta rowgroups],
	cs.state_desc AS [state],
	cs.total_rows AS [total rows],
	ISNULL(cs.deleted_rows, 0) AS [deleted rows],
	RTRIM(CAST(ISNULL(cs.size_in_bytes, 0) AS Char)) + ' bytes' AS [size]
FROM sys.dm_db_column_store_row_group_physical_stats cs
INNER JOIN sys.indexes i ON i.object_id = cs.object_id AND i.index_id = cs.index_id
ORDER BY cs.object_id, cs.index_id, cs.row_group_id





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