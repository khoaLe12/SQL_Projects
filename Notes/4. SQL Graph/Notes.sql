

-- GRAPH DATABASE
-- 1. Offering capabilities to model complicated many-to-many relationships
-- 2. Consists of nodes and edges, node represent an entity and edge as relationship, make it flexible to define complex relationships
-- 3. Provide some unique features:
--	+ Edges/relationships can have attributes or properties associated with them
--	+ A single edge can connect multiple nodes
--	+ Enable queries with pattern macthing and multi-hop navigation
--	+ Easily express transitive closure and polymorphic queries
-- 4. 

-- CREATE GRAPH OBJECTS
CREATE TABLE Person
(
	ID Int PRIMARY KEY,
	Name Varchar(100),
	Age Int
) AS NODE;
CREATE TABLE friends
(
	StartDate Date
) AS EDGE;

-- QUERY LANGUAGE EXTENSIONS
-- Find friends of John
SELECT
	Person2.Name,
	friends.StartDate
FROM Person AS Person1, friends, Person AS Person2
WHERE MATCH(Person1-(friends)->Person2)
	AND Person1.Name = 'John'