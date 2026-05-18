-- 'sys' system schema contains metadata about database tables, vies, columns, indexes, etc
-- Dynamic Management View (DMV) provide real-time insights into Database performance and system health


-- list all indexes on a specific table
sp_helpindex 'dbo.mmct'
GO
sp_helpindex 'dbo.glct'
GO

-- monitoring index usage
SELECT 
	scm.name AS SchemaName,
	tbl.name AS TableName,
	idx.name AS IndexName,
	idx.type_desc AS IndexType,
	idx.is_primary_key AS IsPrimaryKey,
	idx.is_unique AS IsUnique,
	idx.is_disabled AS IsDisabled,
	s.user_seeks AS UserSeek,
	s.user_scans AS UserScan,
	s.user_lookups AS UserLooup,
	s.user_updates,
	COALESCE(s.last_user_seek, s.last_user_scan) AS lastUpdate
FROM sys.indexes idx
JOIN sys.tables tbl ON tbl.object_id = idx.object_id
JOIN sys.schemas scm ON scm.schema_id = tbl.schema_id
LEFT JOIN sys.dm_db_index_usage_stats s ON s.object_id = idx.object_id
ORDER BY tbl.name, idx.name
GO


-- Monitor Missing Indexes
-- See the recommendation on missing indexes
-- Evaluate the recommendations before creating any index
SELECT 
	*
FROM sys.dm_db_missing_index_details
GO


-- Monitor duplicate indexes
SELECT 
	tbl.name AS TableName,
	col.name AS IndexColumn,
	idx.name AS IndexName,
	idx.type_desc AS IndexType,
	COUNT(*) OVER (PARTITION BY tbl.name, col.name) AS ColumnCount
FROM sys.indexes idx
JOIN sys.tables tbl ON tbl.object_id = idx.object_id
JOIN sys.index_columns ic ON idx.object_id = ic.object_id AND idx.index_id = ic.index_id AND ic.is_included_column = 0
JOIN sys.columns col ON col.object_id = idx.object_id AND col.column_id = ic.column_id
ORDER BY tbl.name, col.name

SELECT * FROM sys.indexes WHERE object_id = '2124898987' AND index_id = 2
SELECT * FROM sys.index_columns WHERE object_id = '2124898987' AND index_id = 2 AND is_included_column = 0
GO


-- SQL server read Statistics to decide which way to construct execution plan
-- Exp: Table Scan, Index Scan or Index Seek
-- Update statistics
-- 1. Weekly job to update statistics on weekends
-- 2. After migrating data
SELECT 
	s.object_id, s.stats_id,
	SCHEMA_NAME(t.schema_id) AS SchemaName,
	t.name AS TableName,
	s.name,
	sp.last_updated AS LastUpdated,
	DATEDIFF(day, sp.last_updated, GETDATE()) AS LastUpdateDay,
	sp.rows AS [Rows],
	sp.modification_counter AS ModificationSinceLastUpdate
FROM sys.stats s
JOIN sys.tables t ON s.object_id = t.object_id
CROSS APPLY sys.dm_db_stats_properties(s.object_id, s.stats_id) AS sp
WHERE t.name LIKE 'glct%'
ORDER BY t.name

UPDATE STATISTICS dbo.MMCt _WA_Sys_00000001_4D9A16FC	-- Update 1 statistic of a table
UPDATE STATISTICS dbo.MMCt								-- Update statistics of a table
EXEC sp_updatestats										-- Update all statistics
GO


-- Monitoring Fragmenattion
-- When to defragment?
-- 1. <10% -> No action needed
-- 2. 10-30% Reorganize
-- 3. >30% Rebuild
SELECT 
	tbl.name AS TableName,
	idx.name AS IndexName,
	s.avg_fragmentation_in_percent,
	s.page_count
FROM sys.dm_db_index_physical_stats(DB_ID(), NULL, NULL, NULL, 'LIMITED') s
JOIN sys.tables tbl ON tbl.object_id = s.object_id
JOIN sys.indexes idx ON idx.object_id = s.object_id AND idx.index_id = s.index_id
WHERE tbl.name = 'MmCt'
ORDER BY TableName

ALTER INDEX [Ma_cty-Ngay_ct] ON dbo.MmCt REORGANIZE
ALTER INDEX [Ma_cty-Id_ph] ON dbo.MmCt REBUILD




---------------------------------------------------------------------------------------------------------------------------------------
--------------------------------------------------------------PARTITIONING-------------------------------------------------------------
---------------------------------------------------------------------------------------------------------------------------------------
SELECT * FROM GlCt


-- Step 1: Create a Partition function
-- Define logic on how to divide table into prtitions based on PARTITION KEY
CREATE PARTITION FUNCTION PartitionByNam (int)
AS RANGE LEFT FOR VALUES(2021, 2022, 2023, 2024, 2025, 2026)
-- Query list all existing Partition Function
SELECT
	name,
	function_id,
	type,
	type_desc,
	boundary_value_on_right
