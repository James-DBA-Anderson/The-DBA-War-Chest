
SELECT	DISTINCT i.object_id , o.name, p.index_id, p.rows, ips.*

FROM	sys.indexes AS i 
JOIN	sys.objects AS o ON o.object_id = i.object_id
JOIN	sys.partitions p ON i.object_id = p.object_id AND i.index_id = p.index_id
CROSS APPLY	sys.dm_db_index_physical_stats(DB_ID(), p.object_id, NULL, NULL, 'DETAILED') ips

WHERE	i.type_desc = 'HEAP'
		AND ips.index_type_desc = 'HEAP'
		AND o.type_desc = 'USER_TABLE'

ORDER BY avg_fragmentation_in_percent DESC