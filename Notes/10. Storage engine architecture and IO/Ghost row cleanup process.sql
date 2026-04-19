
-- GHOST ROW CLEANUP PROCESS
-- 1. Ghost rows are rows that have been deleted from the leaf page of an index
--	but are not physically removed immediately.
-- 2. These rows are marked for future removal and are invisible to queries.
-- 3. Ghost cleanup is a background process that runs periodically to physically removed marked rows.
-- 4. This mechanism optimizes performance during delete operations:
--	+ Deletes are faster because rows are only marked, not immediately removed.
--	+ Ghost rows may be retained temporarily for row versioning (e.g., snapshot isolation).
-- 5. In high-load systems with frequent deletes, ghost cleanup can impact performance.
--	+ If necessary, it can ve disabled using trace flag 661.
-- 6. Disabling ghost cleanup may cause the database to grow unnecessarily large,
--	leading to increased I/O and memory consumption.

-- Find the approximate number of ghosted rows in databases
SELECT
	SUM(ghost_record_count) AS total_ghost_records,
	DB_NAME(database_id) AS database_name
FROM sys.dm_db_index_physical_stats(NULL, NULL, NULL, NULL, 'SAMPLED')
GROUP BY database_id
ORDER BY total_ghost_records DESC;