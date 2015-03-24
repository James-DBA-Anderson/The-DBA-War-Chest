
-- DBA War Chest 
-- Last Accessed Times for Tables  
-- 2015-03-24 

-- Display the most recent access times to each table in the current database

WITH LastActivity (ObjectID, LastAction) AS 
  (
       SELECT object_id AS TableName,
              last_user_seek as LastAction
         FROM sys.dm_db_index_usage_stats u
        WHERE database_id = db_id(db_name())
        UNION 
       SELECT object_id AS TableName,
              last_user_scan as LastAction
         FROM sys.dm_db_index_usage_stats u
        WHERE database_id = db_id(db_name())
        UNION
       SELECT object_id AS TableName,
              last_user_lookup as LastAction
         FROM sys.dm_db_index_usage_stats u
        WHERE database_id = db_id(db_name())
  )

SELECT		OBJECT_NAME(so.object_id) AS TableName,
			MAX(la.LastAction) as LastSelect,
			CASE	WHEN so.type = 'U' THEN 'Table (user-defined)'
					WHEN so.type = 'V' THEN 'View'
			END  AS Table_View
			,CASE	WHEN st.create_date IS NULL THEN sv.create_date
			ELSE st.create_date
			END AS create_date
			,CASE	WHEN st.modify_date IS NULL THEN sv.modify_date
			ELSE st.modify_date
			END AS modify_date

FROM		sys.objects so
LEFT JOIN	LastActivity la ON so.object_id = la.ObjectID
LEFT JOIN	sys.tables st ON so.object_id = st.object_id
LEFT JOIN	sys.views sv ON so.object_id = sv.object_id

WHERE		so.type in ('V','U')
			AND so.object_id > 100

GROUP BY	OBJECT_NAME(so.object_id)
			, so.type 
			,st.create_date 
			,st.modify_date
			,sv.create_date
			,sv.modify_date

ORDER BY	OBJECT_NAME(so.object_id)