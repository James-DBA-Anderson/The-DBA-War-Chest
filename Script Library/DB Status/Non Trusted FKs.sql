
-- DBA War Chest 
-- Show Untrusted Foreign Keys 
-- 2015-03-24

-- Show untrusted foriegn keys in the current database.
-- Untrusted foreign keys are ignored by the server.

SELECT		'ALTER TABLE ' + QUOTENAME(s.name) + '.' + QUOTENAME(object_name(fk.parent_object_id)) + ' WITH CHECK CHECK CONSTRAINT ALL' AS TheFix, 
			fk.*

FROM		sys.foreign_keys fk
JOIN		sys.objects o ON fk.parent_object_id = o.object_id 
JOIN		sys.schemas s ON o.schema_id = s.schema_id

WHERE		fk.is_not_trusted = 1
			AND fk.is_not_for_replication = 0

