
SELECT		objtype AS [CacheType]
			,count_big(*) AS [Total Plans]
			,sum(cast(size_in_bytes as decimal(18,2)))/1024/1024 AS [Total MBs]
			,avg(usecounts) AS [Avg Use Count]
			,sum(cast((CASE WHEN usecounts = 1 THEN size_in_bytes ELSE 0 END) as decimal(18,2)))/1024/1024 AS [Total MBs - USE Count 1]
			,sum(CASE WHEN usecounts = 1 THEN 1 ELSE 0 END) AS [Total Plans - USE Count 1]

FROM		sys.dm_exec_cached_plans

GROUP BY	objtype

ORDER BY	[Total MBs - USE Count 1] DESC

go