
-- DBA War Chest 
-- Show Stored Procedure Execution Stats 
-- 2015-03-13 

-- Show stats for each statement in the longest running stored procedures.

SELECT		a.execution_count ,
			OBJECT_NAME(objectid, b.dbid) Name,
			query_text = SUBSTRING( 
									b.text, 
									a.statement_start_offset/2, 
									(	CASE	WHEN a.statement_end_offset = -1 
												THEN len(convert(nvarchar(max), b.text)) * 2 
												ELSE a.statement_end_offset 
										END - a.statement_start_offset)/2
								   ) ,
			b.dbid ,
			dbname = db_name(b.dbid) ,
			b.objectid ,
			a.*

FROM    	sys.dm_exec_query_stats a 
CROSS APPLY sys.dm_exec_sql_text(a.sql_handle) as b 

WHERE		OBJECT_NAME(objectid) IS NOT NULL -- Comment out to see statements

ORDER BY	a.execution_count DESC
			, a.last_execution_time DESC


/*

-- This version uses a crude algo to guess the cost of each execution to find the most costly procs

SELECT		(a.total_logical_reads + (a.total_physical_reads * 2) + (a.total_logical_writes * 4)) / a.execution_count AS CostPerExec,
			a.execution_count ,
			OBJECT_NAME(objectid, b.dbid) Name,
			query_text = SUBSTRING(
									b.text, 
									a.statement_start_offset / 2, 
									(	CASE	WHEN a.statement_end_offset = -1 
												THEN len(convert(nvarchar(max), b.text)) * 2 
												ELSE a.statement_end_offset 
										END - a.statement_start_offset)/2
								   ) ,
			b.dbid ,
			dbname = db_name(b.dbid) ,
			b.objectid,
			a.*

FROM    	sys.dm_exec_query_stats a 
CROSS APPLY sys.dm_exec_sql_text(a.sql_handle) as b 

WHERE		(
				(max_worker_time > 10000)
				OR
				(max_logical_reads > 50)
				OR
				(max_logical_writes > 10)
			)

			AND execution_count > 3

--OBJECT_NAME(objectid) IS NOT NULL -- Comment out to see statements

ORDER BY	(a.total_logical_reads + (a.total_physical_reads * 2) + (a.total_logical_writes * 4)) / a.execution_count DESC
*/