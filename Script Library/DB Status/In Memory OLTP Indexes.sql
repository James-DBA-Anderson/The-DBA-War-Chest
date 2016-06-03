
-- DBA War Chest 
-- In Memory OLTP Indexes
-- 2016-04-27

-- Display all in memory OLTP indexes
-- For SQL Server 2014+

SELECT	OBJECT_NAME(h.object_id),
		i.name,
		h.total_bucket_count,
		h.empty_bucket_count,
		h.avg_chain_length,
		h.max_chain_length
FROM	sys.dm_db_xtp_hash_index_stats h

JOIN	sys.indexes i ON (h.object_id = i.object_id AND h.index_id = i.index_id)

--WHERE	OBJECT_NAME(h.object_id) = 'EmployeeTableInMemory';
GO