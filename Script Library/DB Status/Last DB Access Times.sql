
-- DBA War Chest 
-- Last Access Time for Each Database 
-- 2015-03-24 

-- Display when the last read and write occurred on each database

-- Get last server restart time 

SELECT	crdate AS ServerStartTime

FROM	sysdatabases 

WHERE	name = 'tempdb';


WITH agg AS

(
   SELECT	MAX(last_user_seek) last_user_seek,
			MAX(last_user_scan) last_user_scan,
			MAX(last_user_lookup) last_user_lookup,
			MAX(last_user_update) last_user_update,
			sd.name AS dbname

	FROM	sys.dm_db_index_usage_stats ius
	JOIN	master..sysdatabases sd ON  ius.database_id = sd.dbid 
	
	GROUP BY sd.name 
)

SELECT	dbname,
		last_read = MAX(last_read),
		last_write = MAX(last_write)

FROM	(
			SELECT	dbname, last_user_seek, NULL 
			FROM	agg
			UNION ALL
			SELECT	dbname, last_user_scan, NULL 
			FROM	agg
			UNION ALL
			SELECT	dbname, last_user_lookup, NULL 
			FROM	agg
			UNION ALL
			SELECT	dbname, NULL, last_user_update 
			FROM	agg
		) AS x (dbname, last_read, last_write)

GROUP BY	dbname

ORDER BY	dbname;
