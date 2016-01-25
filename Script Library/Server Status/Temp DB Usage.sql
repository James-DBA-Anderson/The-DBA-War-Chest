
-- DBA War Chest 
-- Show TempDB Usage
-- 2015-03-25

-- Show TempDB usage by statement.


USE tempdb
Go 

SELECT		t.text AS QueryText, 
			SUM(st.internal_objects_alloc_page_count) AS task_internal_objects_alloc_page_count,
			SUM(st.internal_objects_dealloc_page_count) AS task_internal_objects_dealloc_page_count 

FROM		sys.dm_db_task_space_usage  st
JOIN		sys.sysprocesses sp ON sp.spid = st.session_id
CROSS APPLY sys.dm_exec_sql_text(sp.sql_handle) t

GROUP BY	t.text

ORDER BY	task_internal_objects_alloc_page_count DESC