

-- If a query is slow, go check
-- 1. Indexes
--	+ If the query is missing indexes
--	+ Check the state of indexes used by the query (fragmentation, page density) -> do reorganize/rebuild index
--		- Avoid over maintaining every index in the database since it highly costs resource
--	+ For columnstore index, reduce the number of INSERT/UPDATE/DELETE statement by doing bulk operations, columnstore index works at its best if almost 90% of operations performed are SELECT/AGGREGATE
--	+ Periodically reorganize/rebuild indexes
-- 2. Statistics
--	+ Check if statistic is up to date



-- Use Table Partitions 
-- 1. To seperate old data and new data
--	+ Old data is rarely queried/modified
--	+ New data is queried all the time -> focus on improving query on new data


-- Apply Sharding and Replication
-- 1. Replication is a technique that replicates the primary database
--	+ The primary is responsible for handling all write/update requests
--	+ The replicated databases is used to process query requests which are distributed to all replications -> improved read performance
-- 2. Sharding is a technique that split database into smaller independent parts called shards
--	+ Each shard is stored in seperate database servers -> effectively reduce stress compared to a single centralized database
--	+ Require a good strategy to accurately identify shard key.



-- Recompiled stored procedures if the database undergoes significant changes to its data or structure
-- 1. This updates and optimized the procedure's query plan for those changes



-- Insert many values to a table
-- 1. Implement Bulk insert or use table-valued parameters on a procedure
--	+ Reduce roud trips to the server
-- 2. Table-value parameters are efficient for inserting less than 1,000 rows.
-- 3. Bulk insert is the best practice for inserting a very large amount of data rows (> 1,000 rows)
-- ============================================================================================================
-- TABLE-VALUED PARAMETER
-- Create table type
CREATE TYPE DepartmentTableType
	AS TABLE
	(
		Name Nvarchar(50),
		GroupName Nvarchar(50),
		ModifiedDate Datetime
	);
GO
-- Create an insert procedure to receive data for the table-valued parameter.
CREATE OR ALTER PROCEDURE dbo.asDepartmentIns 
	@TVP DepartmentTableType READONLY
AS
BEGIN
	SET NOCOUNT ON;

	INSERT INTO HumanResources.Department (
		Name,
		GroupName,
		ModifiedDate
	)
	SELECT 
		Name,
		GroupName,
		ModifiedDate
	FROM @TVP

	SET NOCOUNT OFF;
END
GO
-- Demo
DECLARE @departmentTVP AS DepartmentTableType;
INSERT INTO @departmentTVP (Name, GroupName, ModifiedDate)
VALUES	('Name1', 'GroupName1', GETDATE()),
		('Name2', 'GroupName2', GETDATE()),
		('Name3', 'GroupName3', GETDATE())
EXEC dbo.asDepartmentIns @departmentTVP;
GO





-- Update many records to a table
-- Construct a dynamic query string to update in a single batch
UPDATE HumanResources.Department
SET Name = updateName,
	GroupName = updateGroupName
FROM (VALUES 
	('Name1', 'GroupName1', 1),
	('Name2', 'GroupName2', 2),
	('Name3', 'GroupName3', 3)
) AS vals (updateName, updateGroupName, id)
WHERE DepartmentID = id;
GO



-- Implement failover mechanism for a database to ensure its availability and reliability