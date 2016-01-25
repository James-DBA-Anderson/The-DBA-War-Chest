
SELECT TOP 10	UseCounts,RefCounts
				, Cacheobjtype
				, Objtype
				, OBJECT_NAME(s.objectid)
				, ISNULL(DB_NAME(dbid),'ResourceDB') AS DatabaseName
				, s.*


FROM sys.dm_exec_cached_plans p WITH(NOLOCK)
CROSS APPLY sys.dm_exec_query_plan(plan_handle) s 

WHERE	s.objectid = OBJECT_ID('stproc_PassThruPartner_GetPaybackItalyFilesAndTransactions')
		AND p.objtype = 'Proc'
		AND cacheobjtype = 'Compiled Plan'
OPTION(RECOMPILE);