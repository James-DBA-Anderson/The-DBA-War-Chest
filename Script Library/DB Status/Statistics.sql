
-- DBA War Chest 
-- Statistics 
-- 2015-02-20 

-- Return information about statistcs in the current database


SELECT		OBJECT_NAME([sp].[object_id]) AS "Table",
			[sp].[stats_id] AS "Statistic ID",
			[s].[name] AS "Statistic",
			[sp].[last_updated] AS "Last Updated",
			[sp].[rows],
			[sp].[rows_sampled],
			[sp].[unfiltered_rows],
			[sp].[modification_counter] AS "Modifications"

FROM		[sys].[stats] AS [s]
OUTER APPLY sys.dm_db_stats_properties ([s].[object_id],[s].[stats_id]) AS [sp]

--WHERE [s].[object_id] = OBJECT_ID(N'SpecificTableName');
