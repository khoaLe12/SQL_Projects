

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

-- CREATE DATABASE
IF NOT EXISTS (SELECT * FROM sys.databases WHERE NAME = 'graphdemo')
	CREATE DATABASE GraphDemo;
GO

USE GraphDemo;
GO

-- CREATE NODE TABLES
CREATE TABLE Person (
	ID Integer PRIMARY KEY,
	name Varchar(100)
) AS NODE;

CREATE TABLE Restaurant (
	ID Integer NOT NULL,
	name Varchar(100),
	city Varchar(100)
) AS NODE;

CREATE TABLE City (
	ID Integer PRIMARY KEY,
	name Varchar(100),
	stateName Varchar(100)
) AS NODE;

-- CREATE EDGE TABLES
CREATE TABLE likes (rating Integer) AS EDGE;
CREATE TABLE friendOf AS EDGE;
CREATE TABLE livesIn AS EDGE;
CREATE TABLE locatedIn AS EDGE;

-- INSERT DATA INTO NODE TABLES
INSERT INTO Person (ID, name)
VALUES (1, 'John'), (2, 'Mary'), (3, 'Alice'), (4, 'Jacob'), (5, 'Julie');

INSERT INTO Restaurant (ID, name, city)
VALUES (1, 'Taco Dell', 'Bellevue'), (2, 'Ginger and spice', 'Seattle'), (3, 'Noodle Land', 'Redmond');

INSERT INTO City (ID, name, stateName)
VALUES (1, 'Bellevue', 'WA'), (2, 'Seattle', 'WA'), (3, 'Redmond', 'WA')

-- INSERT INTO EDGE TABLES
INSERT INTO likes
VALUES ((SELECT $node_id FROM Person WHERE ID = 1), (SELECT $node_id FROM Restaurant WHERE ID = 1), 9),
	((SELECT $node_id FROM Person WHERE ID = 2), (SELECT $node_id FROM Restaurant WHERE ID = 2), 9),
	((SELECT $node_id FROM Person WHERE ID = 3), (SELECT $node_id FROM Restaurant WHERE ID = 3), 9),
	((SELECT $node_id FROM Person WHERE ID = 4), (SELECT $node_id FROM Restaurant WHERE ID = 3), 9),
    ((SELECT $node_id FROM Person WHERE ID = 5), (SELECT $node_id FROM Restaurant WHERE ID = 3), 9);

INSERT INTO livesIn
VALUES ((SELECT $node_id FROM Person WHERE ID = 1), (SELECT $node_id FROM City WHERE ID = 1)),
	((SELECT $node_id FROM Person WHERE ID = 2), (SELECT $node_id FROM City WHERE ID = 2)),
	((SELECT $node_id FROM Person WHERE ID = 3), (SELECT $node_id FROM City WHERE ID = 3)),
	((SELECT $node_id FROM Person WHERE ID = 4), (SELECT $node_id FROM City WHERE ID = 3)),
	((SELECT $node_id FROM Person WHERE ID = 5), (SELECT $node_id FROM City WHERE ID = 1));

INSERT INTO locatedIn
VALUES ((SELECT $node_id FROM Restaurant WHERE ID = 1), (SELECT $node_id FROM City WHERE ID = 1)),
	((SELECT $node_id FROM Restaurant WHERE ID = 2), (SELECT $node_id FROM City WHERE ID = 2)),
	((SELECT $node_id FROM Restaurant WHERE ID = 3), (SELECT $node_id FROM City WHERE ID = 3));

INSERT INTO friendOf
VALUES ((SELECT $node_id FROM Person WHERE ID = 1), (SELECT $node_id FROM Person WHERE ID = 2)),
	((SELECT $NODE_ID FROM Person WHERE ID = 2), (SELECT $NODE_ID FROM Person WHERE ID = 3)),
	((SELECT $NODE_ID FROM Person WHERE ID = 3), (SELECT $NODE_ID FROM Person WHERE ID = 1)),
	((SELECT $NODE_ID FROM Person WHERE ID = 4), (SELECT $NODE_ID FROM Person WHERE ID = 2)),
	((SELECT $NODE_ID FROM Person WHERE ID = 5), (SELECT $NODE_ID FROM Person WHERE ID = 4));



-- Find which restaurant that John likes
SELECT Restaurant.name
FROM Person, likes, Restaurant
WHERE MATCH(Person-(likes)->Restaurant)
	AND Person.name = 'John'

-- Find the restaurants that John's friends like
SELECT Restaurant.name
FROM Person Person1, friendOf fo, Person Person2, likes, Restaurant
WHERE MATCH(Person1-(fo)->Person2-(likes)->Restaurant)
	AND Person1.name = 'John'

-- Find people who like a restaurant in the same city they live in
SELECT Person.name, City.name, Restaurant.name
FROM Person, livesIn, City, locatedIn, Restaurant, likes
WHERE MATCH(Person-(livesIn)->City<-(locatedIn)-Restaurant<-(likes)-Person)

-- Find friends of friends of friends
SELECT CONCAT(Person.name, '->', Person2.name, '->', Person3.name, '->', Person4.name)
FROM Person, friendOf, Person AS Person2, friendOf AS friendOffriend, Person AS Person3, friendOf AS friendOffriendOffriend, Person AS Person4
WHERE MATCH(Person-(friendOf)->Person2-(friendOffriend)->Person3-(friendOffriendOffriend)->Person4)
	AND Person.name != Person2.name
	AND Person2.name != Person3.name
	AND Person3.name != Person4.name
	AND Person4.name != Person.name

-- Find all friends of John
SELECT Person2.name
FROM Person, friendOf, Person AS Person2
WHERE MATCH(Person-(friendOf)->Person2)
	AND Person.name = 'John'
UNION ALL
SELECT Person2.name
FROM Person, friendOf, Person Person2
WHERE MATCH(Person<-(friendOf)-Person2)
	AND Person.name = 'John'

-- Find people 1-3 hops away from a given person
SELECT 
	Person1.name AS PersonName,
	STRING_AGG(Person2.name, '->') WITHIN GROUP (GRAPH PATH) AS friends
FROM
	Person AS Person1,
	friendOf FOR PATH AS fo,
	Person FOR PATH AS Person2
WHERE MATCH(SHORTEST_PATH(Person1(-(fo)->Person2){1,3}))
AND Person1.name = 'Jacob'