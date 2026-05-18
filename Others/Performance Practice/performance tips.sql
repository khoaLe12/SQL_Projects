---- 1. SELECT only what you need

---- 2. Avoid unnecessary DISTINCT and ORDER BY

---- 3. For exploration purpose, limit rows

---- 4. Create nonclustured Indx on frequently used columns

---- 5. Avoid applying functions to columns in WHERE (espeically on indexed columns)
----					Functions on columns can block index usage
----					If possible using LIKE instead

---- 6. Avoid leading wildcards while using LIKE

---- 7. Use IN instead of multiple OR conditions



------------------------JOIN----------------------------
---- 8. Understand the speed of joins and use inner join when possible

---- 9. Use Explicit Join (ANSI Join) Instead of Implicit Join (non-ANSI Join)

---- 10. Make sure to index the columns used in the ON clause

---- 11. Filter before joining (Big Tables)
-- Filter After Join (WHERE)
SELECT c.FirstName, o.OrderID
FROM Sales.Customers c
INNER JOIN Sales.Orders o ON c.CustomerID = o.CustomerID
WHERE o.OrderStatus = 'Delivered'
-- Filter During Join (ON)
SELECT c.FirstName, o.OrderID
FROM Sales.Customers c
INNER JOIN Sales.Orders o ON c.CustomerID = o.CustomerID AND o.OrderStatus = 'Delivered'
-- Filter Before Join (SUBQUERY)
SELECT c.FirstName, o.OrderID
FROM Sales.Customers c
INNER JOIN (
	SELECT OrderID, CustomerID 
	FROM Sales.Orders 
	WHERE OrderStatus = 'Delivered'
) o ON c.CustomerID = o.CustomerID
GO


---- 12. Aggregate Before Joining (Big tables)
-- Grouping and joining: Best practice for small-medium tables 
SELECT c.CustomerID, c.FirstName, COUNT(o.OrderID) AS OrderCount
FROM Sales.Customers c
INNER JOIN Sales.Orders o ON o.CustomerID = c.CustomerID
GROUP BY c.CustomerID, c.FirstName
-- Pre-aggregated subquery: Best practice for big tables
SELECT c.CustomerID, c.FirstName, o.OrderCount
FROM Sales.Customers c 
INNER JOIN (
	SELECT CustomerID, COUNT(OrderID) AS OrderCount 
	FROM Sales.Orders 
	GROUP BY CustomerID
) o ON o.CustomerID = c.CustomerID
-- Correlated subquery: Bad practice
SELECT 
	c.CustomerID,
	c.FirstName,
	(
		SELECT COUNT(*)
		FROM Sales.Orders
		WHERE CustomerID = c.CustomerID
	) AS OrderCount
FROM Sales.Customers c
GO




------------------------UNION----------------------------
---- 13. Use UNION Instead Of OR in JOINS (OR in JOINS is performance killer)

---- 14. Check for Nested Loops and Use SQL HINTS
-- HASH JOIN is good practice for having Small Table (left) and Big Table (right)
SELECT o.OrderID, c.FirstName
FROM Sales.Customers c
INNER JOIN Sales.Orders o ON c.CustomerID = o.CustomerID
OPTION (HASH JOIN)

---- 15. Use UNION ALL instead of using UNION | duplicates are acceptable

---- 16. Use UNION ALL + Distinct instead of using UNION | dupliacted are not acceptable





------------------------AGGREGATING DATA----------------------------
---- 17. Use ColumnStore Index for Aggregations on Large Table

---- 18. Pre-Aggregate Data and store it in new Table for Reporting


---- 19. JOIN vs EXISTS vs IN
---- How to filter a table base on the condition of other table (ex: get all orders of customers from 'USA')
-- JOIN
SELECT o.OrderID, o.Sales
FROM Sales.Orders o
INNER JOIN Sales.Customers c ON c.CustomerID = o.CustomerID
WHERE c.Country = 'USA'
-- EXISTS
SELECT o.OrderID, o.Sales
FROM Sales.Orders o
WHERE EXISTS(
	SELECT TOP 1 1
	FROM Sales.Customers c
	WHERE c.CustomerID = o.CustomerID
		AND c.Country = 'USA'
)
-- IN (Bad Practice if Sales.Customers is big table and has no index on Country column)
SELECT o.OrderID, o.Sales
FROM Sales.Orders o
WHERE o.CustomerID IN (
	SELECT c.CustomerID
	FROM Sales.Customers c
	WHERE c.Country = 'USA'
)


---- 20. Avoid Redundant Logic in query





------------------------CREATE TABLE----------------------------
---- 21. Try avoiding data types VARCHAR and TEXT (consume a lot of resource)

---- 22. Avoid (MAX) unnecessarily large lengths in data types

---- 23. Use the NOT NULL constraint where applicable

---- 24. Ensure all tables have a clustered primary key to provide structure and improve query performance

---- 25. Add non-clustered indexes to foreign keys that are frequently queried to speed up lookups




------------------------INDEXING----------------------------
---- 26 Avoid Over Indexing, as it can slow down insert, update, and delete operations

---- 27 Regularly review and drop unused indexes to save space and improve write performance

---- 28 Update table statistics weekly to ensure the query optimizer has the most up-to-date information

---- 29 Reorganize and rebuild fragmented indexes weekly to maintain query performance.

---- 30 For large tables (e.g., fact tables), partition the data and then apply a columnstore index for best performance results















