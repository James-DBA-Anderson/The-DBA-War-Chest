
-- DBA War Chest 
-- Cache Usage by Database 
-- 2015-03-24

-- Display how much of the cache (buffer pool) is being used by each database

SELECT		COUNT(*)AS cached_pages_count
			,	CASE database_id 
					WHEN 32767 THEN 'ResourceDb' 
					ELSE db_name(database_id) 
				END AS database_name

FROM		sys.dm_os_buffer_descriptors

GROUP BY	DB_NAME(database_id) ,database_id

ORDER BY	cached_pages_count DESC;