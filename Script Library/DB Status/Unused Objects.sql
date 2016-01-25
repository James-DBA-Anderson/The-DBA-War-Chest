
-- DBA War Chest 
-- Show All Unused Objects
-- 2015-03-25

-- Show all unused objects in the current database.


SELECT		OBJECT_NAME(i.[object_id]) AS TableName, 
			CASE 
				WHEN i.name IS NULL THEN '<Unused table>' 
				ELSE i.name 
			END AS UnusedIndex

FROM		sys.indexes AS i
JOIN		sys.objects AS o ON i.[object_id] = o.[object_id]

WHERE		i.index_id NOT IN	( 
									SELECT	s.index_id

									FROM	sys.dm_db_index_usage_stats AS s

									WHERE	s.[object_id] = i.[object_id]
									AND		i.index_id = s.index_id
									AND		database_id = DB_ID() 
								)
								
AND			o.[type] = 'U'

ORDER BY	OBJECT_NAME(i.[object_id]) ASC;
