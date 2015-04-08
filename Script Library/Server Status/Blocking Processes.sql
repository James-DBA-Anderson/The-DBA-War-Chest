
-- DBA War Chest 
-- Show All Blocked and Blocking Processes
-- 2015-03-25

-- Show all UNIQUEIDENTIFIER clustered indexes


SELECT  blocking.session_id AS blocking_session_id ,
	blocked.session_id AS blocked_session_id ,
	waitstats.wait_type AS blocking_resource ,
	waitstats.wait_duration_ms ,
	waitstats.resource_description ,
	blocked_cache.text AS blocked_text ,
	blocking_cache.text AS blocking_text
FROM    sys.dm_exec_connections AS blocking
	INNER JOIN sys.dm_exec_requests blocked
		ON blocking.session_id = blocked.blocking_session_id
	CROSS APPLY sys.dm_exec_sql_text(blocked.sql_handle)
						blocked_cache
	CROSS APPLY sys.dm_exec_sql_text(blocking.most_recent_sql_handle)
						blocking_cache
	INNER JOIN sys.dm_os_waiting_tasks waitstats
		ON waitstats.session_id = blocked.session_id