FROM sys.partition_functions



-- Step 2: Create Filegroups
-- Logical container of one or more data files to help organize partitions
ALTER DATABASE SalesDB ADD FILEGROUP FG_glct_2021;
ALTER DATABASE SalesDB ADD FILEGROUP FG_glct_2022;
ALTER DATABASE SalesDB ADD FILEGROUP FG_glct_2023;
ALTER DATABASE SalesDB ADD FILEGROUP FG_glct_2024;
ALTER DATABASE SalesDB ADD FILEGROUP FG_glct_2025;
ALTER DATABASE SalesDB ADD FILEGROUP FG_glct_2026;
ALTER DATABASE SalesDB ADD FILEGROUP FG_glct_2027;
-- Remove Filegroups
ALTER DATABASE SalesDB REMOVE FILEGROUP FG_glct_2021;
ALTER DATABASE SalesDB REMOVE FILEGROUP FG_glct_2022;
ALTER DATABASE SalesDB REMOVE FILEGROUP FG_glct_2023;
ALTER DATABASE SalesDB REMOVE FILEGROUP FG_glct_2024;
ALTER DATABASE SalesDB REMOVE FILEGROUP FG_glct_2025;
ALTER DATABASE SalesDB REMOVE FILEGROUP FG_glct_2026;
ALTER DATABASE SalesDB REMOVE FILEGROUP FG_glct_2027;
-- Query list all existing Filegroups
SELECT * FROM sys.filegroups WHERE type = 'FG'



-- Step 3: Create Datafiles and add .ndf Files to each group
-- Physical storage of data assigned to each group
ALTER DATABASE SalesDB ADD FILE
(
	NAME = glct_P_2021, -- Logical name
	FILENAME = 'D:\0. Khoa\0. SQL practices\Database\glct_P_2021.ndf' -- not to use default path
) TO FILEGROUP FG_glct_2021;
ALTER DATABASE SalesDB ADD FILE
(
	NAME = glct_P_2022, -- Logical name
	FILENAME = 'D:\0. Khoa\0. SQL practices\Database\glct_P_2022.ndf' -- not to use default path
) TO FILEGROUP FG_glct_2022;
ALTER DATABASE SalesDB ADD FILE
(
	NAME = glct_P_2023, -- Logical name
	FILENAME = 'D:\0. Khoa\0. SQL practices\Database\glct_P_2023.ndf' -- not to use default path
) TO FILEGROUP FG_glct_2023;
ALTER DATABASE SalesDB ADD FILE
(
	NAME = glct_P_2024, -- Logical name
	FILENAME = 'D:\0. Khoa\0. SQL practices\Database\glct_P_2024.ndf' -- not to use default path
) TO FILEGROUP FG_glct_2024;
ALTER DATABASE SalesDB ADD FILE
(
	NAME = glct_P_2025, -- Logical name
	FILENAME = 'D:\0. Khoa\0. SQL practices\Database\glct_P_2025.ndf' -- not to use default path
) TO FILEGROUP FG_glct_2025;
ALTER DATABASE SalesDB ADD FILE
(
	NAME = glct_P_2026, -- Logical name
	FILENAME = 'D:\0. Khoa\0. SQL practices\Database\glct_P_2026.ndf' -- not to use default path
) TO FILEGROUP FG_glct_2026;
ALTER DATABASE SalesDB ADD FILE
(
	NAME = glct_P_2027, -- Logical name
	FILENAME = 'D:\0. Khoa\0. SQL practices\Database\glct_P_2027.ndf' -- not to use default path
) TO FILEGROUP FG_glct_2027;
-- Query list all files in the database
SELECT
	fg.name AS FilegroupName,
	mf.name AS LogicalFileName,
	mf.physical_name AS PhysicalFilePath,
	mf.size / 128 AS SizeInMB
FROM sys.filegroups fg
JOIN sys.master_files mf ON fg.data_space_id = mf.data_space_id
WHERE mf.database_id = DB_ID('SalesDB');



-- Step 4: Create Partition Scheme
-- To connect partition function to each Filegroups (map partitions to a filegroup)
CREATE PARTITION SCHEME SchemePartitionByNam
AS PARTITION PartitionByNam
TO (FG_glct_2021, FG_glct_2022, FG_glct_2023, FG_glct_2024, FG_glct_2025, FG_glct_2026, FG_glct_2027)
-- Query list all Partition Scheme
SELECT 
	ps.name AS PartitionSchemeName,
	pf.name AS PartitionFunctionName,
	ds.destination_id AS PartitionNumber,
	fg.name AS FilegroupName
FROM sys.partition_schemes ps
JOIN sys.partition_functions pf ON ps.function_id = pf.function_id
JOIN sys.destination_data_spaces ds ON ps.data_space_id = ds.partition_scheme_id
JOIN sys.filegroups fg ON ds.data_space_id = fg.data_space_id



