-- DBA War Chest 
-- File Group Objects
-- 2015-04-30 

-- Show which objects are in which file group
-- This scrpt was written by Pinal Dave. For more details see here: http://blog.sqlauthority.com/2009/06/01/sql-server-list-all-objects-created-on-all-filegroups-in-database/

SELECT		f.[name] AS FileGroupName
			, o.[name] AS ObjectName
			, o.[type] AS [Type]
			, i.[name] AS IndexNAme
			, i.[index_id] AS IndexId

FROM		sys.indexes i
INNER JOIN	sys.filegroups f ON i.data_space_id = f.data_space_id
INNER JOIN	sys.all_objects o ON i.[object_id] = o.[object_id]

WHERE		i.data_space_id = f.data_space_id
			AND o.type = 'U' -- User Created Tables

ORDER BY	f.[name]
			, o.[name] 
			, o.[type] 
			, i.[name] 
