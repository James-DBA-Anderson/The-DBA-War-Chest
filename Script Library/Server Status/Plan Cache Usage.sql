
-- DBA War Chest 
-- Page Cache Usage
-- 2015-10-08

-- Show the plans in the cache

SELECT		objtype AS [CacheType]
			,count_big(*) AS [Total Plans]
			,sum(cast(size_in_bytes as decimal(18,2)))/1024/1024 AS [Total MBs]
			,avg(usecounts) AS [Avg Use Count]
			,sum(cast((CASE WHEN usecounts = 1 THEN size_in_bytes ELSE 0 END) as decimal(18,2)))/1024/1024 AS [Total MBs - USE Count 1]
			,sum(CASE WHEN usecounts = 1 THEN 1 ELSE 0 END) AS [Total Plans - USE Count 1]
			--,TEXT
			--,query_plan

FROM		sys.dm_exec_cached_plans
--CROSS APPLY sys.dm_exec_sql_text(plan_handle)
--CROSS APPLY sys.dm_exec_query_plan(plan_handle)

GROUP BY	objtype
			--,TEXT
			--,query_plan

ORDER BY	[Total MBs - USE Count 1] DESC

go