-- Step 5: Create the Partitioned Table
CREATE TABLE [dbo].[GlCt_Partitioned](
	[id] [uniqueidentifier] NOT NULL DEFAULT '',
	[ma_cty] [nvarchar](5) NOT NULL DEFAULT '',
	[id_ph] [nvarchar](50) NOT NULL DEFAULT '',
	[stt] [int] NOT NULL DEFAULT 0,
	[thang] [int] NOT NULL DEFAULT 0,
	[nam] [int] NOT NULL DEFAULT 0,
	[ma_ct] [nvarchar](3) NOT NULL DEFAULT '',
	[ngay_ct] [smalldatetime] NOT NULL DEFAULT '',
	[ngay_lct] [smalldatetime] NOT NULL DEFAULT '',
	[so_ct] [nvarchar](12) NOT NULL DEFAULT '',
	[ngay_lo] [smalldatetime] NOT NULL DEFAULT '',
	[so_lo] [nvarchar](12) NOT NULL DEFAULT '',
	[nguoi_gd] [nvarchar](50) NOT NULL DEFAULT '',
	[dien_giai] [nvarchar](300) NOT NULL DEFAULT '',
	[tk] [nvarchar](20) NOT NULL DEFAULT '',
	[tk_du] [nvarchar](20) NOT NULL DEFAULT '',
	[ps_no_nt] [decimal](19, 4) NOT NULL DEFAULT 0,
	[ps_co_nt] [decimal](19, 4) NOT NULL DEFAULT 0,
	[ma_nt] [nvarchar](3) NOT NULL DEFAULT '',
	[ty_gia] [decimal](19, 4) NOT NULL DEFAULT 0,
	[ps_no] [decimal](19, 4) NOT NULL DEFAULT 0,
	[ps_co] [decimal](19, 4) NOT NULL DEFAULT 0,
	[nhom_dk] [nvarchar](3) NOT NULL DEFAULT '',
	[ma_kh] [nvarchar](20) NOT NULL DEFAULT '',
	[ma_bp] [nvarchar](20) NOT NULL DEFAULT '',
	[ma_nv] [nvarchar](20) NOT NULL DEFAULT '',
	[ma_hd] [nvarchar](20) NOT NULL DEFAULT '',
	[ma_phi] [nvarchar](20) NOT NULL DEFAULT '',
	[ma_spct] [nvarchar](20) NOT NULL DEFAULT '',
	[ma_ku] [nvarchar](20) NOT NULL DEFAULT '',
	[ma_lo] [nvarchar](50) NOT NULL DEFAULT '',
	[opt1] [smalldatetime] NOT NULL DEFAULT '',
	[opt2] [smalldatetime] NOT NULL DEFAULT '',
	[opt3] [decimal](19, 4) NOT NULL DEFAULT 0,
	[opt4] [decimal](19, 4) NOT NULL DEFAULT 0,
	[opt5] [nvarchar](50) NOT NULL DEFAULT '',
	[opt6] [nvarchar](50) NOT NULL DEFAULT '',
	[opt7] [nvarchar](20) NOT NULL DEFAULT '',
	[opt8] [nvarchar](20) NOT NULL DEFAULT '',
	[opt9] [nvarchar](20) NOT NULL DEFAULT '',
	[opt10] [nvarchar](20) NOT NULL DEFAULT '',
	[cdate] [smalldatetime] NOT NULL DEFAULT '',
	[cuser] [nvarchar](20) NOT NULL DEFAULT '',
	[ldate] [smalldatetime] NOT NULL DEFAULT '',
	[luser] [nvarchar](20) NOT NULL DEFAULT '',
	[ma_kv] [nvarchar](20) NOT NULL DEFAULT '',
	[ma_cf] [nvarchar](20) NOT NULL DEFAULT '',
	[dot_tt] [int] NOT NULL DEFAULT 0
) ON SchemePartitionByNam (nam)
GO



-- Step 6: Insert Data into the Partitioned Table
INSERT INTO dbo.GlCt_Partitioned
SELECT * FROM dbo.GlCt
-- Identify which filegroup does each partition use and how many rows does each partition store
SELECT
	p.partition_number AS PartitionNumber,
	f.name AS PartitionFilegroup,
	p.rows AS NumberOfGroup
FROM sys.partitions p
JOIN sys.destination_data_spaces dds ON p.partition_number = dds.destination_id
JOIN sys.filegroups f ON dds.data_space_id = f.data_space_id
WHERE OBJECT_NAME(p.object_id) = 'GlCt_Partitioned';



-- Query on partitioned table
SELECT * 
FROM dbo.GlCt_Partitioned
WHERE nam IN (2022, 2023)

-- Query on non-partitioned table
SELECT *
FROM dbo.GlCt
WHERE nam IN (2022, 2023)




SELECT COUNT(*)
FROM dbo.GlCt_Partitioned
WHERE nam IN (2022, 2023)

SELECT COUNT(*)
FROM dbo.GlCt
WHERE nam IN (2022, 2023)