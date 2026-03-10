

-- GRAPH DATABASE
-- 1. Offering capabilities to model complicated many-to-many relationships
-- 2. Consists of nodes and edges, node represent an entity and edge as relationship
-- 3. Provide some unique features:
--	+ Edges/relationships can have attributes or properties associated with them
--	+ A single edge can connect multiple nodes
--	+ Enable queries with pattern macthing and multi-hop navigation
--	+ Easily express transitive closure and polymorphic queries
-- 4. Each node table has an implicit column/pseudo-column called $node_id
--	+ The $node_id column is automatically generated with the combination of obejct ID for the graph table and internally generated bigint value.
--	+ By default, SQL Server create a unique, nonclustered index for $node_id
--	+ Inserting or updating on $node_id is not allowed which cause error
--	+ Select $node_id will return JSON representation of the value, and column name is displayed as the format [$node_id_<unique suffix>]
-- 5. Edge table includes 3 pseudo-columns are $edge_id, $from_id, $to_id
--	+ The $edge_id is a unique identifier for a given edge, it is the combination of object ID of the edge table and interanlly generated bigint value
--	+ The $from_id is the $node_id of the node, from where the edge originates.
--	+ The $to_id is the $node_id of the node, at which the edge terminates.
--	+ By default, SQL Server create unqiue, nonclustered idnexes for these columns
--	+ Inserting or updating on $edge_id is not allowed which cause error
-- 6. Use metadata views to see attributes of a node or edge table
--	+ The columns is_node, is_edge of sys.tables identify the graph tables 
--	+ Columns graph_type, graph_type_desc of sys.columns to list the types of columns used in graph tables
-- 7. SQL Server provide built-in MATCH function for pattern macthing and traversal through the graph
--	+ Used to specify a search condition for a graph, as part of WHERE clause.
--	+ The search condition could be a pattern to search or path to traverse in the graph
--	+ The pattern goes from one node to another via an edge, in the direction of the arrow provided

-- Create graph objects
CREATE TABLE Person
(
	ID Int PRIMARY KEY,
	Name Varchar(100),
	Age Int
) AS NODE;
CREATE TABLE friend
(
	StartDate Date
) AS EDGE;

-- Insert into node table
INSERT INTO dbo.Person VALUES (1, 'Alice', 20);
INSERT INTO dbo.Person VALUES (2, 'John', 21);
INSERT INTO dbo.Person VALUES (3, 'Jacob', 22);

-- Insert into edge table
INSERT INTO dbo.friend VALUES (
	(SELECT $node_id FROM dbo.Person WHERE name = 'Alice'),
	(SELECT $node_id FROM dbo.Person WHERE name = 'John'),
	'2026/03/09'
);
INSERT INTO dbo.friend VALUES (
	(SELECT $node_id FROM dbo.Person WHERE name = 'Alice'),
	(SELECT $node_id FROM dbo.Person WHERE name = 'Jacob'),
	'2026/03/10'
);
INSERT INTO dbo.friend VALUES (
	(SELECT $node_id FROM dbo.Person WHERE name = 'John'),
	(SELECT $node_id FROM dbo.Person WHERE name = 'Jacob'),
	'2026/03/10'
);

-- QUERY LANGUAGE EXTENSIONS
-- Find friends of John
SELECT
	Person2.Name,
	friend.StartDate
FROM Person AS Person1, friend, Person AS Person2
WHERE MATCH(Person1-(friend)->Person2) AND Person1.Name = 'John'
UNION ALL
SELECT
	Person2.Name,
	friend.StartDate
FROM Person AS Person1, friend, Person AS Person2
WHERE MATCH(Person1<-(friend)-Person2) AND Person1.Name = 'John';

-- Find friends of John's friends
SELECT
	Person2.name AS [friend],
	Person3.name AS [friend of friend]
FROM Person Person1, friend, Person Person2, friend friend2, Person Person3
WHERE MATCH(Person1-(friend)->Person2-(friend2)->Person3) AND Person1.name = 'John' AND Person3.name <> 'John'
UNION ALL
SELECT
	Person2.name AS [friend],
	Person3.name AS [friend of friend]
FROM Person Person1, friend, Person Person2, friend friend2, Person Person3
WHERE MATCH(Person1-(friend)->Person2<-(friend2)-Person3) AND Person1.name = 'John' AND Person3.name <> 'John'
UNION ALL
SELECT
	Person2.name AS [friend],
	Person3.name AS [friend of friend]
FROM Person Person1, friend, Person Person2, friend friend2, Person Person3
WHERE MATCH(Person1<-(friend)-Person2-(friend2)->Person3) AND Person1.name = 'John' AND Person3.name <> 'John'
UNION ALL
SELECT
	Person2.name AS [friend],
	Person3.name AS [friend of friend]
FROM Person Person1, friend, Person Person2, friend friend2, Person Person3
WHERE MATCH(Person1<-(friend)-Person2<-(friend2)-Person3) AND Person1.name = 'John' AND Person3.name <> 'John'

-- Find people 1-3 hops away from a given person
SELECT 
	Person1.name AS PersonName,
	STRING_AGG(Person2.name, '->') WITHIN GROUP (GRAPH PATH) AS friends
FROM
	Person AS Person1,
	friend FOR PATH AS fo,
	Person FOR PATH AS Person2
WHERE MATCH(SHORTEST_PATH(Person1(-(fo)->Person2){1,3}))
AND Person1.name = 'Jacob'