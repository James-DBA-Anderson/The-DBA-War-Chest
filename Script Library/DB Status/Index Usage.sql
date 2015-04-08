
-- DBA War Chest 
-- Index Usage
-- 2015-03-30

-- Show the most used and the most altered indexes on the server.


SELECT	d.name as [Database]
		, OBJECT_NAME(S.[OBJECT_ID]) AS [OBJECT NAME]          
		, I.[NAME] AS [INDEX NAME]         
		, USER_SEEKS          
		, USER_SCANS        
		, USER_LOOKUPS          
		, USER_UPDATES 

FROM    SYS.DM_DB_INDEX_USAGE_STATS AS S          
JOIN	SYS.INDEXES AS I ON I.[OBJECT_ID] = S.[OBJECT_ID]               
							AND I.INDEX_ID = S.INDEX_ID 
JOIN	sys.Databases d on s.database_id = d.database_id

WHERE    OBJECTPROPERTY(S.[OBJECT_ID],'IsUserTable') = 1 

ORDER BY USER_SEEKS + USER_SCANS + USER_LOOKUPS + USER_UPDATES DESC


SELECT	d.name
		, t.name
		, OBJECT_NAME(A.[OBJECT_ID]) AS [OBJECT NAME]
		, I.[NAME] AS [INDEX NAME]
		, A.LEAF_INSERT_COUNT        
		, A.LEAF_UPDATE_COUNT
		, A.LEAF_DELETE_COUNT

FROM	SYS.DM_DB_INDEX_OPERATIONAL_STATS (NULL,NULL,NULL,NULL ) A        
JOIN	SYS.INDEXES AS I ON I.[OBJECT_ID] = A.[OBJECT_ID]   
JOIN	sys.tables t ON i.object_id = t.object_id      
JOIN	sys.databases d ON a.database_id = d.database_id
						AND I.INDEX_ID = A.INDEX_ID 

WHERE	OBJECTPROPERTY(A.[OBJECT_ID],'IsUserTable') = 1

ORDER BY	A.LEAF_INSERT_COUNT + A.LEAF_UPDATE_COUNT + A.LEAF_DELETE_COUNT DESC


