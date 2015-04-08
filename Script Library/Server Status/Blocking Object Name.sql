
-- DBA War Chest 
-- Show name of blocking object
-- 2015-03-25

-- Show the name of the object that has a lock which is blocking a query

SELECT	OBJECT_NAME(p.[object_id]) BlockedObject
	
FROM    sys.dm_exec_connections AS blocking 
JOIN	sys.dm_exec_requests blocked ON blocking.session_id = blocked.blocking_session_id
JOIN	sys.dm_os_waiting_tasks waitstats ON waitstats.session_id = blocked.session_id
JOIN	sys.partitions p ON SUBSTRING(resource_description, PATINDEX('%associatedObjectId%', resource_description) + 19, LEN(resource_description)) = p.partition_id

