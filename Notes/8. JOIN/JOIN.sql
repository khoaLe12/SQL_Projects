

-- JOIN
-- 1. Joins are fundamental database operations that used to combine data from two or more tables into a single result set.
-- 2. SQL Server implements both logical join operators (defined by T-SQL syntax) and physical join operators (the actual algorithm used to execute joins).
-- 3. Logical join operations:
--	+ INNER JOIN: returns the combined data of two tables that both side satisfy the condition.
--	+ LEFT OUTER JOIN: combines rows from two tables while keeping records from left tables, the unmatched records will have null value on the right side.
--	+ RIGHT OUTER JOIN: combines rows from two tables while keeping records from right tables, the unmatched records will have null value on the left side.
--	+ FULL OUTER JOIN: joins two tables base on condition, and returns both macthed and unmatched records from two sides, the unmatched records will have null value on the other side.
--	+ CROSS JOINS: join each record of left table to each record of right table, the result is the multiplication of 2 tables.
--	+ SEMI JOIN: returns a single row in the left table for each match to the right table, no duplications of matched row are allowed (constructed with EXISTS or IN keyword).
--	+ ANTI SEMI JOIN: returns rows from the left table where no matching row exists in the right table (constructed with NOT EXISTS, NOT IN, or LEFT JOIN with NULL matching condition)
-- 4. Physical join operations:
--	+ Nested loops joins
--		- Perform nested loops on two tables to find matches.
--		- The smaller join input is identified as outer input table (top input) and the other as inner input table (bottom input).
--		- For each row in the outer loop, it perform an inner loop to search for the matches of the row.
--		- It is the fastest join operator if the outer input has fewer than 10 rows, and the inner input is indexed on its join columns (called index nested loops join)
--		- If the index is built as part of the query plan, its called a temporary index nested loops join.
--	+ Merge joins
--	+ Hash joins
--	+ Adaptive joins (available on SQL Server 2017+)




-- PRACTICE
USE AdventureWorks2025;
GO



-- SEMI JOIN using EXISTS/IN keywords (returns customers who have placed at least one order)
SELECT c.*
FROM Sales.Customer c
WHERE EXISTS(SELECT 1 FROM Sales.SalesOrderHeader o WHERE o.CustomerID = c.CustomerID)
	AND c.CustomerID IN (SELECT CustomerID FROM Sales.SalesOrderDetail);
GO



-- ANTI SEMI JOIN using NOT EXISTS/NOT IN keywords, and LEFT JOIN clause (returns customers who have never placed an order)
SELECT c.*
FROM Sales.Customer c
WHERE NOT EXISTS(SELECT 1 FROM Sales.SalesOrderHeader o WHERE o.CustomerID = c.CustomerID)
	AND c.CustomerID NOT IN (SELECT CustomerID FROM Sales.SalesOrderHeader);
GO

SELECT c.*
FROM Sales.Customer c
LEFT JOIN Sales.SalesOrderHeader o ON o.CustomerID = c.CustomerID
WHERE o.CustomerID IS NULL