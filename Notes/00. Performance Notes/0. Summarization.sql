

-- If a query is slow, go check
--	1. Indexes
--	 + If the query is missing indexes
--	 + Check the state of indexes used by the query (fragmentation, page density) -> do reorganize/rebuild index
--		- Avoid over maintaining every index in the database since it highly costs resource
--	2. Statistics
--	 + Check if statistic is up to date