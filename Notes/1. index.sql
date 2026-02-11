

-- Types of index
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







-- HEAP TABLE:
