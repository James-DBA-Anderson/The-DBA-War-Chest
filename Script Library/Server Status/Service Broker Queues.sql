
-- DBA War Chest 
-- Service Broker Queues 
-- 2015-03-30

-- Show the service broker queues in the current database.

SELECT	queues.Name 
		, parti.Rows 

FROM	sys.objects AS SysObj 
JOIN	sys.partitions AS parti ON parti.object_id = SysObj.object_id 
JOIN	sys.objects AS queues ON SysObj.parent_object_id = queues.object_id 
 
WHERE	parti.index_id = 1 
