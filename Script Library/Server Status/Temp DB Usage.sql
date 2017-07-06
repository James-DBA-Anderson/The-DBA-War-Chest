
-- DBA War Chest 
-- Show TempDB Usage
-- 2015-03-25

-- Show TempDB usage by statement.

USE tempdb;
GO 

SELECT		s.session_id AS [SESSION ID],
            DB_NAME(ss.database_id) AS [DATABASE Name],
            HOST_NAME AS [System Name],
            program_name AS [Program Name],
            login_name AS [USER Name],
            status,
            cpu_time AS [CPU TIME (in milisec)],
            total_scheduled_time AS [Total Scheduled TIME (in milisec)],
            total_elapsed_time AS    [Elapsed TIME (in milisec)],
            (memory_usage * 8)      AS [Memory USAGE (in KB)],
            (user_objects_alloc_page_count * 8) AS [SPACE Allocated FOR USER Objects (in KB)],
            (user_objects_dealloc_page_count * 8) AS [SPACE Deallocated FOR USER Objects (in KB)],
            (internal_objects_alloc_page_count * 8) AS [SPACE Allocated FOR Internal Objects (in KB)],
            (internal_objects_dealloc_page_count * 8) AS [SPACE Deallocated FOR Internal Objects (in KB)],
            CASE is_user_process
                                    WHEN 1      THEN 'user session'
                                    WHEN 0      THEN 'system session'
            END         AS [SESSION Type], row_count AS [ROW COUNT]
FROM sys.dm_db_session_space_usage ss
INNER join sys.dm_exec_sessions s ON ss.session_id = s.session_id

WHERE		(user_objects_alloc_page_count * 8) + 
			(user_objects_dealloc_page_count * 8) +
			(internal_objects_alloc_page_count * 8) +
            (internal_objects_dealloc_page_count * 8) > 0

ORDER BY	(user_objects_alloc_page_count * 8) + 
			(user_objects_dealloc_page_count * 8) +
			(internal_objects_alloc_page_count * 8) +
            (internal_objects_dealloc_page_count * 8) DESC;



SELECT		t.text AS QueryText, 
			SUM(st.internal_objects_alloc_page_count) AS task_internal_objects_alloc_page_count,
			SUM(st.internal_objects_dealloc_page_count) AS task_internal_objects_dealloc_page_count 

FROM		sys.dm_db_task_space_usage  st
JOIN		sys.sysprocesses sp ON sp.spid = st.session_id
CROSS APPLY sys.dm_exec_sql_text(sp.sql_handle) t

GROUP BY	t.text

ORDER BY	task_internal_objects_alloc_page_count DESC;