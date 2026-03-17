

-- If a query is slow, go check
--	1. Indexes
--	 + If the query is missing indexes
--	 + Check the state of indexes used by the query (fragmentation, page density) -> do reorganize/rebuild index
--		- Avoid over maintaining every index in the database since it highly costs resource
--	2. Statistics
--	 + Check if statistic is up to date


-- Use Table Partitions 
-- 1. To seperate old data and new data
--	+ Old data is rarely queried/modified
--	+ New data is queried all the time -> focus on improving query on new data


-- Insert many values to a table
-- 1. Implement Bulk insert or use table-valued parameters on a procedure
--	+ Reduce roud trips to the server
-- 2. Table-value parameters are efficient for inserting less than 1,000 rows.
-- 3. Bulk insert is the best practice for inserting a very large amount of data rows (> 1,000 rows)


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
WHERE DepartmentID = id